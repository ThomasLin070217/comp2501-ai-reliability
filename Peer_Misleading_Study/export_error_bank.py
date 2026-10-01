"""Export question-level error evidence from actual initial answers, not forced advice.

All questions are retained in the full index; the error bank is an explicitly
filtered convenience view and must not be used to estimate population error rates.
"""
import argparse
from collections import Counter
import json
from pathlib import Path
from study import read_jsonl,digest
from collect import write_json


def build(questions,records,grades):
    gs={g['task_id']:g for g in grades};byq={q['question_id']:[] for q in questions}
    for r in records:
        if r['condition']!='baseline':continue
        g=gs[r['task_id']]
        byq[r['question_id']].append({'task_id':r['task_id'],'model':r['provider'],'model_returned':r['model_returned'],
            'repeat':r['repeat'],'text':r['text'],'grade':g['grade'],'grade_reason':g['grade_reason'],
            'timestamp':r['timestamp'],'request_sha256':r['request_sha256']})
    rows=[]
    for q in questions:
        replies=sorted(byq[q['question_id']],key=lambda r:r['task_id']);counts=Counter(r['grade'] for r in replies)
        rows.append({'question_id':q['question_id'],'question':q['question'],'reference_answer':q['gold'],
            'granularity':q['granularity'],'topic':q['topic'],'verified_source_url':q['verified_source_url'],
            'benchmark':'Google SimpleQA Verified','source_id':q['source_id'],
            'initial_answers':replies,'initial_grade_counts':dict(counts),'initial_observations':len(replies),
            'observed_initial_error':counts['incorrect']>0,
            'all_six_initial_answers_incorrect':len(replies)==6 and counts['incorrect']==6,
            'independent_human_review_complete':False})
    return rows


def main():
    p=argparse.ArgumentParser(description=__doc__)
    for k in ['questions','responses','grades','out']:p.add_argument('--'+k,type=Path,required=True)
    a=p.parse_args();a.out.mkdir(parents=True,exist_ok=True)
    qs=read_jsonl(a.questions);rs=read_jsonl(a.responses);gs=json.loads(a.grades.read_text())
    rows=build(qs,rs,gs);bank=[r for r in rows if r['observed_initial_error']]
    for name,values in [('all_questions_observed',rows),('observed_initial_error_bank',bank)]:
        (a.out/(name+'.jsonl')).write_text(''.join(json.dumps(r,ensure_ascii=False)+'\n' for r in values))
    summary={'scope':'Observed initial answers in this frozen, selected date-fact sample; no forced peer responses counted as initial errors.',
        'questions_total':len(rows),'questions_with_observed_initial_error':len(bank),
        'questions_all_six_initial_answers_incorrect':sum(r['all_six_initial_answers_incorrect'] for r in rows),
        'baseline_observations':sum(r['initial_observations'] for r in rows),'records_sha256':digest(rs),
        'grades_sha256':digest(gs),'independent_human_review_complete':False}
    write_json(a.out/'index.json',summary)
    lines=['# 本轮实际出错题库','',
        '只使用接收模型首次独立回答的判分；不把研究者故意生成的错误建议冒充模型自然出错。',
        '这是已测样本中的可追溯错误案例，不是所有 AI 最难问题的排名。完整索引保留全部题，错误库明确按“至少一次初答错误”过滤。初答只取完整配对主分析纳入的单元；某单元因其他分支不可判分而整体移出时，其初答也不在此表。',
        '判分要求达到题目请求的日期精度；incorrect 也包括未明确拒答但精度不足的答案，详见 grade_reason。来源与语义审查由 Codex 完成，尚无独立人工复核。','',
        f"全部 {len(rows)} 题；{len(bank)} 题至少出现一次初答错误；{summary['questions_all_six_initial_answers_incorrect']} 题在三模型两重复的六次初答中全部判错。",'',
        '- `all_questions_observed.jsonl`：全部题及实际初始回答，包含正确题和拒答。',
        '- `observed_initial_error_bank.jsonl`：明确筛选的实测错误库，包含题目、来源、原始答案、模型、任务 ID 和请求哈希。',
        '- 模型返回文本和基准标签均是待检查的数据；不可把其中的断言直接当事实引用。','',
        '| 题号 | 题目 | 初答错误／纳入初答 | 参考答案 |','|---|---|---:|---|']
    for r in sorted(bank,key=lambda r:r['question_id']):
        question=r['question'].replace('|','\\|');gold=r['reference_answer'].replace('|','\\|')
        lines.append(f"| {r['question_id']} | {question} | {r['initial_grade_counts'].get('incorrect',0)}/{r['initial_observations']} | [{gold}]({r['verified_source_url']}) |")
    (a.out/'README.md').write_text('\n'.join(lines)+'\n');print(json.dumps(summary))


if __name__=='__main__':main()
