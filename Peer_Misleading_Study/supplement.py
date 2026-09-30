"""Descriptive secondary outcomes; does not change frozen primary analysis."""
import argparse
from collections import Counter
import json
from pathlib import Path
import statistics
from study import CONDITIONS, MODELS, read_jsonl, digest
from collect import write_json


def percent(num, den):
    return 100*num/den if den else None


def summarize(records, grades):
    gs = {g['task_id']:g for g in grades}
    cells = {}
    for r in records:
        key = (r['question_id'], r['provider'], r['repeat'])
        cells.setdefault(key,{})[r['condition']] = gs[r['task_id']]
    complete = {k:v for k,v in cells.items() if set(v)==set(['baseline']+CONDITIONS)}
    result = {'scope':'Secondary descriptive outcomes; no additional hypothesis tests.',
              'records_sha256':digest(records),'grades_sha256':digest(grades),'tables':{},'C2_C3_transitions':{},
              'neutral_comparisons':{},'condition_usage':{}}
    for model in MODELS+['pooled']:
        rows = [v for k,v in complete.items() if model=='pooled' or k[1]==model]
        table = {}
        for c in ['baseline']+CONDITIONS:
            counts = Counter(v[c]['grade'] for v in rows)
            correct = counts['correct']; wrong = counts['incorrect']; answered = correct+wrong
            basecorrect = [v for v in rows if v['baseline']['grade']=='correct']
            table[c] = {'n':len(rows),'correct':correct,'incorrect':wrong,'abstain':counts['abstain'],
                        'pending':counts['pending'],'answered':answered,
                        'coverage_pct':percent(answered,len(rows)),
                        'accuracy_among_answered_pct':percent(correct,answered),
                        'wrong_answers_per_100_questions':percent(wrong,len(rows)),
                        'target_adoptions_all':sum(v[c]['target_adopted'] is True for v in rows),
                        'target_adoptions_from_initial_correct':sum(v[c]['target_adopted'] is True for v in basecorrect),
                        'initial_correct_n':len(basecorrect),
                        'baseline_transitions':dict(Counter(v['baseline']['grade']+'->'+v[c]['grade'] for v in rows))}
        result['tables'][model] = table
        result['C2_C3_transitions'][model] = dict(Counter(v['C2']['grade']+'->'+v['C3']['grade'] for v in rows))
        result['neutral_comparisons'][model] = {}
        for c in ['C2','C3']:
            eligible = [v for v in rows if v['baseline']['grade']=='correct']
            result['neutral_comparisons'][model][c+'_minus_C0'] = {
                'accuracy_difference_pp':percent(sum((v[c]['grade']=='correct')-(v['C0']['grade']=='correct') for v in rows),len(rows)),
                'harm_difference_pp':percent(sum((v[c]['grade']=='incorrect')-(v['C0']['grade']=='incorrect') for v in eligible),len(eligible)),
                'eligible_correct_cells':len(eligible),'n':len(rows)}
        result['condition_usage'][model] = {}
        for c in ['baseline']+CONDITIONS:
            rs = [r for r in records if r['condition']==c and (model=='pooled' or r['provider']==model)]
            result['condition_usage'][model][c] = {
                'calls':len(rs),'input_tokens':sum(r.get('input_tokens',0) for r in rs),
                'output_tokens':sum(r.get('output_tokens',0) for r in rs),
                'median_latency_seconds':statistics.median(r['latency_seconds'] for r in rs) if rs else None,
                'cost_guard_cny':sum(r.get('cost_upper_cny',0) for r in rs)}
    return result


def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--responses',type=Path,required=True)
    p.add_argument('--grades',type=Path,required=True)
    p.add_argument('--out',type=Path,required=True)
    a=p.parse_args()
    result=summarize(read_jsonl(a.responses),json.loads(a.grades.read_text()))
    a.out.parent.mkdir(parents=True,exist_ok=True);write_json(a.out,result)
    print('Saved descriptive supplementary outcomes')

if __name__=='__main__':main()
