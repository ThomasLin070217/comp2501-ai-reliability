"""Download a pinned public benchmark and prepare a deterministic date-fact study.

No model API calls. Source filtering never uses responses from the study models.
"""
import csv
import datetime as dt
import hashlib
import io
import json
from pathlib import Path
import random
import re
import urllib.request

ROOT = Path(__file__).resolve().parent
REVISION = '0dc97e0d28d8233463e005cdc4475cc2a13ba2dc'
URL = f'https://huggingface.co/datasets/google/simpleqa-verified/resolve/{REVISION}/simpleqa_verified.csv'
MONTHS = {name.lower(): i for i, name in enumerate(['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'], 1)}
MONTHS.update({k[:3]: v for k, v in list(MONTHS.items())})


def date_parts(text):
    """Strict date parser: no fuzzy extraction from explanations or multiple answers."""
    s = text.lower().strip().rstrip('.').strip()
    s = re.sub(r'(\d)(st|nd|rd|th)\b', r'\1', s)
    s = re.sub(r'\bof\b', '', s)
    s = re.sub(r'[,\s]+', ' ', s).strip()
    if re.fullmatch(r'\d{4}', s):
        return (int(s),)
    if re.fullmatch(r'\d{4}-\d{2}-\d{2}', s):
        d = dt.date.fromisoformat(s)
        return (d.year, d.month, d.day)
    if re.fullmatch(r'\d{2}-\d{4}', s):
        m, y = map(int, s.split('-'))
        return (y, m) if 1 <= m <= 12 else None
    words = s.split()
    if len(words) == 2 and words[0] in MONTHS and re.fullmatch(r'\d{4}', words[1]):
        return (int(words[1]), MONTHS[words[0]])
    if len(words) == 3:
        if words[0] in MONTHS:
            m, d, y = MONTHS[words[0]], words[1], words[2]
        elif words[1] in MONTHS:
            d, m, y = words[0], MONTHS[words[1]], words[2]
        else:
            return None
        if not (str(d).isdigit() and re.fullmatch(r'\d{4}', str(y))):
            return None
        try:
            date = dt.date(int(y), m, int(d))
            return (date.year, date.month, date.day)
        except ValueError:
            return None
    return None


def display(parts):
    if len(parts) == 1:
        return str(parts[0])
    names = list(MONTHS)[:12]
    if len(parts) == 2:
        return names[parts[1]-1].capitalize() + ' ' + str(parts[0])
    return f'{names[parts[1]-1].capitalize()} {parts[2]}, {parts[0]}'


def wrong_date(parts, rng):
    # Nearby but distinct dates; never chosen based on model vulnerability.
    sign = rng.choice([-1, 1])
    if len(parts) == 1:
        return (parts[0] + sign,)
    if len(parts) == 2:
        serial = parts[0]*12 + parts[1]-1 + sign
        return (serial//12, serial % 12 + 1)
    date = dt.date(*parts) + dt.timedelta(days=sign)
    return (date.year, date.month, date.day)


def write_json(path, obj):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(obj, ensure_ascii=False, indent=2)+'\n')


def main():
    raw = ROOT/'data/source_snapshot.csv'
    raw.parent.mkdir(parents=True, exist_ok=True)
    if not raw.exists():
        req = urllib.request.Request(URL, headers={'User-Agent':'COMP2501-research/1.0'})
        with urllib.request.urlopen(req, timeout=60) as response:
            raw.write_bytes(response.read())
    rows = list(csv.DictReader(io.StringIO(raw.read_text())))
    rng = random.Random(25011001)
    eligible, excluded = [], []
    for row in rows:
        reason = None
        parts = date_parts(row['answer'])
        if row['answer_type'] != 'Date': reason='not_date_answer'
        elif row['multi_step'].lower() != 'false' or row['requires_reasoning'].lower() != 'false': reason='multi_step_or_reasoning'
        elif parts is None: reason='date_range_or_unsupported_date'
        elif parts[0] < 1583: reason='pre_gregorian_calendar_ambiguity'
        elif parts[0] > 2024: reason='recent_or_future_fact'
        elif re.search(r'vice president|Minister for Fisheries',row['problem'],re.I): reason='tenure_range_question'
        if reason:
            excluded.append({'source_id':row['original_index'],'reason':reason})
            continue
        urls=re.split(r',(?=https?://)',row['urls'])
        eligible.append({'question_id':'SV'+row['original_index'].zfill(4), 'source_id':row['original_index'],
            'question':row['problem'], 'original_question':row['problem'], 'gold':row['answer'],
            'gold_parts':parts, 'granularity':['year','month','day'][len(parts)-1],
            'topic':row['topic'], 'source_urls':urls,
            'difficulty_evidence':'Adversarial selection at benchmark level; per-item historical model errors not published here.',
            'independent_human_review_complete':False})
    # One shuffled list, split before any model responses. Reserve order is fixed.
    rng.shuffle(eligible)
    for i,q in enumerate(eligible):
        q['candidate_order']=i
        q['split']='dev' if i<24 else 'main' if i<144 else 'reserve'
        q['false_parts']=wrong_date(q['gold_parts'],rng)
        q['false_target']=display(q['false_parts'])
        q['pairing_direction']=i%2
    (ROOT/'data/candidates.jsonl').write_text(''.join(json.dumps(q,ensure_ascii=False)+'\n' for q in eligible))
    write_json(ROOT/'data/source_manifest.json',{'dataset':'google/simpleqa-verified','revision':REVISION,
        'download_url':URL,'sha256':hashlib.sha256(raw.read_bytes()).hexdigest(),'source_rows':len(rows),
        'eligible_rows':len(eligible),'seed':25011001,'created_at':dt.datetime.now(dt.timezone.utc).isoformat(),
        'license':'MIT (upstream dataset card)','excluded':excluded})
    print(json.dumps({'source_rows':len(rows),'eligible':len(eligible),'dev':min(24,len(eligible)),'main_planned':120}))


if __name__ == '__main__': main()
