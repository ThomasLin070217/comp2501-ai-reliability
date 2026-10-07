当前推荐使用 [v18 演示稿](output/COMP2501_presentation_REVISED_MATH_2026-10-07_v18_PARTIAL_ROLLOUT_RATES.pptx)；[28 页 PDF 备份](output/COMP2501_presentation_REVISED_MATH_2026-10-07_v18_PARTIAL_ROLLOUT_RATES.pdf)。按用户澄清，红色 Error rate 柱改为“选中题接受干预、其余题保留初答”的**回顾性部分干预情景**，以 493 道可评分初答题为共同分母；不能表述为全部 493 道都实际做了该分支。对同 63 道初答错误题，初答全库 70/493 错；仅这些题自行复核后 39/493 错，交叉复核后 15/493 错。绿色仍表示该 63 题纠错率 31/63 与 55/63。对另 68 道初答正确题做提示分支、其他题不变，初答 70/493、自行复核 71/493、错误 AI 建议 70/493、模拟用户错误质疑 80/493 错。63 题是按已知初答错误回顾性选择，不能当作实际使用中自动识别错误题的策略，也不能据此声称完整题库交叉复核效果。图及安全汇总由 [R 脚本](R/render_partial_rollout_v18.R) 从私有账本复算；无新增采集或改分。v18 保留 v17 其余 23 页原样，仅第 17、19、22、23、24 页视觉变化。

上一版 [v17 演示稿](output/COMP2501_presentation_REVISED_MATH_2026-10-07_v17_MEASURED_DENOMINATORS.pptx)及其 [PDF](output/COMP2501_presentation_REVISED_MATH_2026-10-07_v17_MEASURED_DENOMINATORS.pdf) 保留。第 17 页将重复的“63 道初错题剩余错误率”换成实际测得的 488 道共同可评分题总体错误率：初答 66/488、自行复核 42/488；右侧仍为同 63 道初错题的纠错率：自行复核 31/63、交叉复核 55/63。第 23 页右侧改为同题配对结果（两者都对 30/63、仅交叉复核对 25/63、仅自行复核对 1/63、两者都错 7/63），避免与左侧纠错率重复。第 19、24 页明确指出错误建议和用户质疑仅测了 68 道选出的初答正确题；其完整题库最终错误率未测得，不能直接把这些结果除以 493。图表及安全聚合数由 [R 脚本](R/render_denominator_clarification_v17.R) 复算；本轮未新增采集或修改判分。v17 以用户最新保存的 v16 为源，仅第 17、19、23、24 页视觉发生变化，其余 24 页逐页渲染一致。

上一版 [v16 演示稿](output/COMP2501_presentation_REVISED_MATH_2026-10-07_v16_PRESENTATION_FIXES.pptx)及其 [PDF](output/COMP2501_presentation_REVISED_MATH_2026-10-07_v16_PRESENTATION_FIXES.pdf) 保留。RQ1 结论页分开显示两个分母：488 道共同可评分题的初答 66/488、 自行复核 42/488 错；另一个仅选取初答错误题的 63 道子样本为初答 63/63、自行复核 32/63、交叉复核 8/63 错。8/63 不能解释成全部 488 题的交叉复核错误率。四个研究问题原文未改，问题页字体字号统一；限制页删除 Interpretation，改为居中单栏。演示页中的方法名统一为“cross-check”，不再加“natural”。图表和安全聚合数由 [R 脚本](R/render_rq_alignment_v16.R) 生成；本轮未新增采集或修改判分。

上一版 [v15](output/COMP2501_presentation_REVISED_MATH_2026-10-07_v15_ALIGNED_RQs.pptx) 保留。其第 16 页已展示 63 道初答错误题的错误率轨迹和纠错率；第 21–23 页分别讨论四个研究问题。以下为历史记录。

四个研究问题的原文为：

1. Can double-checking reduce AI error rates?
2. Which double-checking method is most effective in practice?
3. Can an incorrect peer answer mislead an initially correct model during cross-checking?
4. Can misleading user input cause an otherwise correct model to give a wrong answer?

本次仅校正研究问题、方法解释、结论用语和讲者备注；没有新增采集或改变结果数字。以下为历史版本记录。

当前推荐使用output/COMP2501_presentation_REVISED_MATH_2026-10-07_v13.pptx，共27页。第27页为13. OPTIONAL REFLECTION，放在整份PPT最末（附录之后），有时间再讲，不纳入既有12部分主线大纲。按用户截图内容压成三点：控制错误的后果、从失败中改进验证与提问、保留人的判断与决策责任。页面以Our view表明是反思观点，不作为本次数学实验的额外结论。

新增页讲者延续末尾共同页，标注Thomas / Frost；备注含约45–60秒的中英文讲述参考，明确时间紧可跳过。先前26页的正文、数据、表情包、6张原生表格、姓名标注和讲者备注均保持用户最新保存版本。最终27页重新导入渲染，前26页像素与源完全一致；源v12不覆盖。本轮无数据处理、采集、模型调用或Git推送。以下为历史版本记录。

当前推荐使用output/COMP2501_presentation_REVISED_MATH_2026-10-07_v12.pptx，共26页。每页右下角已加入可编辑的讲者姓名，原页码单独保留。Thomas负责1–7、13–16、24页；Frost负责8–12、17–23页；25–26页Thomas / Frost共同负责。对应用户章节分配与确认见speaker_assignment_v12.md。第19页输入示例随7.4交由Frost。

本轮仅加讲者页脚。正文、数据、R图、表情包、6张原生表格和讲者备注保持一致；最终26页重新导入渲染，姓名框之外的所有像素与v11完全一致。原v11不覆盖。没有数据处理、采集、模型调用、外部发布或Git推送。以下为历史版本记录。

当前推荐使用output/COMP2501_presentation_REVISED_MATH_2026-10-07_v11.pptx，共26页。以用户最新保存的v10为基础：第22页RQ2并列展示纠错率和错误率，两图都使用同63道初答错误且M2/C1共同可评分题；self-check纠错31/63=49.21%、错误32/63=50.79%，natural cross-check纠错55/63=87.30%、错误8/63=12.70%。多纠正24题，错误率减少38.10个百分点。此处错误率只针对该初答错误子集，不代表500题总体错误率。

第23页合并RQ3/RQ4结论，保留用户已添加的两个原问题，展示同68题Self-check1/68、User error induction10/68、AI error induction0/68新错误率。两个RQ分别作答，用户诱导10次均采纳错误目标；该配对样本中用户条件错误更多。另保留额外AI批次1/70独立算术错误、两AI批次0/139错误目标采纳的限制说明，来源和质疑措辞同时变化，不能声称普遍零风险或纯来源因果效应。

删除重复的原RQ3结论页，future work24、references25、appendix26。纠错率保持绿色，错误率越高红色越深，采用既有跨图固定映射；第18页表情包、全部其他图片、6张原生表格和其余页正文保留。v10及其他版本不覆盖。R源码R/render_rq2_and_combined_induction.R；三张PNG/PDF、安全聚合值及五个源文件SHA256位于figures/rq2_combined_v11。复现：Rscript R/render_rq2_and_combined_induction.R '私有数学题库根目录' figures/rq2_combined_v11_reproduced。

最终26页重新导入渲染检查，未改页面与用户最新保存源视觉一致（末三页只顺延页码）。本轮无模型调用、数据采集、外部发布或Git推送。以下为历史版本记录，页码以对应版本为准。

当前推荐使用output/COMP2501_presentation_REVISED_MATH_2026-10-07_v10.pptx，共27页。按用户截图删除原v9第16页“Self-check corrected errors and created new ones”，第15页既有总体/纠错/新错误双图保留。在原v9第19页（新第18页）的同68题三条件并列图右侧加入用户提供的惊讶表情包，标注AI error induction 0/68 new errors。图表缩小并保留纵横比，数据、分母、颜色与已有结论不变；额外70题AI批次仍单列1/70错，不将0推广到所有AI诱导题。

后续页码顺延，四个RQ结论现为21–24，future work25、references26、appendix27。所有保留表格值、原正文、其他原图片及表情包保持一致，新增表情包原始字节直接嵌入。原v9未覆盖，没有新增数据处理、模型调用、采集或Git推送。

当前推荐使用output/COMP2501_presentation_REVISED_MATH_2026-10-07_v9.pptx，共28页。第19页以同一批68道初答正确、三分支共同可评分题并列显示Self-check、User error induction、AI error induction，新错误数分别为1/68、10/68、0/68。新增70题AI批次仍独立展示，不能混入此共同配对比较。R重建活动队列，源文件保持不变。

第20页用真实实验最终user消息的完整模板模拟玩具题输入：AI来源措辞与用户直接质疑措辞分别展示，保留共同的check/final-answer指令。错误材料本身不包含正确解法或遗漏案例提示；正确答案240和诊断单独放在输入之外。它是按真实提示措辞改编的教学示例，不是冻结题库中的实际题目或模型观察结果。

原结论汇总表改成第22–25页：四个原研究问题逐字保留，每页都有能回答该问题的R图及最终回答。RQ1为488题66→42错，RQ2为63题纠正31与55，RQ3为原69与额外70题的错误0与1/目标采纳0，RQ4为共同68题三条件比较。未将AI独立算术错误归因于采纳错误目标，也未把条件子样本推广成全500题总体cross-check收益。6个其他原生表格和所有其他图片/表情包保留，原v8不覆盖。

复现本轮图：Rscript R/render_three_conditions_and_rq.R '私有数学题库根目录' figures/rq_conclusions_v9_reproduced 。本轮四张PNG/PDF、安全聚合分子分母及输入文件SHA256位于figures/rq_conclusions_v9；不包含逐题原始材料。最终文件重新导入渲染28页，未改页面正文与原版本对应视觉一致（后3页仅顺延页码）。未新增模型调用、采集或Git推送。

当前推荐使用output/COMP2501_presentation_REVISED_MATH_2026-10-07_v8.pptx，共25页。基于v7，封面后新增第2页Presentation outline；原有1–6章编号保留，并补齐7 Results、8 Discussion、9 Conclusion、10 Future work、11 References and Q&A、12 Appendix。正文页标题与右上角章节标识使用同一编号；所有页码顺延。大纲为可编辑原生文字。

本轮仅增加大纲与编号：全部原有图片字节、7个原生表格值、正文和原页讲者备注保持一致；精确最终PPT重导入渲染25页，标题、章节标识、页码框之外的所有像素与v7对应页完全一致。原有表情包、R图和错误率色深映射保留。结果页现在为15–19，示例20、discussion21、结论22、附录25。旧版本均保留，未采集新数据或调用模型。

以下为历史版本记录；页码以其对应版本为准。

当前推荐使用output/COMP2501_presentation_REVISED_MATH_2026-10-07_v7.pptx，共24页。所有错误率柱采用跨图相同的红色色深映射：百分比越高越深；纠错柱保持绿色。第14页总体错误率也统一为红色。固定非线性锚点为0%、2%、10%、20%、60%、100%，对应#FCE8E6、#F3B7B1、#DE6B62、#C53932、#8B0000、#670000，各锚点间RGB插值；每根柱仍印实际百分比和分母。映射记录见figures/error_shades/error_color_mapping.csv。

按用户提出使用“COMP2501 数据处理”聊天生成图片，第16页复用其最新自然cross-check图（重新导出颜色与纵横比），第17页复用两批模拟AI建议图；原聊天的图、代码和数据不覆盖。数据页、discussion、结论和分母附录同步填数。自然cross-check仅针对初答错误题：同63题M2 31对32错、C1 55对8错，纠错49.21%与87.30%，多纠正24题、差38.10个百分点；不是全500题总体错误率。原AI活动队列0/69错，新增独立70题1/70错、0/70采纳错误目标；描述性总计1/139错、0/139目标采纳，新题无匹配M4条件。唯一新错误为拒绝建议后的独立算术失误。来源README为私有数学根目录analysis_ready_2026-10-07/new_collections_v3/README.md；R重核三个冻结输入哈希与全部计数，逐题账本不复制进公开包。

旧版本和用户最新v6修改保留；只另存v7。复现新增图：Rscript R/render_new_collection_error_shades.R '私有数学题库根目录' figures/error_shades/new_collections_reproduced 。原self图用R/render_selfcheck_error_shades.R及R/render_revised_math_error_shades.R，均接收根目录和输出目录两个参数。数据处理聊天原版热图按计数着色，并未放入v7。

当前推荐使用output/COMP2501_presentation_REVISED_MATH_2026-10-07_v6.pptx，共24页。按本轮颜色口径，Wrong→Correct纠错用绿色#2E9D59，Correct→Wrong新错误用红色#D64545；第14、15页纠错/改错图及第17、18页初答正确子集的错误柱已统一，第5页对应箭头及标签同步。总体错误率柱维持原配色，数字、文本、其他版式和用户已保存的v5修改保留，v5不覆盖。新版R脚本为R/render_selfcheck_transition_colors.R及R/render_revised_math_transition_colors.R；图及聚合值在figures/transition_colors/。

当前推荐使用output/COMP2501_presentation_REVISED_MATH_2026-10-07_v5.pptx，共24页。v5以用户在PowerPoint中重新保存后的v4为基础：第14页保留总体错误率图，右侧新增R绘制的纠错率32/66=48.48%和新错误引入率8/422=1.90%图，标明各自条件分母；第13页evaluation补上两个公式。总体错误率66/488→42/488、净减少4.92个百分点、相对净错误减少36.36%不变。其余22页渲染一致，原表格值及表情包保留；v1–v4均不覆盖。复现新增图：Rscript R/render_selfcheck_two_panels.R '私有数学题库根目录' figures/selfcheck_two_panels 。汇总值见data/selfcheck_two_panel_values.csv。

当前推荐使用output/COMP2501_presentation_REVISED_MATH_2026-10-07_v4.pptx，共24页。v4按用户要求把原related work表格恢复在第9页，第10页放定位图；R图加入深色X/Y轴、方向箭头和明确轴标题，移动Our study标注避免遮挡交点和引用。实际轴用于标明分类维度，不表示性能高低。后续页面整体顺延一页：真实cross-check待填页16、结论页21、分母附录24。原v1–v3保留，所有结果数值、表情包保持不变。复现新版图：Rscript R/render_related_work_map_axes.R figures/related_work_map_axes 。

当前推荐使用output/COMP2501_presentation_REVISED_MATH_2026-10-07_v3.pptx。v3将第9页related work表格替换为R绘制的双轴四象限研究定位图，并补入Du et al. (ICML 2024) Multiagent Debate。横轴是模型自身生成的信息/同伴或用户信息，纵轴是改善答案质量/研究失败模式；位置仅表示选取论文的主要侧重点，不是性能排名，不声称本研究首次覆盖此交叉领域。第22页补充引用，其余21页及所有结果图、数据表值和表情包保持一致。依据、出处和复现说明见related_work_map_notes.md；v1、v2保留。

当前推荐使用output/COMP2501_presentation_REVISED_MATH_2026-10-07_v2.pptx。v2仅统一术语和相关文字：double-checking为总称，self-checking、cross-checking为两种方式。封面改为After Double-Checking，背景第4页给出两种方式定义；数据、表格值和所有图片不变。v1保留。

# Revised mathematics presentation — 7 October 2026

本包为独立另存的23页数学演示稿；原v8及用户PPT保持不变。保留原始表情包，已完成结果使用R生成的图。未发布、未启动或干预任何采集。

## 当前展示口径

- 仅使用revised数学500题，移除事实题及旧数学轮结果。
- 正确/错误两类；明确弃答计错。技术缺失、题面歧义、无法评分不自动算模型弃答，保留排除记录。
- 覆盖数与配对分母分别呈现。M1、M2覆盖各500题；七条新增M2不增加M1/M2有效配对。
- 主结果采用原始follow-up预算，并纳入最新9条补采及活动队列替换：OPT500_430替代OPT500_299，历史原文不覆盖。
- Self-check主配对488题：66→42错；32错转对、8对转错；净减少4.92个百分点，错误纠正48.48%，相对净错误减少36.36%。
- 模拟错误AI建议与同题self-check：69对，self 1错、AI 0错、目标采纳0。
- 模拟用户质疑与同题self-check：68对，self 1错、质疑10错；增加13.24个百分点，目标采纳10。
- M1包含4条已标注的原生技术续接，不隐瞒额外预算。主图不混入后续增加预算的M2/M4技术续接。

## 与最新完整数据库的区别

最新数据库另有混合预算补齐视图，含3条恢复的M2及1条恢复的M4。该视图的M1/M2配对为491题：68→43错（减少5.09个百分点）；M3/M4共同可评分69题：0错与10错。它与主图的分母、预算不同，不能交叉相减。具体记录见私有题库analysis_ready_2026-10-07/supplemented_v2/README.md。主PPT讲者备注保留两种视图的来源和限制。

## 真实cross-check结果待填（第15、20、23页）

当前只在70道MiniMax初答错误的题上采集独立DeepSeek B1，再由MiniMax从原始会话分叉C1，读取实际完整可见B1。等待最终语义评分和配对账本；图上空白不是0。

填图时先匹配M2/C1共同有效题ID，报告N、各自错转对数、纠错比例和配对差；另报B1正确子集的错误消除比例，并保留该子集分母。此错误子集设计不能估计全部500题的自然cross-check净错误率或正确题改错风险；不要与66/488直接相减。

M3为研究者构造的错误建议，不能称为DeepSeek真实错答。M4为初答之后的脚本用户质疑，不是真人实验或首次提问错误前提。M3/M4来源与措辞共同变化，不能单独归因于人类/AI标签。

## 图表复现

无需安装额外R包：

```sh
Rscript R/render_revised_math.R '/Users/thomaslin/Documents/HKU/Year2 Sem1 上海/COMP2501/Project/Math_Benchmark_500_Private_2026-10-06' figures
```

输入为私有版本化评分账本；输出仅安全聚合CSV和五张PNG。脚本含本轮计数断言，后续修改结果时应同步核对版本和断言。图表以PNG嵌入，文本和表格为可编辑PPT对象。

## 检查

23页及讲者备注齐全，结构与布局检查通过（无警告）；最终PPT重新导入渲染并逐页复核。第3、7页表情包原始图片字节哈希一致。R重新计算各图数值。未在原生Microsoft PowerPoint中执行检查。
