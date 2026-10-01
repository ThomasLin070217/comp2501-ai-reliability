"""Assemble successful transport recoveries without overwriting original logs.

Only a failed request without any answer can be replaced, and the request body
must match exactly. The full failed-attempt count remains in the audit.
"""
import argparse
import datetime as dt
from collections import Counter
import json
from pathlib import Path
from audit_run import audit
from collect import write_json
from study import digest, read_jsonl


def replace_failure(original, replacement, recovery_manifest):
    if original['status'] != 'error' or original.get('text'):
        raise ValueError('Cannot replace a returned answer')
    if replacement['status'] != 'ok':
        raise ValueError('Recovery did not succeed')
    if recovery_manifest['original_failure_sha256'] != digest(original):
        raise ValueError('Failure provenance mismatch')
    for key in ['task_id','provider','question_id','condition','repeat','generator','request','request_sha256']:
        if original[key] != replacement[key]:
            raise ValueError('Recovery changed '+key)
    if replacement['timestamp'] < original['timestamp']:
        raise ValueError('Recovery precedes original attempt')
    return replacement


def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--run',type=Path,required=True)
    p.add_argument('--recovery',type=Path,action='append',default=[])
    p.add_argument('--questions',type=Path,required=True)
    p.add_argument('--materials',type=Path,required=True)
    p.add_argument('--out',type=Path,required=True)
    p.add_argument('--continuation-amendment',type=Path)
    a=p.parse_args()
    original=read_jsonl(a.run/'responses.jsonl');attempts=read_jsonl(a.run/'attempts.jsonl')
    if Counter(x['task_id'] for x in original)!=Counter(x['task_id'] for x in attempts):
        raise ValueError('Unresolved original attempt or response')
    manifest=json.loads((a.run/'manifest.json').read_text())
    continuation=None;cutoff=dt.datetime.fromisoformat(manifest['deadline'])
    if a.continuation_amendment:
        amendment=json.loads(a.continuation_amendment.read_text());n=amendment['existing_response_count']
        if digest(original[:n])!=amendment['existing_responses_sha256'] or digest(manifest)!=amendment['original_manifest_sha256']:
            raise ValueError('Continuation provenance mismatch')
        new=original[n:]
        if len(new)>amendment['max_new_unique_calls']:raise ValueError('Continuation call cap exceeded')
        for r in new:
            if r.get('continuation_amendment_sha256')!=digest(amendment):raise ValueError('Missing continuation attribution')
            if not (dt.datetime.fromisoformat(amendment['timestamp'])<=dt.datetime.fromisoformat(r['timestamp'])<dt.datetime.fromisoformat(amendment['deadline'])):
                raise ValueError('Request outside amended window')
        continuation={'amendment_sha256':digest(amendment),'original_deadline':manifest['deadline'],
                      'extended_deadline':amendment['deadline'],'original_prefix_preserved':True,
                      'new_unique_requests':len(new),'completed_within_original_window':False}
    else:
        n=len(original)
    if any(dt.datetime.fromisoformat(r['timestamp'])>=cutoff for r in original[:n]):
        raise ValueError('Unamended request after original deadline')
    index={r['task_id']:r for r in original};attempt_index={r['task_id']:r for r in attempts}
    all_attempts=list(attempts);all_records=list(original);mapping=[];seen=set()
    for run in a.recovery:
        rs=read_jsonl(run/'responses.jsonl');ats=read_jsonl(run/'attempts.jsonl');m=json.loads((run/'manifest.json').read_text())
        if len(rs)!=1 or len(ats)!=1 or rs[0]['task_id']!=ats[0]['task_id']:
            raise ValueError('Recovery must contain exactly one resolved attempt')
        if m['original_manifest_sha256']!=digest(manifest):raise ValueError('Wrong source run')
        r=rs[0];task=r['task_id']
        if dt.datetime.fromisoformat(r['timestamp'])>=dt.datetime.fromisoformat(m['deadline']):
            raise ValueError('Recovery outside its declared window')
        if dt.datetime.fromisoformat(r['timestamp'])>=cutoff:
            if not continuation or m.get('continuation_amendment_sha256')!=digest(amendment):
                raise ValueError('Unamended late recovery')
        if task in seen:raise ValueError('Multiple candidate recoveries are not allowed')
        seen.add(task);failed=index[task]
        index[task]=replace_failure(failed,r,m);attempt_index[task]=ats[0]
        all_attempts.extend(ats);all_records.extend(rs)
        mapping.append({'task_id':task,'original_run':a.run.name,'recovery_run':run.name,
            'original_failure_sha256':digest(failed),'recovery_response_sha256':digest(r),
            'original_http_status':failed.get('http_status'),'request_sha256':r['request_sha256']})
    selected=[index[r['task_id']] for r in original]
    selected_attempts=[attempt_index[r['task_id']] for r in original]
    qs=read_jsonl(a.questions);materials=json.loads(a.materials.read_text())
    checked=audit(qs,materials,json.loads((a.materials.parent/'freeze.json').read_text()),
                  selected,manifest,selected_attempts)
    checked['scope']='Assembled successful responses; all original failed attempts are retained and counted in assembly.json.'
    assembly={'raw_api_attempts':len(all_attempts),'all_status_counts':dict(Counter(r['status'] for r in all_records)),
              'selected_responses':len(selected),'original_records_sha256':digest(original),
              'selected_records_sha256':digest(selected),'recovery_mapping':mapping,
              'original_failed_records_preserved':True,'response_content_modified':False,
              'continuation':continuation}
    a.out.mkdir(parents=True,exist_ok=True)
    for name,rows in [('responses',selected),('attempts',selected_attempts)]:
        (a.out/(name+'.jsonl')).write_text(''.join(json.dumps(r,ensure_ascii=False)+'\n' for r in rows))
    write_json(a.out/'manifest.json',manifest);write_json(a.out/'audit.json',checked)
    write_json(a.out/'assembly.json',assembly)
    print(json.dumps({'raw_api_attempts':len(all_attempts),'selected_responses':len(selected),
                      'transport_failures':sum(r['status']!='ok' for r in all_records),'audit':checked['status']}))


if __name__=='__main__':main()
