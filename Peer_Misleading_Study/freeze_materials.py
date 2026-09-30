"""Offline preparation of auditable peer materials; never calls a model.

The reviewer first creates a proposal, inspects every selected explanation,
and records any rejected task IDs. --approve creates a hashed freeze.
"""
import argparse
import json
from pathlib import Path
from study import MODELS, digest, material_errors, parse_json, read_jsonl, timestamp
from collect import write_json


def propose(questions, records, rejections):
    selected, audit, missing = {}, [], []
    for q in questions:
        for provider in MODELS:
            for truth in ['correct', 'wrong']:
                key=f'{q["question_id"]}:{provider}:{truth}'
                candidates=sorted((r for r in records if r['task_id'].startswith(key+':')), key=lambda r:r['attempt'])
                chosen=False
                for r in candidates:
                    errors=material_errors(r.get('text'),q,truth) if r['status']=='ok' else ['api_failure']
                    if not errors:
                        try:digest(parse_json(r['text']))
                        except UnicodeEncodeError:errors.append('invalid_unicode_in_decoded_material')
                    if r['task_id'] in rejections:errors.append('content_review: '+rejections[r['task_id']])
                    take=not chosen and not errors
                    audit.append({'key':key,'task_id':r['task_id'],'errors':errors,'selected':take})
                    if take:
                        selected[key]=parse_json(r['text']);chosen=True
                if not chosen:missing.append(key)
    return selected,audit,missing


def validate(questions, materials, receipt):
    if receipt.get('status')!='frozen' or receipt.get('reviewer')!='Codex':raise ValueError('Unapproved material receipt')
    if receipt['questions_sha256']!=digest(questions) or receipt['materials_sha256']!=digest(materials):raise ValueError('Frozen file hash mismatch')
    expected={f'{q["question_id"]}:{p}:{t}' for q in questions for p in MODELS for t in ['correct','wrong']}
    if set(materials)!=expected:raise ValueError('Missing or extra material keys')
    for q in questions:
        if not q.get('source_review'):raise ValueError('Missing question source review')
        for p in MODELS:
            for t in ['correct','wrong']:
                if material_errors(json.dumps(materials[f'{q["question_id"]}:{p}:{t}']),q,t):raise ValueError('Invalid frozen material')


def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--questions',required=True,type=Path)
    p.add_argument('--responses',required=True,type=Path)
    p.add_argument('--out',required=True,type=Path)
    p.add_argument('--rejections',type=Path)
    p.add_argument('--approve',action='store_true')
    args=p.parse_args();qs=read_jsonl(args.questions);rs=read_jsonl(args.responses)
    rejections=json.loads(args.rejections.read_text()) if args.rejections else {}
    material,audit,missing=propose(qs,rs,rejections)
    args.out.mkdir(parents=True,exist_ok=True)
    write_json(args.out/'selection_audit.json',{'candidates':audit,'missing':missing,'rejections':rejections})
    write_json(args.out/'materials.json',material)
    receipt={'status':'frozen' if args.approve and not missing else 'proposal','reviewer':'Codex',
             'independent_human_review_complete':False,'timestamp':timestamp(),
             'questions_sha256':digest(qs),'materials_sha256':digest(material),
             'raw_responses_sha256':digest(rs),'selected':len(material),'missing':missing,
             'rule':'First qualifying candidate of at most two; no receiver outcomes available at selection.'}
    if args.approve:
        if missing:raise ValueError('Cannot approve incomplete materials')
        validate(qs,material,receipt)
    write_json(args.out/'freeze.json',receipt)
    print(json.dumps({'selected':len(material),'missing':missing,'status':receipt['status']}))


if __name__=='__main__':main()
