"""Create readable tables from saved analysis, without model calls."""
import argparse
import json
from pathlib import Path
from study import MODELS, CONDITIONS

LABELS={'baseline':'初始回答','C0':'中性复核','C1':'错误日期','C2':'错误日期＋解释',
        'C3':'相同错误建议＋结构化核验','C4':'正确目标＋解释','C5':'相同正确建议＋结构化核验'}
NAMES={'deepseek':'DeepSeek V4 Pro','kimi':'Kimi K2.6','minimax':'MiniMax M3（HKU）','pooled':'合并'}

def pct(value):return '不可估计' if value is None else f'{value:.2f}%'
def effect(e):
    v=e['difference_pp'];ci=e['ci95_pp']
    if v is None:return '不可估计（无合格分母）'
    return f'{v:+.2f} pp；'+(f'95% CI [{ci[0]:+.2f}, {ci[1]:+.2f}]' if ci else '区间不可估计；不代表等效')
def ratio(n,d):return f'{n}/{d}（{pct(100*n/d if d else None)}）'


def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--summary',type=Path,required=True);p.add_argument('--supplement',type=Path,required=True)
    p.add_argument('--sensitivity',type=Path);p.add_argument('--usage',type=Path)
    p.add_argument('--out',type=Path,required=True);a=p.parse_args()
    s=json.loads(a.summary.read_text());sup=json.loads(a.supplement.read_text())
    lines=['# 实验统计表','',f"{s['questions']} 道题；{s['responses']:,} 次响应；{s['complete_cells']} 个完整配对单元。未解决评分：{s['unresolved_grades']}。",'',
           '以下表格由保存的分析文件生成。准确率的分母包含拒答；拒答不算事实错误，也不算正确。“错误”是任务判分，包含未拒答但答案精度不足的情况，不表示每条都断言了一个明确的错误事实；相关边界另有敏感性分析。题目是重采样单位，模型与重复不是独立题目。','',
           '## 合并结果','', '| 条件 | 正确／全部 | 错误 | 拒答 | 初始正确→错误 | 初始正确→拒答 | 初始错误→正确 |',
           '|---|---:|---:|---:|---:|---:|---:|']
    for c in ['baseline']+CONDITIONS:
        t=s['tables']['pooled'][c]
        lines.append(f"| {c} {LABELS[c]} | {ratio(t.get('correct',0),t['n'])} | {t.get('incorrect',0)} | {t.get('abstain',0)} | {ratio(t['correct_to_incorrect'],t['baseline_correct_n'])} | {ratio(t['correct_to_abstain'],t['baseline_correct_n'])} | {ratio(t['incorrect_to_correct'],t['baseline_incorrect_n'])} |")
    if s.get('output_quality'):
        q=s['output_quality']
        lines+=['',f"原始接口响应 {q['raw_responses']:,} 条；不可判分输出 {len(q['unscorable_outputs'])} 条。按采集后的透明质量修订，配对分析移出 {len(q['excluded_cells'])} 个完整单元（每单元七条），原始数据均保留；这不是丢弃答错案例。",'']
    lines+=['','## 预定配对比较','', '| 模型 | C2−C1 改错率：增加解释 | C3−C2 改错率：结构化核验 | C5−C4 纠错率：正确目标控制 |','|---|---|---|---|']
    for m in MODELS+['pooled']:
        e=s['effects'][m]
        lines.append('| '+NAMES[m]+' | '+' | '.join(effect(e[k]) for k in ['RQ1_C2_minus_C1_harm','RQ2_C3_minus_C2_harm','control_C5_minus_C4_repair'])+' |')
    lines+=['','pp 表示百分点。前两列越负表示改错更少；第三列越负表示纠错能力更低。区间为题目聚类百分位 bootstrap 的边际 95% 区间，未用于多重显著性宣称。没有观察到差异不能证明方法等效。','',
            '## 各模型准确率与分母','', '| 条件 | DeepSeek | Kimi | MiniMax（HKU） |','|---|---:|---:|---:|']
    for c in ['baseline']+CONDITIONS:
        lines.append('| '+c+' '+LABELS[c]+' | '+' | '.join(ratio(s['tables'][m][c].get('correct',0),s['tables'][m][c]['n']) for m in MODELS)+' |')
    lines+=['','## 指定错误采纳与选择性回答（辅助描述）','', '| 条件 | 初始正确后采纳预设错误 | 全部预设错误采纳 | 回答覆盖率 | 已回答中的正确率 |','|---|---:|---:|---:|---:|']
    for c in ['baseline']+CONDITIONS:
        t=sup['tables']['pooled'][c]
        lines.append(f"| {c} | {ratio(t['target_adoptions_from_initial_correct'],t['initial_correct_n'])} | {ratio(t['target_adoptions_all'],t['n'])} | {ratio(t['answered'],t['n'])} | {ratio(t['correct'],t['answered'])} |")
    lines+=['','预设错误与其他错误分开统计。baseline 的预设错误采纳只是恰好答到该日期，不能解释为受建议影响。覆盖率降低可能伴随已回答准确率提高，不能只选报后者。','',
            '## 与中性复核比较（辅助描述）','', '| 模型 | 比较 | 最终准确率差（pp） | 改错率差（pp） | 初始正确分母 |','|---|---|---:|---:|---:|']
    for m in MODELS+['pooled']:
        for k,v in sup['neutral_comparisons'][m].items():
            fmt=lambda x:'不可估计' if x is None else f'{x:+.2f}'
            lines.append(f"| {NAMES[m]} | {k} | {fmt(v['accuracy_difference_pp'])} | {fmt(v['harm_difference_pp'])} | {v['eligible_correct_cells']} |")
    lines+=['','## 纳入配对分析响应的 token 与延迟','', '| 模型 | 条件 | 调用 | 输入 token | 输出 token | 中位延迟（秒） |','|---|---|---:|---:|---:|---:|']
    for m in MODELS:
        for c in ['baseline']+CONDITIONS:
            t=sup['condition_usage'][m][c]
            latency='—' if t['median_latency_seconds'] is None else f"{t['median_latency_seconds']:.2f}"
            lines.append(f"| {NAMES[m]} | {c} | {t['calls']} | {t['input_tokens']:,} | {t['output_tokens']:,} | {latency} |")
    lines+=['','延迟受服务端负载、网络及 HKU 转发影响，不是受控速度排行榜。C2/C3 和 C4/C5 调用数相同，输入长度与 token 成本不同。','']
    if a.sensitivity:
        sens=json.loads(a.sensitivity.read_text())
        lines+=['## 敏感性分析','', '| 版本 | 题目 | 初始正确分母 | C2−C1 改错率差 | C3−C2 改错率差 |','|---|---:|---:|---|---|']
        for name,v in sens['variants'].items():
            e=v['effects']['pooled']
            lines.append(f"| {name} | {v['questions']} | {v['tables']['pooled']['baseline']['baseline_correct_n']} | {effect(e['RQ1_C2_minus_C1_harm'])} | {effect(e['RQ2_C3_minus_C2_harm'])} |")
        lines+=['', '整题剔除版本的题号：'+', '.join(sorted(set(sens['excluded_disputed_question_ids']+sens['excluded_source_caveat_question_ids']+sens.get('excluded_unscorable_question_ids',[]))))+'。替代评分规则和逐条理由保存在 adjudications 文件；所有变体一起报告，不能选有利版本替代主结果。不可用输出按未答出／非回答计入的变体是运行质量敏感性分析，不把缺失内容断言为事实错误。','']
    if a.usage:
        u=json.loads(a.usage.read_text());lines+=['## 全部阶段用量','', '| 阶段 | 响应数 | 输入 token | 输出 token | 保守计价（人民币） |','|---|---:|---:|---:|---:|']
        for stage,v in u['stages'].items():lines.append(f"| {stage} | {v['calls']:,} | {v['input_tokens']:,} | {v['output_tokens']:,} | {v['cost_guard_cny']:.4f} |")
        lines+=['',f"累计保守计价 **{u['total']['cost_guard_cny']:.4f} 元**；这不是账单。MiniMax 经 HKU 的价格未知，0 计价不表示免费，token 单独保存。材料预检失败和未入选材料也计入总用量。",'']
    lines+=['## 审阅与范围','', '题目、来源、材料和必要的语义评分由 Codex 处理，非独立人工标注。开发难度警报未按原计划完整处理，见执行偏离复核；不能将这套课程评估称作已充分功效验证的确认性实验。错误建议由研究者指定，不是模型自然错误率。结果仅适用于这些模型、日期题、英文提示、参数及冻结材料。','']
    a.out.write_text('\n'.join(lines))
    print('Saved statistics tables')

if __name__=='__main__':main()
