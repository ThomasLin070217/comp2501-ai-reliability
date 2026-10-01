"""Resume only unissued frozen tasks after an explicitly recorded time extension.

The original manifest and all existing log lines remain unchanged. A separate
amendment records the old prefix hash, new deadline and exact remaining call cap.
"""
import argparse
import datetime as dt
import hashlib
import json
from pathlib import Path
from study import Runner, digest, read_jsonl, receive
from assemble_receivers import replace_failure


def validate_prefix(records,manifest,amendment):
    n=amendment['existing_response_count']
    if len(records)<n or digest(records[:n])!=amendment['existing_responses_sha256']:
        raise ValueError('Original log prefix changed')
    if digest(manifest)!=amendment['original_manifest_sha256']:
        raise ValueError('Original manifest changed')
    if amendment['expected_unique_tasks']-n!=amendment['max_new_unique_calls']:
        raise ValueError('Continuation call cap mismatch')
    if len({r['task_id'] for r in records})!=len(records):raise ValueError('Duplicate original tasks')
    if manifest['budget_guard_cny']!=amendment['budget_guard_cny']:raise ValueError('Budget changed')


def main():
    p=argparse.ArgumentParser(description=__doc__)
    for k in ['run','questions','materials','amendment']:p.add_argument('--'+k,type=Path,required=True)
    p.add_argument('--recovery',type=Path,action='append',default=[])
    p.add_argument('--execute',action='store_true');a=p.parse_args()
    records=read_jsonl(a.run/'responses.jsonl');manifest=json.loads((a.run/'manifest.json').read_text())
    amendment=json.loads(a.amendment.read_text());validate_prefix(records,manifest,amendment)
    qs=read_jsonl(a.questions);materials=json.loads(a.materials.read_text())
    if digest(qs)!=manifest['questions_sha256'] or digest(materials)!=manifest['materials_sha256']:
        raise ValueError('Frozen inputs changed')
    root=Path(__file__).parent
    freeze=json.loads((root/'protocol/formal-receiver-freeze.json').read_text())
    for name,expected in freeze['hashes'].items():
        if hashlib.sha256((root/name).read_bytes()).hexdigest()!=expected:raise ValueError('Frozen file changed: '+name)
    remaining=amendment['expected_unique_tasks']-len(records)
    runner=Runner(manifest['models'],a.run,amendment['budget_guard_cny'],remaining,
                  dt.datetime.fromisoformat(amendment['deadline']).timestamp())
    for folder in a.recovery:
        rs=read_jsonl(folder/'responses.jsonl');m=json.loads((folder/'manifest.json').read_text())
        if len(rs)!=1 or m['original_manifest_sha256']!=digest(manifest):raise ValueError('Invalid recovery')
        r=rs[0];runner.done[r['task_id']]=replace_failure(runner.done[r['task_id']],r,m)
    if any(r['status']!='ok' for r in runner.done.values()):raise ValueError('Unresolved provider error')
    if not a.execute:print(json.dumps({'remaining_calls':remaining,'deadline':amendment['deadline'],'frozen_files_verified':len(freeze['hashes'])}));return
    original_call=runner.call
    def recorded_call(provider,task,messages,metadata):
        return original_call(provider,task,messages,{**metadata,'continuation_amendment_sha256':digest(amendment)})
    runner.call=recorded_call
    receive(runner,qs,materials,manifest['repeats'])


if __name__=='__main__':main()
