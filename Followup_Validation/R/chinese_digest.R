# Plain-language summary of the completed run; all numerical processing stays in R.
source('Followup_Validation/R/common.R');library(knitr)
p<-file.path(VROOT,'reports');e<-read.csv(file.path(p,'effects.csv'));s<-read_json(file.path(p,'summary.json'));v<-read_json(file.path(p,'validation.json'))
tab<-function(x)paste(capture.output(print(knitr::kable(x,format='pipe',row.names=FALSE))),collapse='\n')
effect_row<-function(domain,comp,metric='error')e[e$domain==domain&e$provider=='pooled'&e$comparison==comp&e$metric==metric,]
f<-effect_row('facts','N2-N1');m<-effect_row('mathematics','N2-N1');stopifnot(nrow(f)==1,nrow(m)==1)
row<-function(z,name)data.frame(题目=name,有效配对=z$n,自行复核错误=sprintf('%d/%d = %.2f%%',z$before_n,z$n,z$before_pct),跨模型复核错误=sprintf('%d/%d = %.2f%%',z$after_n,z$n,z$after_pct),变化百分点=sprintf('%+.2f',z$difference_pp),调整后区间=sprintf('[%.2f, %.2f]',z$familywise_low,z$familywise_high),check.names=FALSE)
conclusion<-function(z){if(z$familywise_high<0)'本轮数据支持：在这批题目上，跨模型复核比自行复核少产生错误回答。'else if(z$familywise_low>0)'本轮数据支持：在这批题目上，跨模型复核比自行复核产生更多错误回答。'else'区间仍包含零，尚不能确认跨模型复核具有稳定的净收益；不能只根据点估计宣称有效。'}
w<-subset(e,provider=='pooled'&domain=='facts'&metric=='error'&comparison%in%c('W1-W0','W2-W1','W2-W0'))
namesw<-c('W1-W0'='核验提示（无额外弃答提醒） − 普通复核','W2-W1'='有额外弃答提醒 − 无额外弃答提醒','W2-W0'='原完整核验提示 − 普通复核')
wt<-data.frame(比较=unname(namesw[w$comparison]),有效配对=w$n,错误率变化百分点=sprintf('%+.2f',w$difference_pp),区间95=sprintf('[%.2f, %.2f]',w$ci_low,w$ci_high),check.names=FALSE)
counts<-do.call(rbind,lapply(c('facts','mathematics'),function(domain){z<-e[e$domain==domain&e$provider=='pooled'&e$comparison=='N2-N1',];data.frame(题型=if(domain=='facts')'事实题'else'数学题',指标=unname(c(error='错误',correct='正确',abstain='明确弃答')[z$metric]),分母=z$n,自行复核=z$before_n,跨模型复核=z$after_n,check.names=FALSE)}))
ba<-read.csv(file.path(VROOT,'baseline_review/codex_annotations.csv'))
reason<-if(file.exists(file.path(p,'reasoning_summary.csv')))paste('另有隐藏模型和组别的AI理由复核。下表中的标签来自Kimi，属于辅助证据，不是人工或形式化证明。缺少关键论证与明确推理错误分开记录。',tab(read.csv(file.path(p,'reasoning_summary.csv'))),sep='\n\n')else'理由复核尚无可用结果，不能据此声称推理严密性提高。'
txt<-c('# 补测结果：交叉检查之后，我们能更信任 AI 吗？','',
 '作者：**LINYUNIAN、PAN ZHENGYU**。本页对应本次补测；旧实验、旧评分和旧PPT/PDF保留为此前版本。完整方法及统计见[英文报告](report.md)。','',
 '## 这次实际做了什么','',
 '100道此前研究过的事实题扩大复测，另加41道本项目未用过的CHAMP数学题。三个模型各答两次；同一道题先独立作答，再分别做自行复核和跨模型复核。跨模型时接收者和建议者始终不同，两次重复轮换建议者，因此每个接收模型都见到另外两种模型。','',
 '另在固定36道事实题上，保持初答和错误建议完全相同，只比较普通复核、去掉额外弃答提醒的核验提示、原带提醒的核验提示。各组仍共享基础的“不会时可以说不知道”权限。','',
 sprintf('计划4,032个输出，实际记录%d次HTTP尝试、%d个不同任务的返回。接口失败、截断或无法判分的输出单列，不算“主动弃答”。',s$http_attempts,s$returned_tasks),'',
 '## 1. 不同模型交叉检查，是否比自行复核更好？','',tab(rbind(row(f,'事实题'),row(m,'数学题'))),'',
 paste('**事实题：**',conclusion(f)),paste('**数学题：**',conclusion(m)),'',
 '负数表示错误减少，正数表示错误增加。两类题的主要比较同时报告97.5%区间，以处理两项主要比较；不是把成百上千条模型回复视作相互独立的题目。','',
 '![主要错误率比较](primary_error_rates.png)','',
 '按你的定义，正确回答和明确弃答都不算错误。但这不等于把弃答叫作答对。主指标评的是最终答案，不保证解释中的每一句话也正确；数学理由另行复核。下面分开保留三种结局：','',tab(counts),'',
 '## 2. 数学部分是否测到了真实的推理错误？','',
 sprintf('有。Codex逐读了初答中全部%d条可判分错误回答；它们都包含实际的错误推导或逻辑矛盾，没有一条被归为“理由完全正确、只是最后答案栏写错”。这些回答涉及11道题，重复回答并非独立数学问题。',nrow(ba)),'',
 '例如：相同饼干被当成不同饼干计数；圆环排列漏掉整体旋转的两种情况；约瑟夫环把已经从1编号的公式又加了1。原文、判断理由及R验算都保存在[初答复核](../baseline_review/README.md)。这些例子证明题目包含真实推理失误；是否被交叉检查修好，要看后续配对结果，不能把两者等同。','',reason,'',
 '## 3. 不额外强调弃答，核验还有没有帮助？','',tab(wt),'',
 '第一行检验去掉额外弃答提醒后，核验提示整体是否改变错误率；第二行才是额外那句提醒的增量效果。第三行与旧版完整核验提示对应。三项都属于辅助比较，不能据此断言某种心理机制。','',
 '![同样错误建议下的提示对照](abstention_ablation.png)','',
 '## 交付与限制','',
 '- 所有采集、清洗、评分、统计和绘图使用R；原始响应、失败记录和冻结规则公开。没有因结果不理想而挑选题目或补跑答案。',
 '- 事实题是旧题池上的新调用，不是全新事实题验证。公开数学题也可能出现在模型训练材料中。',
 '- 数学题共享部分结构，不能由41道题推断所有逻辑任务；没有增加“同一模型独立回答两次”的对照，因此不能单独分离模型多样性与多一个独立答案的作用。',
 '- 错误率降低不自动等于得到更多正确答案，也不等于可以完全信任AI。实际人类信任、思考或工作表现没有在本实验中测量。',
 '- AI建议是模拟交互中错误判断与理由的材料；实际提示仍把它标成另一AI的建议，未直接比较真人来源标签。','',
 sprintf('本次及此前授权内工作的已知付费保守估价合计 **¥%.2f**，未扩展¥100预算；不是供应商账单。HKU接口的令牌另列，现金价格未确认。',v$known_paid_estimate_cny),'',
 '复算入口、缺失输出上下界、各接收模型方向、同一分母诊断和理由复核范围均见[完整报告](report.md)。')
writeLines(txt,file.path(p,'结果说明_中文.md'))
