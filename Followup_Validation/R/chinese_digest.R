# Plain-language summary of the completed run; all numerical processing stays in R.
source('Followup_Validation/R/common.R');library(knitr)
p<-file.path(VROOT,'reports');e<-read.csv(file.path(p,'effects.csv'));s<-read_json(file.path(p,'summary.json'));v<-read_json(file.path(p,'validation.json'))
tab<-function(x)paste(capture.output(print(knitr::kable(x,format='pipe',row.names=FALSE))),collapse='\n')
effect_row<-function(domain,comp,metric='error')e[e$domain==domain&e$provider=='pooled'&e$comparison==comp&e$metric==metric,]
f<-effect_row('facts','N2-N1');m<-effect_row('mathematics','N2-N1');stopifnot(nrow(f)==1,nrow(m)==1)
row<-function(z,name)data.frame(题目=name,有效题数=z$questions,有效配对=z$n,自行复核错误=sprintf('%d/%d = %.2f%%',z$before_n,z$n,z$before_pct),跨模型复核错误=sprintf('%d/%d = %.2f%%',z$after_n,z$n,z$after_pct),变化百分点=sprintf('%+.2f',z$difference_pp),调整后区间=sprintf('[%.2f, %.2f]',z$familywise_low,z$familywise_high),check.names=FALSE)
conclusion<-function(z){if(z$familywise_high<0)'本轮数据支持：在这批题目上，跨模型复核比自行复核少产生错误回答。'else if(z$familywise_low>0)'本轮数据支持：在这批题目上，跨模型复核比自行复核产生更多错误回答。'else'区间仍包含零，尚不能确认跨模型复核具有稳定的净收益；不能只根据点估计宣称有效。'}
w<-subset(e,provider=='pooled'&domain=='facts'&metric=='error'&comparison%in%c('W1-W0','W2-W1','W2-W0'))
namesw<-c('W1-W0'='核验提示（无额外弃答提醒） − 普通复核','W2-W1'='有额外弃答提醒 − 无额外弃答提醒','W2-W0'='原完整核验提示 − 普通复核')
wt<-data.frame(比较=unname(namesw[w$comparison]),有效配对=w$n,错误率变化百分点=sprintf('%+.2f',w$difference_pp),区间95=sprintf('[%.2f, %.2f]',w$ci_low,w$ci_high),check.names=FALSE)
counts<-do.call(rbind,lapply(c('facts','mathematics'),function(domain){z<-e[e$domain==domain&e$provider=='pooled'&e$comparison=='N2-N1',];data.frame(题型=if(domain=='facts')'事实题'else'数学题',指标=unname(c(error='错误',correct='正确',abstain='明确弃答')[z$metric]),分母=z$n,自行复核=z$before_n,跨模型复核=z$after_n,check.names=FALSE)}))
ba<-read.csv(file.path(VROOT,'baseline_review/codex_annotations.csv'))
rp<-read.csv(file.path(p,'reasoning_paired_sensitivity.csv'))
reason<-paste('Kimi对432条完整数学复核回答做了隐藏模型与组别标签的理由评审。Codex随后逐读全部28条被标记回答和固定随机抽取的24条“理由有效”回答，发现8条标签有分歧：评审AI也会把正确证明判错，或漏掉错误推导。原标签保留，另列修正敏感性。',
 '下面只比较同一批206个完整配对。部分Codex复核后，错误理由由13条降至8条，差−2.43个百分点，95%区间[−5.76,+0.47]，仍包含零。其余380条标签未逐条独立复核，不能把这些比例当作已核实的推理错误率，更不能仅凭AI评审宣称逻辑严密性稳定提升。',
 tab(subset(rp,label=='incorrect')),'评审原文、分歧理由和R验算见[理由评审复核](../review/codex_review_notes.md)。',sep='\n\n')
fs<-read.csv(file.path(p,'format_sensitivity_effects.csv'));fprimary<-subset(fs,comparison=='N2-N1'&outcome=='incorrect')
fm<-subset(e,domain=='facts'&provider!='pooled'&comparison=='N2-N1'&metric=='error')
directm<-effect_row('mathematics','N2-N0')
txt<-c('# 补测结果：交叉检查之后，我们能更信任 AI 吗？','',
 '作者：**LINYUNIAN、PAN ZHENGYU**。本页对应本次补测；旧实验、旧评分和旧PPT/PDF保留为此前版本。完整方法及统计见[英文报告](report.md)。','',
 '## 这次实际做了什么','',
 '100道此前研究过的事实题扩大复测，另加41道本项目未用过的CHAMP数学题。三个模型各答两次；同一道题先独立作答，再分别做自行复核和跨模型复核。跨模型时接收者和建议者始终不同，两次重复轮换建议者，因此每个接收模型都见到另外两种模型。','',
 '另在固定36道事实题上，保持初答和错误建议完全相同，只比较普通复核、去掉额外弃答提醒的核验提示、原带提醒的核验提示。各组仍共享基础的“不会时可以说不知道”权限。','',
 sprintf('计划4,032个输出，实际记录%d次HTTP尝试，涉及%d个不同任务（含传输失败记录）。尝试调用、收到完整回答和能够判分是不同概念。接口失败、截断或无法判分的输出单列，不算“主动弃答”。',s$http_attempts,s$returned_tasks),'',
 '## 1. 不同模型交叉检查，是否比自行复核更好？','',tab(rbind(row(f,'事实题'),row(m,'数学题'))),'',
 paste('**事实题：**',conclusion(f)),paste('**数学题：**',conclusion(m)),'',
 '事实题平均值掩盖了模型差异：本轮DeepSeek和Kimi接收建议后错误增加，MiniMax减少。这是本题集上的描述性结果，不是普遍模型排名。','',tab(fm[,c('provider','n','before_pct','after_pct','difference_pp')]),'',
 sprintf('若与“只答一次”相比，可用数学配对上错误率从 %.2f%% 降到 %.2f%%（%d配对，差%+.2f个百分点，95%%区间[%.2f, %.2f]）。这是辅助比较，不能与上面的“相比自行复核”混为同一结论。',directm$before_pct,directm$after_pct,directm$n,directm$difference_pp,directm$ci_low,directm$ci_high),'',
 '负数表示错误减少，正数表示错误增加。两类题的主要比较同时报告97.5%区间，以处理两项主要比较；不是把成百上千条模型回复视作相互独立的题目。','',
 '![主要错误率比较](primary_error_rates.png)','',
 '按你的定义，正确回答和明确弃答都不算错误。但这不等于把弃答叫作答对。主指标评的是最终答案，不保证解释中的每一句话也正确；数学理由另行复核。下面分开保留三种结局：','',tab(counts),'',
 '## 2. 数学部分是否测到了真实的推理错误？','',
 sprintf('有。Codex逐读了初答中全部%d条可判分错误回答；它们都包含实际的错误推导或逻辑矛盾，没有一条被归为“理由完全正确、只是最后答案栏写错”。这些回答涉及11道题，重复回答并非独立数学问题。',nrow(ba)),'',
 '例如：相同饼干被当成不同饼干计数；圆环排列漏掉整体旋转的两种情况；约瑟夫环把已经从1编号的公式又加了1。原文、判断理由及R验算都保存在[初答复核](../baseline_review/README.md)。这些例子证明题目包含真实推理失误；是否被交叉检查修好，要看后续配对结果，不能把两者等同。','',reason,'',
 '## 3. 不额外强调弃答，核验还有没有帮助？','',tab(wt),'',
 '第一行检验去掉额外弃答提醒后，核验提示整体是否改变错误率；第二行才是额外那句提醒的增量效果。第三行与旧版完整核验提示对应。三项都属于辅助比较，不能据此断言某种心理机制。','',
 '本轮没有确认“去掉额外弃答提醒的核验”本身能稳定降错；加回提醒后，错误减少、弃答增加，同时正确回答也减少。弃答可以有价值，但这里的降错不能全部解释为更强的事实核验能力。','',
 '![同样错误建议下的提示对照](abstention_ablation.png)','',
 '## 格式问题会不会改变结论？','',
 '另逐读了64条完整返回但无法自动判分的回答：27条可读为正确、22条错误、2条明确弃答、13条仍有冲突或没有明确答案。主评分保留；将可明确解释的答案纳入后，主要差异如下（事后敏感性分析）：','',tab(fprimary[,c('domain','n','before','after','difference_pp','ci975_low','ci975_high')]),'',
 '事实题仍接近零；数学方向仍偏向改善，但调整后区间仍触及零。没有把未知答案、截断回答或未采集的分支猜出来。','',
 '## 一条能说明问题的真实案例','',
 '1980个数字2组成的整数除以1982，余数应为0。Kimi自行复核仍答0；MiniMax给出错误的中国剩余定理推导、答220。Kimi收到它的建议后认可该错误步骤，改答220。R逐位取余独立验证了0。另有多项式系数从−120纠正到120的成功例子，两种方向都保留在[案例与同伴质量诊断](peer_diagnostics.md)。','',
 '## 交付与限制','',
 '- 所有采集、清洗、评分、统计和绘图使用R；原始响应、失败记录和冻结规则公开。没有因结果不理想而挑选题目或补跑答案。',
 '- 事实题是旧题池上的新调用，不是全新事实题验证。公开数学题也可能出现在模型训练材料中。',
 '- 数学题共享部分结构，不能由41道题推断所有逻辑任务；没有增加“同一模型独立回答两次”的对照，因此不能单独分离模型多样性与多一个独立答案的作用。',
 '- 数学主要比较只有199/246个可用配对，覆盖39/41题。L形砖铺排题与圆环三数乘积题没有完整配对；这两题本身包含真实初答错误。缺失并非可以忽略，最保守范围允许数学总体方向反转。',
 '- 错误率降低不自动等于得到更多正确答案，也不等于可以完全信任AI。实际人类信任、思考或工作表现没有在本实验中测量。',
 '- AI建议是模拟交互中错误判断与理由的材料；实际提示仍把它标成另一AI的建议，未直接比较真人来源标签。','',
 sprintf('本次及此前授权内工作的已知付费保守估价合计 **¥%.2f**，未扩展¥100预算；不是供应商账单。HKU接口的令牌另列，现金价格未确认。',v$known_paid_estimate_cny),'',
 '复算入口、缺失输出上下界、各接收模型方向、同一分母诊断和理由复核范围均见[完整报告](report.md)。')
writeLines(txt,file.path(p,'结果说明_中文.md'))
