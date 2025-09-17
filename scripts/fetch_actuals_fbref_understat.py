#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
HAFEZ Auto-Actuals Fetcher (La Liga) - FBref + Understat
Inputs:
  --season: e.g., 2025-26
  --matchday: integer
  --data_dir: path to JSON data directory (default: public/data)

Behavior:
  - Loads HAFEZ_LaLiga_{season}_MD{matchday}_Actuals_Extended.json (must exist)
  - Fills halftime score, second-half score, first goal (team/minute/player),
    scorers[], corners_total, cards (yellow/red), xG (home/away).
  - Saves back the JSON in-place.

Requirements:
  pip install requests beautifulsoup4 lxml
"""
import argparse, json, re, sys, time, math
from pathlib import Path

import requests
from bs4 import BeautifulSoup

ROOT = Path(__file__).resolve().parents[1]  # repo root
ALIASES = json.loads((ROOT/"scripts"/"team_aliases_laliga.json").read_text(encoding="utf-8"))

def normalize_team(name:str)->str:
    for canon, alist in ALIASES.items():
        for a in alist:
            if name.strip().lower() == a.strip().lower():
                return canon
    for canon, alist in ALIASES.items():
        if any(a.lower() in name.lower() for a in alist):
            return canon
    return name

def get_understat_matches(season_start:int):
    url = f"https://understat.com/league/La_liga/{season_start}"
    html = requests.get(url, timeout=30).text
    m = re.search(r"var\s+matchesData\s*=\s*JSON\.parse\('([^']+)'", html)
    if not m:
        raise RuntimeError("Understat matchesData not found")
    import html as ihtml, json as ijson
    raw = ihtml.unescape(m.group(1))
    matches = ijson.loads(raw)
    return matches

def get_understat_match_details(match_id:int):
    url = f"https://understat.com/match/{match_id}"
    html = requests.get(url, timeout=30).text
    ms = re.search(r"var\s+shotsData\s*=\s*JSON\.parse\('([^']+)'", html)
    if not ms:
        return None
    import html as ihtml, json as ijson
    raw = ihtml.unescape(ms.group(1))
    data = ijson.loads(raw)  # dict: {'h': [...], 'a': [...]}
    return data

def get_fbref_round_table(season_start:int):
    url = f"https://fbref.com/en/comps/12/{season_start}-{season_start+1}/schedule/{season_start}-{season_start+1}-La-Liga-Scores-and-Fixtures"
    r = requests.get(url, timeout=30)
    r.raise_for_status()
    return BeautifulSoup(r.text, "lxml")

def parse_fbref_match_links(soup, round_num:int):
    out = {}
    table = soup.find("table", id="sched_all") or soup.find("table", id="sched")
    if not table:
        table = soup.find("table")
    for tr in table.find_all("tr"):
        tds = tr.find_all("td")
        if not tds:
            continue
        week = tr.find("th", {"data-stat":"week"})
        if week and week.get_text(strip=True).isdigit():
            if int(week.get_text(strip=True)) != round_num:
                continue
        date = (tr.find("td", {"data-stat":"date"}).get_text(strip=True) if tr.find("td", {"data-stat":"date"}) else "").split(" ")[0]
        home = tr.find("td", {"data-stat":"home_team"})
        away = tr.find("td", {"data-stat":"away_team"})
        if not home or not away:
            continue
        home = normalize_team(home.get_text(strip=True))
        away = normalize_team(away.get_text(strip=True))
        link = tr.find("td", {"data-stat":"match_report"})
        if link and link.find("a"):
            href = link.find("a")["href"]
            out[(home,away,date)] = "https://fbref.com"+href
    return out

def extract_fbref_match_stats(url:str):
    r = requests.get(url, timeout=30)
    if r.status_code != 200:
        return {}
    soup = BeautifulSoup(r.text, "lxml")
    res = {}
    scorebox = soup.find("div", class_="scorebox")
    if scorebox:
        meta = scorebox.find("div", class_="scorebox_meta")
        if meta:
            for li in meta.find_all(["div","li"]):
                txt = li.get_text(" ", strip=True)
                if "halftime" in txt.lower() or "half-time" in txt.lower() or "ht" in txt.lower():
                    m = re.search(r"(\\d+)[–-](\\d+)", txt)
                    if m:
                        res["halftime_score"] = {"home": int(m.group(1)), "away": int(m.group(2))}
                        break
    for table in soup.find_all("table"):
        cap = table.find("caption")
        captxt = cap.get_text(strip=True).lower() if cap else ""
        if "team stats" in captxt or "match stats" in captxt:
            rows = table.find_all("tr")
            home_corners = away_corners = None
            hy=hr=ay=ar=None
            for tr in rows:
                label = tr.find("th")
                if not label: continue
                lbl = label.get_text(strip=True).lower()
                tds = tr.find_all("td")
                if "corner" in lbl:
                    try:
                        home_corners = int(re.sub(r"[^\\d]", "", tds[0].get_text(strip=True)))
                        away_corners = int(re.sub(r"[^\\d]", "", tds[1].get_text(strip=True)))
                    except: pass
                if "yellow cards" in lbl:
                    try:
                        hy = int(re.sub(r"[^\\d]", "", tds[0].get_text(strip=True)))
                        ay = int(re.sub(r"[^\\d]", "", tds[1].get_text(strip=True)))
                    except: pass
                if "red cards" in lbl:
                    try:
                        hr = int(re.sub(r"[^\\d]", "", tds[0].get_text(strip=True)))
                        ar = int(re.sub(r"[^\\d]", "", tds[1].get_text(strip=True)))
                    except: pass
            if home_corners is not None and away_corners is not None:
                res["corners_total"] = home_corners + away_corners
            if hy is not None or hr is not None or ay is not None or ar is not None:
                res["cards"] = {"yellow_home":hy, "yellow_away":ay, "red_home":hr, "red_away":ar}
    return res

def main():
    import html
    ap = argparse.ArgumentParser()
    ap.add_argument("--season", required=True, help="e.g., 2025-26")
    ap.add_argument("--matchday", required=True, type=int)
    ap.add_argument("--data_dir", default="public/data", help="where JSONs live")
    args = ap.parse_args()
    season_start = int(args.season.split("-")[0])
    target = Path(args.data_dir)/f"HAFEZ_LaLiga_{args.season}_MD{args.matchday}_Actuals_Extended.json"
    if not target.exists():
        print("Actuals_Extended file not found:", target, file=sys.stderr)
        sys.exit(1)
    pkg = json.loads(target.read_text(encoding="utf-8"))
    us_matches = get_understat_matches(season_start)
    us_by_key = {}
    for m in us_matches:
        rnd = int(m.get("round") or 0)
        h = normalize_team(m.get("h_title",""))
        a = normalize_team(m.get("a_title",""))
        us_by_key[(rnd,h,a)] = m
    fb_soup = get_fbref_round_table(season_start)
    fb_links = parse_fbref_match_links(fb_soup, args.matchday)
    changed=False
    for mm in pkg["matches"]:
        h = normalize_team(mm["home_team"]); a = normalize_team(mm["away_team"])
        um = us_by_key.get((args.matchday,h,a)) or us_by_key.get((args.matchday,a,h))
        if um:
            try:
                xg_h = float(um.get("xG", {}).get("h", um.get("xG",{}).get("home", um.get("xG",0))))
                xg_a = float(um.get("xG", {}).get("a", um.get("xG",{}).get("away", um.get("xG",0))))
            except Exception:
                xg_h = xg_a = None
            mid = int(um.get("id"))
            shots = get_understat_match_details(mid)
            first_goal = {"team": None, "minute": None, "player": None}
            scorers=[]
            if shots:
                def parse_goals(arr, side):
                    res=[]
                    for s in arr:
                        if s.get("result")=="Goal":
                            try:
                                minute = int(float(s.get("minute",0)))
                            except:
                                minute = None
                            player = s.get("player","")
                            res.append({"team": side, "minute": minute, "player": player})
                    return res
                goals = parse_goals(shots.get("h",[]),"Home")+parse_goals(shots.get("a",[]),"Away")
                goals = sorted(goals, key=lambda x:(x["minute"] if x["minute"] is not None else 9999))
                if goals:
                    first_goal = goals[0]
                scorers = goals
            mm.setdefault("xG", {"home": None, "away": None})
            if xg_h is not None: mm["xG"]["home"]=round(xg_h,2)
            if xg_a is not None: mm["xG"]["away"]=round(xg_a,2)
            mm.setdefault("first_goal", {"team": None, "minute": None, "player": None})
            if first_goal["team"]:
                mm["first_goal"]=first_goal
            mm["scorers"]=scorers
            mm.setdefault("sources", {})
            mm["sources"]["understat"]=f"https://understat.com/match/{mid}"
            changed=True
        fb_url = fb_links.get((h,a,mm["date"])) or fb_links.get((h,a,""))
        if fb_url:
            fb = extract_fbref_match_stats(fb_url)
            if "halftime_score" in fb:
                mm["halftime_score"]=fb["halftime_score"]
            if "corners_total" in fb:
                mm["corners_total"]=fb["corners_total"]
            if "cards" in fb:
                mm["cards"]=fb["cards"]
            mm.setdefault("sources", {})["fbref"]=fb_url
            changed=True
    if changed:
        target.write_text(json.dumps(pkg, indent=2, ensure_ascii=False), encoding="utf-8")
        print("Updated:", target)
    else:
        print("No changes applied (nothing found).")

if __name__ == "__main__":
    main()
