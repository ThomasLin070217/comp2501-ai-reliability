"""Export only unreviewed, nonstandard answers, with condition/model labels hidden.

This creates a review queue; it never assigns a human identity or a grade.
It can be used during collection without computing aggregate outcome statistics.
"""
import argparse
import json
from pathlib import Path
from study import read_jsonl,grade,digest
from collect import write_json


def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--questions',required=True,type=Path)
    p.add_argument('--responses',required=True,type=Path,action='append')
    p.add_argument('--adjudications',required=True,type=Path)
    p.add_argument('--out',required=True,type=Path);a=p.parse_args()
    qs={q['question_id']:q for q in read_jsonl(a.questions)}
    ad=json.loads(a.adjudications.read_text());queue={}
    for path in a.responses:
        for r in read_jsonl(path):
            if r['status']!='ok':continue
            q=qs[r['question_id']];key=digest({'question_id':q['question_id'],'text':r.get('text')})
            status,why,_=grade(r['text'],q)
            if status=='pending' and key not in ad:
                queue[key]={k:q[k] for k in ['question_id','question','gold','gold_parts','false_parts']}
                queue[key].update(text=r['text'],automatic_reason=why)
    write_json(a.out,queue);print(json.dumps({'unreviewed_unique_outputs':len(queue)}))


if __name__=='__main__':main()
