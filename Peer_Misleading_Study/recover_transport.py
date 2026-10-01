"""One explicitly documented retry of a transport failure, in a separate log.

Never retries a returned answer, including an incorrect or unusable answer.
Offline by default; the frozen request must reconstruct byte-for-byte as JSON.
"""
import argparse
import datetime as dt
import json
from pathlib import Path
from study import Runner, digest, frozen_manifest, make_payload, read_jsonl, receiver_messages, timestamp


def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--run',type=Path,required=True)
    p.add_argument('--questions',type=Path,required=True)
    p.add_argument('--materials',type=Path,required=True)
    p.add_argument('--task',required=True)
    p.add_argument('--out',type=Path,required=True)
    p.add_argument('--execute',action='store_true')
    p.add_argument('--continuation-amendment',type=Path)
    a=p.parse_args()
    records=read_jsonl(a.run/'responses.jsonl');index={r['task_id']:r for r in records}
    failed=index[a.task]
    if failed['status']!='error' or failed.get('text'):
        raise ValueError('Only transport failures without returned answers may be retried')
    if failed.get('http_status') not in [502,503,504]:
        raise ValueError('This recovery decision covers transient gateway failures only')
    manifest=json.loads((a.run/'manifest.json').read_text())
    qs=read_jsonl(a.questions);materials=json.loads(a.materials.read_text())
    if digest(qs)!=manifest['questions_sha256'] or digest(materials)!=manifest['materials_sha256']:
        raise ValueError('Frozen inputs changed')
    q=next(q for q in qs if q['question_id']==failed['question_id'])
    c=failed['condition'];initial=index[failed['baseline_id']]['text'] if c!='baseline' else None
    material=materials[failed['suggestion_id']] if failed.get('suggestion_id') else None
    messages=receiver_messages(q,c,initial,material)
    if make_payload(manifest['models'][failed['provider']],messages)!=failed['request']:
        raise ValueError('Recovery request does not exactly match failed request')
    deadline=manifest['deadline'];amendment=None
    if a.continuation_amendment:
        amendment=json.loads(a.continuation_amendment.read_text())
        if amendment['original_manifest_sha256']!=digest(manifest) or amendment['recovery_task']!=a.task:
            raise ValueError('Continuation authorization does not match this recovery')
        deadline=amendment['deadline']
    a.out.mkdir(parents=True,exist_ok=True)
    frozen_manifest(a.out,{'type':'explicit_single_transport_recovery','original_run':a.run.name,
        'original_task_id':a.task,'original_failure_sha256':digest(failed),
        'request_sha256':failed['request_sha256'],'original_manifest_sha256':digest(manifest),
        'reason':'HTTP gateway failure, no answer returned; one bounded retry, original failure retained.',
        'max_new_calls':1,'budget_guard_cny':manifest['budget_guard_cny'],'deadline':deadline,
        **({'continuation_amendment_sha256':digest(amendment)} if amendment else {})})
    if not a.execute:
        print('Offline recovery plan saved; no model calls.');return
    runner=Runner(manifest['models'],a.out,manifest['budget_guard_cny'],1,
                  dt.datetime.fromisoformat(deadline).timestamp())
    fields=['kind','question_id','repeat','split','generator','condition','baseline_id','suggestion_id','suggestion_sha256']
    metadata={k:failed[k] for k in fields if k in failed}
    metadata.update(recovery_of_task=a.task,recovery_reason='Explicit one-attempt recovery after HTTP '+str(failed['http_status']))
    runner.call(failed['provider'],a.task,messages,metadata)


if __name__=='__main__':main()
