# 关键案例来源与评分复核（Codex，2026-10-01）

这是查看聚合结果后的 AI 复核，不是独立人工复核，不修改冻结题库、原始输出或主评分。完整提取覆盖 51 题、68 单元；本次重新联网核查集中于下列来源，**不代表51题的全部来源已经重新验证**。C4/C5的65个差异单元原文均已阅读；解释的其他事实未全量查证，不能统计“解释错误率”。

## 三次正确改错

| 单元 | 初答 | C2错误解释组 | C3结构化组 | 来源核查 |
|---|---|---|---|---|
| SV0013:deepseek:r1 | 2023 | 2024 | 2023 | City of Monash 官方页面支持2023 |
| SV3488:deepseek:r0 | 2003 | 2002 | 2003 | Québec官方授勋名录支持2003 |
| SV3693:minimax:r0 | 1949 | 1950 | 1949 | Museum Collection历史资料支持1949；本次未取得乐团官方档案 |

C2、C3是各自从初答出发的平行分支，不能叙述成C3在看到C2输出后“救回来”。这三例是全部观察到的C2初答正确改错事件，不是总体错误的全部形式。

- SV0013：[City of Monash](https://www.monash.vic.gov.au/About-Us/Council/Committees/Museum-of-Australian-Photography-Committee-of-Management) 原文节选：“MGA rebranded to MAPh on Sunday 19 March 2023.” 支持题目要求的年份。
- SV3488：[Ordre national du Québec](https://www.ordre-national.gouv.qc.ca/membres/membre.asp?id=1693) 原文：“Chevalier (2003)”。C2却把2002归因于官方名录。实验没有搜索工具，这只是模型生成的来源声称，不能写成它真的查过名录。
- SV3693：[Museum Collection](https://dc.mus-col.com/en/the-authors/22659/) 将第二次Red Banner及正式名称关联于1949年2月7日；这是博物馆历史资料，证据等级不同于上两项当事机构记录。C1答案字段为1949，解释却给1948；C3答案匹配也不能证明整段解释可靠。推荐组员继续查乐团档案，不把背景叙述当已验证事实。

## 正确建议：48次失去纠错与17次新增纠错

初答错误的322个单元中，C4/C5都正确28个；C4正确而C5未正确48个（24错误、24弃答）；C4未正确而C5正确17个（13原为错误、4原为弃答）。因此C4为76次纠错、C5为45次，净差−31。不能把净差写成“恰好31个案例受损”，也不能省去17次收益。

回答中的“没有证据”有时伴随弃答，有时伴随坚持错误日期；正确答案中也有“看起来合理所以接受”的表述。这里只描述可见文本，不从自述推断模型内部机制或真实检索行为。

### SV1246：Dogra Art Museum

C4给1954-04-18，C5坚持1957-04-18。调查未发现足以支持1957的机构证据。[印度国家手稿任务官方刊物](https://www.namami.gov.in/sites/default/files/Kriti%20Rakshana-April13-March14_0.pdf) 原文节选：“This Museum was established on 18th April 1954”。[IGNCA保存的博物馆资料](https://ignca.gov.in/Asi_data/27994.pdf)也将开馆展览放在1954年4月。当前证据支持保留基准日期；不因模型重复1957就修改答案。

### SV3691：Arch Linux——题意歧义

问题原文：“In which month and year did Arch Linux installation images start including installation scripts by default?” 冻结答案April2021。

[Arch官方2012年公告](https://archlinux.org/news/install-media-20120715-released/)写道：“some simple install scripts are provided to aid in the installation process.” 公告日期2012-07-22、镜像版本2012.07.15；两者都属于2012年7月。[2021年公告](https://archlinux.org/news/installation-medium-with-installer/)写道：“The installation medium now provides a guided installer.” 日期2021-04-01。

题目未明确guided installer/archinstall，存在把两种事件混为一谈的风险。Kimi的C5确实指出两者不同，但给的是2012年8月，也不能据此直接判其正确。事后按整题排除做敏感性分析，既不改题意，也不悄悄把C5升级为正确。

### SV3593：Wood River——来源冲突

[Baptist General State Convention of Illinois](https://bgscil.org/history/)将组织成立记为1838年4月27日，支持冻结答案1838；[Illinois House Resolution HR1095](https://ilga.gov/documents/legislation/95/HR/PDF/09500HR1095.pdf)第14–17行记为1839。两个机构来源不一致，尚未解决事件定义或档案差异。保留来源冲突，按整题排除作事后检验，不武断改成1839。

### SV1199:minimax:r0:C5——答案字段与解释冲突

原始JSON包含 `answer="1975"`、`abstain=false`，解释末句却是“The uncertainty warrants abstention.” 冻结评分按答案字段判correct。本次提出两种**事后**检验：仅把该C5算abstain；或整题排除。均保留原判和原始文本；这条AI发现不等于已完成独立裁决。

## 事后敏感性结果

由 `R/prepare_key_review.R` 生成 `posthoc_effects.csv`。按整题聚类bootstrap5000次，沿用R种子25011001。原七项敏感性结果另存main_r，不在本轮覆盖。

| 处理 | C5−C4纠错差（百分点） | 95%题目聚类区间 | 初答错误分母 |
|---|---:|---|---:|
| 原主分析 | −9.63 | [−14.38, −5.25] | 322 |
| 排除Wood River | −9.49 | [−14.19, −5.03] | 316 |
| 排除Arch Linux | −9.12 | [−13.68, −4.83] | 318 |
| 同时排除两题 | −8.97 | [−13.76, −4.53] | 312 |
| SV1199冲突回答按弃答 | −9.94 | [−14.72, −5.57] | 322 |
| 整题排除SV1199 | −9.69 | [−14.38, −5.04] | 320 |

这些版本中纠错损失方向未改变，不能由此宣称所有标签均无问题。来源排除两题不改变RQ1/RQ2点估计；SV1199整题排除会改变RQ1分母及点估计，详见CSV。事后分析不能冒充预先承诺的分析。

下一步是让组员先独立填写 `reviewer/`，再核对本文件及协调者映射。此文件不应作为盲评者的首读材料。
