"""Verify every actual request against its frozen experimental branch."""
import argparse
from collections import Counter
import json
from pathlib import Path
from study import CONDITIONS, MODELS, digest, generator_for, make_payload, read_jsonl, receiver_messages
from freeze_materials import validate
from collect import write_json


def audit(questions,materials,receipt,records,manifest,attempts):
    validate(questions,materials,receipt)
    if manifest['questions_sha256']!=digest(questions):raise ValueError('Question manifest mismatch')
    if manifest['materials_sha256']!=digest(materials):raise ValueError('Material manifest mismatch')
    qs={q['question_id']:q for q in questions};index={r['task_id']:r for r in records}
    if len(index)!=len(records):raise ValueError('Duplicate task IDs')
    expected={f'{q}:{p}:r{r}:{c}' for q in qs for p in MODELS for r in range(manifest['repeats']) for c in ['baseline']+CONDITIONS}
    if set(index)!=expected:raise ValueError('Incomplete or unexpected response set')
    if Counter(a['task_id'] for a in attempts)!=Counter(index.keys()):raise ValueError('Attempt/response mismatch')
    if any(r['status']!='ok' for r in records):raise ValueError('API failures in complete run')
    if min(r['timestamp'] for r in records)<receipt['timestamp']:raise ValueError('Receiver called before material freeze')
    for r in records:
        q=qs[r['question_id']];provider=r['provider'];c=r['condition'];g=generator_for(provider,q['pairing_direction'])
        if g!=r['generator'] or g==provider:raise ValueError('Generator assignment mismatch')
        initial=index[f'{q["question_id"]}:{provider}:r{r["repeat"]}:baseline']['text']
        truth='correct' if c in ['C4','C5'] else 'wrong'
        m=materials[f'{q["question_id"]}:{g}:{truth}'] if c not in ['baseline','C0'] else None
        payload=make_payload(manifest['models'][provider],receiver_messages(q,c,initial,m))
        if payload!=r['request'] or digest(payload)!=r['request_sha256']:raise ValueError('Actual request differs from intended branch: '+r['task_id'])
        if c!='baseline' and r['suggestion_sha256']!=(digest(m) if m else None):raise ValueError('Suggestion hash mismatch')
    return {'status':'passed','questions':len(qs),'receivers':len(MODELS),'repeats':manifest['repeats'],'responses':len(records),
            'checks':['exact expected task set','attempt-response bijection','all provider statuses ok','materials frozen before calls',
                      'cross-model generator mapping','every request exactly reconstructed','C2/C3 and C4/C5 share identical suggestions',
                      'review branches contain only shared baseline, never other review responses','question/source allowlist',
                      'frozen input hashes'],
            'pairing_directions':dict(Counter(q['pairing_direction'] for q in questions)),
            'records_sha256':digest(records),'independent_human_review_complete':False}


def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--questions',required=True,type=Path);p.add_argument('--materials',required=True,type=Path)
    p.add_argument('--run',required=True,type=Path);args=p.parse_args()
    result=audit(read_jsonl(args.questions),json.loads(args.materials.read_text()),
                 json.loads((args.materials.parent/'freeze.json').read_text()),read_jsonl(args.run/'responses.jsonl'),
                 json.loads((args.run/'manifest.json').read_text()),read_jsonl(args.run/'attempts.jsonl'))
    write_json(args.run/'audit.json',result);print(json.dumps(result))


if __name__=='__main__':main()
