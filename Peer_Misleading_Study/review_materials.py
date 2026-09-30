"""Record a completed Codex content screen of explicitly named questions.

This command does not perform semantic review. The operator must read all selected
explanations before using it. Non-mentioned questions remain unreviewed.
"""
import argparse,json
from pathlib import Path
from freeze_materials import propose
from study import digest,read_jsonl,timestamp

p=argparse.ArgumentParser(description=__doc__)
p.add_argument('--ids',nargs='+',required=True)
p.add_argument('--reject',default='{}',help='JSON mapping task ID to observed content problem')
a=p.parse_args();root=Path(__file__).resolve().parent
rp=root/'data/main_material_rejections.json';reject=json.loads(rp.read_text()) if rp.exists() else {}
reject.update(json.loads(a.reject));rp.write_text(json.dumps(reject,ensure_ascii=False,indent=2)+'\n')
qs=read_jsonl(root/'data/main_candidate_questions.jsonl');rs=read_jsonl(root/'runs/main_materials/responses.jsonl')
materials,audit,missing=propose(qs,rs,reject)
reviewfile=root/'data/main_content_reviews.json';reviews=json.loads(reviewfile.read_text()) if reviewfile.exists() else {}
for row in audit:
    if row['key'].split(':')[0] not in a.ids:continue
    if row['selected']:
        reviews[row['key']]={'task_id':row['task_id'],'material_sha256':digest(materials[row['key']]),'status':'screened',
          'reviewer':'Codex','timestamp':timestamp(),'independent_human_review_complete':False,
          'scope':'Inspected for explicit experiment leakage, target contradiction, and obvious false supporting claims in correct-target suggestions. Background assertions are not comprehensively fact-checked.'}
reviewfile.write_text(json.dumps(reviews,ensure_ascii=False,indent=2)+'\n')
print(json.dumps({'total_screened_slots':len(reviews),'rejected_tasks':len(reject),'currently_missing_slots':len(missing)}))
