"""Deterministic offline grading, question-cluster bootstrap, and run audit."""
import argparse
from collections import Counter, defaultdict
import hashlib
import json
from pathlib import Path
import random
import statistics
from study import CONDITIONS, MODELS, digest, grade, read_jsonl, timestamp
from collect import write_json


def percentile(values,p):
    values=sorted(values);i=(len(values)-1)*p;lo=int(i);hi=min(lo+1,len(values)-1)
    return values[lo]*(hi-i)+values[hi]*(i-lo) if hi!=lo else values[lo]


def bootstrap(rows,left,right,eligible='correct',outcome='incorrect',iterations=5000):
    # rows contain all model/repeat cells for one question; cluster at question.
    clusters=[]
    for cells in rows.values():
        valid=[x for x in cells if x['baseline']==eligible]
        clusters.append((sum((x[right]==outcome)-(x[left]==outcome) for x in valid),len(valid)))
    den=sum(n for _,n in clusters)
    if not den:return {'difference_pp':None,'ci95_pp':None,'eligible_cells':0,'question_clusters':len(clusters)}
    observed=100*sum(d for d,_ in clusters)/den
    if all(d==0 for d,_ in clusters):
        return {'difference_pp':observed,'ci95_pp':None,'eligible_cells':den,'question_clusters':len(clusters),
                'eligible_question_clusters':sum(n>0 for _,n in clusters),'bootstrap_iterations':0,
                'bootstrap_status':'degenerate_no_observed_cluster_variation',
                'interpretation':'Zero observed contrast is not proof of equivalence; empirical bootstrap cannot estimate uncertainty here.'}
    rng=random.Random(25011001);boot=[]
    for _ in range(iterations):
        sample=rng.choices(clusters,k=len(clusters));n=sum(x[1] for x in sample)
        if n:boot.append(100*sum(x[0] for x in sample)/n)
    return {'difference_pp':observed,'ci95_pp':[percentile(boot,.025),percentile(boot,.975)],
            'eligible_cells':den,'question_clusters':len(clusters),'bootstrap_iterations':iterations,
            'interpretation':'Descriptive paired contrast; question-cluster percentile bootstrap, fixed tested models.'}


def analyze(questions,records,adjudications=None):
    qs={q['question_id']:q for q in questions};adjudications=adjudications or {}
    scored=[];pending=[];seen=set()
    for r in records:
        if r['kind']!='receiver':continue
        if r['task_id'] in seen:raise ValueError('Duplicate task ID')
        seen.add(r['task_id']);q=qs[r['question_id']]
        status,why,target=grade(r.get('text'),q) if r['status']=='ok' else ('api_error',r['status'],None)
        key=digest({'question_id':q['question_id'],'text':r.get('text')})
        if status=='pending':
            pending.append({'review_id':key,'question_id':q['question_id'],'question':q['question'],
                            'gold':q['gold'],'gold_parts':q['gold_parts'],'false_parts':q['false_parts'],
                            'text':r.get('text'),'automatic_reason':why})
            if key in adjudications:
                a=adjudications[key]
                if a['status'] not in ['correct','incorrect','abstain','pending']:raise ValueError('Invalid adjudication')
                status,why,target=a['status'],'review: '+a['reason'],a.get('target_adopted')
        scored.append({k:r.get(k) for k in ['task_id','question_id','provider','generator','repeat','condition']} |
                      {'grade':status,'grade_reason':why,'target_adopted':target,'review_id':key})
    index={(r['question_id'],r['provider'],r['repeat'],r['condition']):r for r in scored}
    cells=[];incomplete=[]
    for key,r in index.items():
        if key[3]!='baseline':continue
        k=key[:3]
        if not all((*k,c) in index for c in CONDITIONS):incomplete.append(k);continue
        cell={'question_id':key[0],'provider':key[1],'repeat':key[2]}
        cell.update({c:index[(*k,c)]['grade'] for c in ['baseline']+CONDITIONS});cells.append(cell)
    tables={}
    for model in MODELS+['pooled']:
        current=[c for c in cells if model=='pooled' or c['provider']==model]
        tables[model]={}
        for condition in ['baseline']+CONDITIONS:
            counts=Counter(c[condition] for c in current);n=len(current)
            basecorrect=[c for c in current if c['baseline']=='correct'];basewrong=[c for c in current if c['baseline']=='incorrect']
            counts.update({'n':n,'baseline_correct_n':len(basecorrect),'baseline_incorrect_n':len(basewrong),
                           'correct_to_incorrect':sum(c[condition]=='incorrect' for c in basecorrect),
                           'correct_to_abstain':sum(c[condition]=='abstain' for c in basecorrect),
                           'incorrect_to_correct':sum(c[condition]=='correct' for c in basewrong)})
            counts['accuracy_pct']=100*counts['correct']/n if n else None
            counts['harm_pct']=100*counts['correct_to_incorrect']/len(basecorrect) if basecorrect else None
            counts['repair_pct']=100*counts['incorrect_to_correct']/len(basewrong) if basewrong else None
            tables[model][condition]=dict(counts)
    effects={}
    for model in MODELS+['pooled']:
        groups=defaultdict(list)
        for c in cells:
            if model=='pooled' or c['provider']==model:groups[c['question_id']].append(c)
        effects[model]={
            'RQ1_C2_minus_C1_harm':bootstrap(groups,'C1','C2'),
            'RQ2_C3_minus_C2_harm':bootstrap(groups,'C2','C3'),
            'control_C5_minus_C4_repair':bootstrap(groups,'C4','C5','incorrect','correct')}
    usage={}
    for model in MODELS:
        rs=[r for r in records if r['provider']==model]
        usage[model]={'calls':len(rs),'statuses':dict(Counter(r['status'] for r in rs)),
                      'input_tokens':sum(r.get('input_tokens',0) for r in rs),'output_tokens':sum(r.get('output_tokens',0) for r in rs),
                      'cost_upper_cny':sum(r.get('cost_upper_cny',0) for r in rs),
                      'median_latency_seconds':statistics.median(r['latency_seconds'] for r in rs) if rs else None,
                      'returned_models':sorted(set(r.get('model_returned','unknown') for r in rs))}
    result={'created_at':timestamp(),'questions':len(qs),'questions_sha256':digest(questions),'responses':len(records),
            'records_sha256':digest(records),'complete_cells':len(cells),'incomplete_cells':incomplete,
            'unresolved_grades':sum(r['grade']=='pending' for r in scored),'tables':tables,'effects':effects,'usage':usage,
            'independent_human_review_complete':False,'adjudications_sha256':digest(adjudications)}
    return result,scored,{p['review_id']:p for p in pending}


def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--questions',type=Path,required=True);p.add_argument('--responses',type=Path,required=True)
    p.add_argument('--adjudications',type=Path);p.add_argument('--out',type=Path,required=True)
    args=p.parse_args();args.out.mkdir(parents=True,exist_ok=True)
    ad=json.loads(args.adjudications.read_text()) if args.adjudications else None
    result,scored,pending=analyze(read_jsonl(args.questions),read_jsonl(args.responses),ad)
    write_json(args.out/'summary.json',result);write_json(args.out/'grades.json',scored)
    # Contains no provider, condition, generator, or task ID. Gold is necessary for date adjudication.
    write_json(args.out/'blinded_format_review.json',pending)
    print(json.dumps({'questions':result['questions'],'complete_cells':result['complete_cells'],
                      'pending':result['unresolved_grades'],'incomplete':len(result['incomplete_cells']),
                      'pooled':result['tables']['pooled'],'effects':result['effects']['pooled']},ensure_ascii=False))


if __name__=='__main__':main()
