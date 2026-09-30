"""Deterministic illustrative cases plus an index of every matching cell."""
import argparse
import json
from pathlib import Path
from study import read_jsonl, CONDITIONS
from collect import write_json


def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--questions',type=Path,required=True);p.add_argument('--responses',type=Path,required=True)
    p.add_argument('--grades',type=Path,required=True);p.add_argument('--materials',type=Path,required=True)
    p.add_argument('--out',type=Path,required=True);a=p.parse_args();a.out.mkdir(parents=True,exist_ok=True)
    qs={q['question_id']:q for q in read_jsonl(a.questions)};rs=read_jsonl(a.responses)
    grades={g['task_id']:g for g in json.loads(a.grades.read_text())};materials=json.loads(a.materials.read_text())
    cells={}
    for r in rs:
        k=f'{r["question_id"]}:{r["provider"]}:r{r["repeat"]}'
        cells.setdefault(k,{})[r['condition']]=r
    def status(v,c):return grades[v[c]['task_id']]['grade']
    predicates={
      'harm_after_explanation':lambda v:status(v,'baseline')=='correct' and status(v,'C2')=='incorrect',
      'structured_rescue':lambda v:status(v,'baseline')=='correct' and status(v,'C2')=='incorrect' and status(v,'C3')=='correct',
      'structured_harm':lambda v:status(v,'C2')=='correct' and status(v,'C3')=='incorrect',
      'correct_advice_repair':lambda v:status(v,'baseline')=='incorrect' and status(v,'C4')=='correct',
      'initial_knowledge_error':lambda v:status(v,'baseline')=='incorrect'}
    index={name:[k for k in sorted(cells) if len(cells[k])==7 and pred(cells[k])] for name,pred in predicates.items()}
    selected=[]
    for category,keys in index.items():
        if not keys:continue
        k=keys[0];v=cells[k];r=v['baseline'];q=qs[r['question_id']];g=r['generator']
        selected.append({'category':category,'cell_id':k,'question':q['question'],'gold':q['gold'],
                         'source':q['verified_source_url'],'generator':g,
                         'wrong_material':materials[f'{q["question_id"]}:{g}:wrong'],
                         'correct_material':materials[f'{q["question_id"]}:{g}:correct'],
                         'responses':{c:{'task_id':v[c]['task_id'],'text':v[c]['text'],'grade':status(v,c)} for c in ['baseline']+CONDITIONS}})
    write_json(a.out/'case_index.json',{'selection':'First lexicographic cell ID in each descriptive category; all matches are listed.',
                                     'counts':{k:len(v) for k,v in index.items()},'all_matches':index})
    write_json(a.out/'illustrative_cases.json',selected)
    lines=['# 可追溯的接收模型案例','', '从每类结果中按题号、模型、重复号排序取第一条，不挑最戏剧性的例子。所有匹配单元见 case_index.json；案例只能说明可能出现的行为，整体频率以完整统计为准。C2 和 C3 是从相同 baseline 出发的平行分支，不能把两者结果差异讲成 C3 先读到 C2 再进行修正。','']
    for x in selected:
        lines += ['## '+x['category'],'', '`'+x['cell_id']+'`', '',x['question'],'',f"参考答案：{x['gold']}。[核对来源]({x['source']})。建议生成者：{x['generator']}。",'',
                  '实验错误建议（故意构造，不能作为事实引用）：','',json.dumps(x['wrong_material'],ensure_ascii=False),'',
                  '正确目标建议（不保证每句背景断言都经独立核实）：','',json.dumps(x['correct_material'],ensure_ascii=False),'']
        for c,r in x['responses'].items():lines += [f"### {c} · {r['grade']}",'', '```text',r['text'],'```','',f"任务 ID：`{r['task_id']}`",'']
    (a.out/'cases.md').write_text('\n'.join(lines))
    print('Saved case index and deterministic examples')

if __name__=='__main__':main()
