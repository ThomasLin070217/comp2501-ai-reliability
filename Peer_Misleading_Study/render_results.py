"""Render offline analysis as exportable figures and a self-contained case explorer.

Requires matplotlib; collection and statistical analysis use the standard library.
"""
import argparse
import base64
from collections import defaultdict
import html
import json
from pathlib import Path
import os
import tempfile
os.environ.setdefault('MPLCONFIGDIR',str(Path(tempfile.gettempdir())/'comp2501-mpl'))
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from study import CONDITIONS, MODELS, read_jsonl

LABELS={'baseline':'Initial answer','C0':'Neutral review','C1':'Wrong date only','C2':'Wrong date + explanation',
        'C3':'Same wrong advice + check','C4':'Correct target + explanation','C5':'Same correct advice + check'}
NAMES={'deepseek':'DeepSeek V4 Pro','kimi':'Kimi K2.6','minimax':'MiniMax M3 (HKU)','pooled':'All tested models'}
COLORS={'correct':'#277c78','incorrect':'#be5347','abstain':'#9aabc0','pending':'#eac679'}


def plot(summary,out):
    plt.rcParams.update({'font.family':'DejaVu Sans','font.size':10,'axes.spines.top':False,'axes.spines.right':False,
                         'axes.spines.left':False,'svg.hashsalt':'comp2501-peer-study-v1','axes.titleweight':'bold','figure.facecolor':'#fbfaf7','axes.facecolor':'#fbfaf7'})
    cs=['baseline']+CONDITIONS
    fig,axes=plt.subplots(2,2,figsize=(13,8.5),layout='constrained')
    for ax,model in zip(axes.flat,MODELS+['pooled']):
        table=summary['tables'][model];left=[0]*len(cs)
        for status,color in COLORS.items():
            values=[100*table[c].get(status,0)/table[c]['n'] for c in cs]
            ax.barh(cs,values,left=left,color=color,height=.7,label=status.capitalize())
            left=[a+b for a,b in zip(left,values)]
        for i,c in enumerate(cs):
            v=table[c]['accuracy_pct']
            if v>7:ax.text(v/2,i,f'{v:.1f}%',ha='center',va='center',color='white',fontsize=9)
        ax.set_yticks(range(len(cs)),[LABELS[c] for c in cs]);ax.invert_yaxis();ax.set_xlim(0,100)
        ax.set_xlabel('Share of all responses (%)');ax.set_title(NAMES[model]+f" · {table['baseline']['n']} cells")
        ax.grid(axis='x',alpha=.1);ax.set_axisbelow(True)
    handles,labels=axes.flat[0].get_legend_handles_labels()
    fig.legend(handles,labels,loc='outside lower center',ncol=4,frameon=False)
    fig.suptitle(f"Peer advice and factual accuracy · {summary['questions']} questions",fontsize=17)
    fig.savefig(out/'accuracy.png',dpi=180);fig.savefig(out/'accuracy.svg',metadata={'Date':None});plt.close(fig)
    fig,axes=plt.subplots(1,2,figsize=(13.5,5.2),layout='constrained')
    keys=['RQ1_C2_minus_C1_harm','RQ2_C3_minus_C2_harm']
    for ax,key,title in zip(axes,keys,['Adding a wrong explanation: C2 − C1','Structured checking: C3 − C2']):
        for i,model in enumerate(MODELS+['pooled']):
            e=summary['effects'][model][key];v=e['difference_pp'];ci=e['ci95_pp']
            if v is not None and ci is None:
                ax.plot(v,i,'x',color='#8d6b50',ms=8)
                ax.annotate(f'{v:+.1f} [interval not estimable]',(v,i),xytext=(0,12),textcoords='offset points',ha='center',fontsize=8)
            elif v is not None:
                ax.hlines(i,ci[0],ci[1],color='#277c78',lw=2);ax.plot(v,i,'o',color='#173d4a',ms=7)
                ax.annotate(f"{v:+.1f} [{ci[0]:+.1f}, {ci[1]:+.1f}]",(v,i),xytext=(0,12),textcoords='offset points',ha='center',fontsize=8)
        ax.axvline(0,color='#787b80',ls='--',lw=1);ax.set_yticks(range(4),[NAMES[x]+f"\ninitial correct n={summary['tables'][x]['baseline']['baseline_correct_n']}" for x in MODELS+['pooled']])
        ax.invert_yaxis();ax.set_ylim(3.5,-.65);ax.set_title(title);ax.set_xlabel('Change in correct-to-incorrect rate\n(percentage points)')
        ax.grid(axis='x',alpha=.12)
    fig.suptitle('Paired contrasts · 95% question-cluster bootstrap intervals',fontsize=14)
    fig.savefig(out/'effects.png',dpi=180);fig.savefig(out/'effects.svg',metadata={'Date':None});plt.close(fig)

    for filename in ['accuracy.svg','effects.svg']:
        svg=out/filename;svg.write_text('\n'.join(line.rstrip() for line in svg.read_text().splitlines())+'\n')

def dashboard(summary,questions,records,grades,materials,out):
    qs={q['question_id']:q for q in questions};gs={g['task_id']:g for g in grades};cells={}
    for r in records:
        key=f'{r["question_id"]}:{r["provider"]}:r{r["repeat"]}'
        cell=cells.setdefault(key,{'id':key,'qid':r['question_id'],'model':r['provider'],'repeat':r['repeat'],
            'question':qs[r['question_id']]['question'],'gold':qs[r['question_id']]['gold'],
            'source':qs[r['question_id']]['verified_source_url'],'generator':r['generator'],'answers':{}})
        cell['answers'][r['condition']]={'text':r['text'],'grade':gs[r['task_id']]['grade'],'task_id':r['task_id']}
    for c in cells.values():
        c['wrong']=materials[f'{c["qid"]}:{c["generator"]}:wrong'];c['right']=materials[f'{c["qid"]}:{c["generator"]}:correct']
    data=json.dumps({'summary':summary,'cells':list(cells.values())},ensure_ascii=False).replace('<','\\u003c').replace('>','\\u003e')
    def img(name):return 'data:image/png;base64,'+base64.b64encode((out/name).read_bytes()).decode()
    page='''<!doctype html><html lang="zh-CN"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>COMP2501 · AI 同伴误导实验</title><style>
:root{color-scheme:light}*{box-sizing:border-box}body{margin:0;background:#f8f7f3;color:#21333b;font-family:-apple-system,BlinkMacSystemFont,"PingFang SC",sans-serif;line-height:1.6}main{max-width:1240px;margin:auto;padding:44px 30px}h1{font-size:36px;line-height:1.25;margin:10px 0}h2{font-size:23px;margin-top:42px}.eyebrow{letter-spacing:.12em;color:#57717a;font-size:12px}.muted{color:#65757c}.cards{display:grid;grid-template-columns:repeat(3,1fr);gap:14px;margin:25px 0}.card,.panel{background:white;border:1px solid #dfe5e5;border-radius:12px;padding:20px}.card b{font-size:28px;display:block}.tablewrap{overflow-x:auto}table{width:100%;border-collapse:collapse;font-size:13px;background:white}th,td{text-align:left;padding:10px 12px;border-bottom:1px solid #dfe5e5;white-space:nowrap}th{color:#49646d}.chart{width:100%;display:block;margin:20px 0;border:1px solid #e4e7e6;border-radius:12px}label{display:inline-flex;flex-direction:column;gap:5px;font-size:13px;margin-right:12px;margin-bottom:12px}input,select{font:inherit;padding:9px 12px;border:1px solid #b4c3c7;background:white;border-radius:7px;max-width:100%}input{min-width:270px}button{border:0;border-radius:7px;background:#276b70;color:white;padding:9px 15px;cursor:pointer;margin-right:8px}.layout{display:grid;grid-template-columns:320px 1fr;gap:18px}.list{max-height:740px;overflow:auto}.item{display:block;width:100%;text-align:left;background:transparent;color:#223842;border-bottom:1px solid #e2e7e7;border-radius:0;padding:13px 12px}.item.active{background:#e4f0ee}.item small{display:block;color:#677982}.answers{display:grid;grid-template-columns:1fr 1fr;gap:12px}.answer{padding:13px;border-left:4px solid #9aabc0;background:#f5f7f8;border-radius:4px}.answer.correct{border-color:#277c78}.answer.incorrect{border-color:#be5347}.answer.pending{border-color:#eac679}pre{font:12px/1.55 ui-monospace,Menlo,monospace;white-space:pre-wrap;overflow-wrap:anywhere;margin-bottom:0}.badge{font-size:12px;font-weight:600}.advice{border:1px solid #e4c1b8;background:#fff8f4;padding:14px;border-radius:7px;margin:14px 0}.advice.good{border-color:#bedcd4;background:#f2faf6}.small{font-size:13px}a{color:#1f6a78}summary{cursor:pointer;font-weight:600}.notice{padding:16px;background:#eaf0f0;border-radius:8px}footer{font-size:12px;color:#68767c;margin-top:40px}@media(max-width:800px){main{padding:25px 15px}h1{font-size:28px}.layout{grid-template-columns:1fr}.list{max-height:230px}.cards{grid-template-columns:1fr}.answers{grid-template-columns:1fr}}
</style><main><div class="eyebrow">COMP2501 / CONTROLLED PEER-ADVICE STUDY / 2026-10-01</div>
<h1>AI 再检查一次，会更准确吗？</h1><p class="muted">无搜索的日期事实问答 · 三个模型 · 同一初始回答，六种独立复核条件</p>
<div class="cards"><div class="card"><b id="nq"></b>不同题目；以题目为重采样单位</div><div class="card"><b id="nr"></b>正式接收响应</div><div class="card"><b id="nc"></b>纳入分析的初始回答单元</div></div><p id="qualitynote" class="small muted"></p>
<p class="notice">这是受控错误建议实验，不是日常错误率排行榜。正确目标建议也不是外部证据。拒答与错误分别统计；原始材料、提示、判分和质量排除均可追溯。来源和内容由 Codex 检查，尚无独立人工复核。</p>
<h2>准确率、错误与拒答</h2><img class="chart" alt="各模型与实验条件的正确、错误、拒答比例" src="__ACCURACY__">
<div class="tablewrap"><table><thead><tr><th>条件</th><th>正确／全部</th><th>错误</th><th>拒答</th><th>初始正确→错误</th><th>初始错误→正确</th></tr></thead><tbody id="resultrows"></tbody></table></div><h2>两个预先确定的主比较</h2><p class="small muted">只在初始正确的单元中计算改错率。区间以题目为聚类单位，保留同题的模型和重复相关性。边际区间不构成多重检验校正。</p><img class="chart" alt="两条主比较的效应与题目聚类置信区间" src="__EFFECTS__">
<h2>逐题查看真实回答</h2><p class="small muted">选择题目可对照初始答案、错误同伴建议、正确目标建议及六条独立复核输出。红色建议是实验用错误材料。C2 与 C3 是平行分支，C3 没有读到 C2 的输出。</p>
<label>接收模型<select id="model"><option value="">全部</option><option>deepseek</option><option>kimi</option><option>minimax</option></select></label>
<label>案例筛选<select id="kind"><option value="">全部案例</option><option value="harm">C2 把正确改成错误</option><option value="rescue">初始正确：C2 答错、C3 答对</option><option value="checkharm">C2 答对、C3 答错</option><option value="abstainloss">初始正确：C3 转为拒答</option><option value="repair">C4 纠正初始错误</option><option value="baselinewrong">初始答错</option></select></label>
<label>搜索<input id="query" placeholder="题号或题目关键词"></label><p id="count" class="small muted"></p>
<div class="layout"><div class="panel list" id="list"></div><div class="panel" id="detail"></div></div>
<footer>仅展示本轮已保存的响应；页面不调用任何模型或外部服务。重新计算方式见项目的 REPRODUCE.md 和研究报告。</footer></main>
<script id="data" type="application/json">__DATA__</script><script>
const data=JSON.parse(document.getElementById('data').textContent);const labels={baseline:'初始回答',C0:'C0 中性复核',C1:'C1 错误日期',C2:'C2 错误日期＋解释',C3:'C3 相同错误建议＋核验',C4:'C4 正确目标＋解释',C5:'C5 相同正确建议＋核验'};const status={correct:'正确',incorrect:'错误',abstain:'拒答',pending:'待复核'};
const el=id=>document.getElementById(id);const esc=s=>String(s??'').replace(/[&<>"']/g,x=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[x]));
el('nq').textContent=data.summary.questions;el('nr').textContent=(data.summary.output_quality?.raw_responses??data.summary.responses).toLocaleString();el('nc').textContent=data.summary.complete_cells.toLocaleString();let selected=null;if(data.summary.output_quality){const q=data.summary.output_quality;el('qualitynote').textContent=`正文不可判分 ${q.unscorable_outputs.length} 条；按公开的采集后质量修订，移出 ${q.excluded_cells.length} 套配对单元，主分析使用 ${q.analysis_responses.toLocaleString()} 条响应。${data.summary.collection?`实际 API 尝试 ${data.summary.collection.raw_api_attempts.toLocaleString()} 次，含已保留的传输失败与补跑。`:''}原始响应全部保留，另报告敏感性分析。`;}el('resultrows').innerHTML=Object.entries(labels).map(([k,label])=>{const t=data.summary.tables.pooled[k];return `<tr><td>${label}</td><td>${t.correct||0}/${t.n} (${t.accuracy_pct.toFixed(1)}%)</td><td>${t.incorrect||0}</td><td>${t.abstain||0}</td><td>${t.correct_to_incorrect}/${t.baseline_correct_n}</td><td>${t.incorrect_to_correct}/${t.baseline_incorrect_n}</td></tr>`}).join('');
function detail(c){selected=c.id;el('detail').innerHTML=`<div class="eyebrow">${esc(c.qid)} · ${esc(c.model)} · 重复 ${c.repeat+1}</div><h3>${esc(c.question)}</h3><p><b>参考答案：${esc(c.gold)}</b> · <a href="${esc(c.source)}" target="_blank" rel="noopener">核对来源</a></p><p class="small muted">建议生成模型：${esc(c.generator)}</p><details class="advice"><summary>错误同伴材料：${esc(c.wrong.answer)}</summary><p>${esc(c.wrong.explanation)}</p></details><details class="advice good"><summary>正确目标材料：${esc(c.right.answer)}</summary><p>${esc(c.right.explanation)}</p></details><div class="answers">${Object.entries(labels).map(([k,label])=>{let r=c.answers[k];return `<div class="answer ${esc(r.grade)}"><b>${label}</b> <span class="badge">${status[r.grade]||esc(r.grade)}</span><pre>${esc(r.text)}</pre><div class="small muted">${esc(r.task_id)}</div></div>`}).join('')}</div>`;document.querySelectorAll('.item').forEach(x=>x.classList.toggle('active',x.dataset.id===selected))}
function render(){let model=el('model').value,kind=el('kind').value,q=el('query').value.toLowerCase();let items=data.cells.filter(c=>{let a=c.answers;if(model&&c.model!==model)return false;if(q&&!`${c.qid} ${c.question}`.toLowerCase().includes(q))return false;if(kind==='harm'&&!(a.baseline.grade==='correct'&&a.C2.grade==='incorrect'))return false;if(kind==='rescue'&&!(a.baseline.grade==='correct'&&a.C2.grade==='incorrect'&&a.C3.grade==='correct'))return false;if(kind==='checkharm'&&!(a.C2.grade==='correct'&&a.C3.grade==='incorrect'))return false;if(kind==='abstainloss'&&!(a.baseline.grade==='correct'&&a.C3.grade==='abstain'))return false;if(kind==='repair'&&!(a.baseline.grade==='incorrect'&&a.C4.grade==='correct'))return false;if(kind==='baselinewrong'&&a.baseline.grade!=='incorrect')return false;return true});el('count').textContent=`${items.length} 个模型–题目–重复单元`;el('list').innerHTML=items.map(c=>`<button class="item" data-id="${esc(c.id)}">${esc(c.qid)} · ${esc(c.model)} · ${c.repeat+1}<small>${esc(c.question)}</small></button>`).join('');el('list').querySelectorAll('button').forEach(b=>b.onclick=()=>detail(items.find(c=>c.id===b.dataset.id)));if(items.length)detail(items.find(c=>c.id===selected)||items[0]);else el('detail').textContent='没有匹配案例。'}['model','kind','query'].forEach(id=>el(id).addEventListener('input',render));render();
</script></html>'''
    if all(q['split']=='dev' for q in questions):page=page.replace('正式接收响应','开发轮接收响应')
    page=page.replace('__DATA__',data).replace('__ACCURACY__',img('accuracy.png')).replace('__EFFECTS__',img('effects.png'))
    (out/'results.html').write_text(page)


def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--summary',type=Path,required=True);p.add_argument('--questions',type=Path,required=True)
    p.add_argument('--responses',type=Path,required=True);p.add_argument('--materials',type=Path,required=True)
    p.add_argument('--out',type=Path,required=True);args=p.parse_args();args.out.mkdir(parents=True,exist_ok=True)
    summary=json.loads(args.summary.read_text());plot(summary,args.out)
    dashboard(summary,read_jsonl(args.questions),read_jsonl(args.responses),json.loads((args.summary.parent/'grades.json').read_text()),json.loads(args.materials.read_text()),args.out)
    print('Saved accuracy/effects PNG+SVG and self-contained results.html')


if __name__=='__main__':main()
