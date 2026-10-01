"""Report transparent alternative adjudications and disputed-item exclusions.

Variants are secondary; the frozen primary results are never overwritten.
"""
import argparse
import datetime as dt
from collections import defaultdict
import json
from pathlib import Path
from analyze import analyze
from study import read_jsonl, digest
from collect import write_json
from quality_analyze import filter_quality


def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--questions',type=Path,required=True)
    p.add_argument('--responses',type=Path,required=True)
    p.add_argument('--adjudications',type=Path,required=True)
    p.add_argument('--caveats',type=Path,required=True)
    p.add_argument('--out',type=Path,required=True);a=p.parse_args()
    qs=read_jsonl(a.questions);raw=read_jsonl(a.responses);ad=json.loads(a.adjudications.read_text())
    rs,quality=filter_quality(qs,raw,ad)
    caveats=json.loads(a.caveats.read_text());alternative={k:dict(v) for k,v in ad.items()}
    changed=[]
    for key,value in ad.items():
        if value.get('alternative_status'):
            alternative[key]['status']=value['alternative_status']
            alternative[key]['target_adopted']=value.get('alternative_target_adopted')
            alternative[key]['reason']='Sensitivity alternative: '+value['reason']
            changed.append(key)
    disputed={r['question_id'] for r in rs if ad.get(digest({'question_id':r['question_id'],'text':r.get('text')}),{}).get('disputed')}
    source_caveats={c['question_id'] for c in caveats['question_caveats']}
    unscorable_questions={c[0] for c in quality['excluded_cells']}
    exclude=disputed|source_caveats|unscorable_questions
    variants={}
    plans=[
        ('primary',qs,rs,ad),
        ('alternative_adjudications',qs,rs,alternative),
        ('exclude_disputed_and_source_caveats',[q for q in qs if q['question_id'] not in exclude],
         [r for r in rs if r['question_id'] not in exclude],ad)]
    if quality['unscorable_outputs']:
        plans.append(('exclude_unscorable_questions_only',
            [q for q in qs if q['question_id'] not in unscorable_questions],
            [r for r in rs if r['question_id'] not in unscorable_questions],ad))
        for status,name in [('incorrect','unscorable_as_unsuccessful_answer'),('abstain','unscorable_as_nonanswer')]:
            decisions={k:dict(v) for k,v in ad.items()}
            for item in quality['unscorable_outputs']:
                decisions[item['review_id']].update(status=status,target_adopted=None,
                    reason='Operational sensitivity for unusable output; not a claim about its missing factual answer.')
            plans.append((name,qs,raw,decisions))
    note_path=Path(__file__).resolve().parent/'protocol/morning-analysis-note.json'
    spanning=set()
    if note_path.exists():
        note=json.loads(note_path.read_text());cutoff=dt.datetime.fromisoformat(note['cutoff'])
        sides=defaultdict(set)
        for r in rs:
            sides[(r['question_id'],r['provider'],r['repeat'])].add(dt.datetime.fromisoformat(r['timestamp'])>=cutoff)
        spanning={k for k,v in sides.items() if len(v)==2}
        if spanning:plans.append(('exclude_cells_spanning_overnight_pause',qs,
            [r for r in rs if (r['question_id'],r['provider'],r['repeat']) not in spanning],ad))
    for name,questions,records,decisions in plans:
        if not questions:continue
        summary,_,_=analyze(questions,records,decisions)
        variants[name]={k:summary[k] for k in ['questions','responses','complete_cells','unresolved_grades','tables','effects']}
    write_json(a.out,{'scope':'Secondary sensitivity analysis; all variants reported, no favorable-rule selection.',
                     'alternative_review_ids':changed,'excluded_disputed_question_ids':sorted(disputed),
                     'excluded_source_caveat_question_ids':sorted(source_caveats),
                     'excluded_unscorable_question_ids':sorted(unscorable_questions),
                     'output_quality':quality,'excluded_overnight_spanning_cells':[list(c) for c in sorted(spanning)],'variants':variants})
    print('Saved primary, alternative-adjudication and exclusion sensitivity variants')

if __name__=='__main__':main()
