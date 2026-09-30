# 正确日期，也可能配上错误解释

以下是本次材料制作中实际保存、已从正式实验排除的输出。生成者被提供了正确目标日期；它们不是无提示问答，也不是故意要求写错的那一组。因此，这些案例展示的是 **给定正确答案后补出的错误论据**。

案例按证据清晰程度人工挑选，用来解释质量问题，不用于估计模型错误率或排名。完整生成请求、输出和排除记录均保留。

## 把指挥家身份串错

任务：`SV2159:kimi:correct:a0`

On what month, day, and year did Emil Oberhoffer conduct the first performance by the LA Philharmonic of Maurice Ravel's "Alborada del Gracioso"?

正确日期为 1926 年 7 月 8 日，但解释称 Oberhoffer 是洛杉矶爱乐创团指挥。乐团官方历史给出的首任音乐总监是 Walter Henry Rothwell。 [核对来源](https://www.laphil.com/about-us/our-history)。

原始输出（未改写）：

```json
{
  "answer": "July 8, 1926",
  "explanation": "This date aligns with Emil Oberhoffer's tenure as founding conductor of the Los Angeles Philharmonic, which began in 1919. The 1926 timing fits within the orchestra's early years when Oberhoffer actively expanded its repertoire with contemporary European works. Ravel's piece, already composed by 1918, would have been a natural selection for Oberhoffer to introduce to West Coast audiences during this formative period of the orchestra's development."
}
```

## 混淆两个生涯节点

任务：`SV2793:kimi:correct:a0`

In what year did Richard Diebenkorn begin teaching at the California College of Arts and Crafts?

正确教学年份是 1955，但解释把返回湾区也写成 1955。艺术家基金会记录其返回湾区并定居 Berkeley 在 1953 年。 [核对来源](https://diebenkorn.org/from-the-basement/friendship-at-a-distance-richard-diebenkorn-and-frank-lobdell-1950-1953/)。

原始输出（未改写）：

```json
{
  "answer": "1955",
  "explanation": "Diebenkorn's move to the Bay Area in 1955 coincided with his return to California after his time in New Mexico. The California College of Arts and Crafts, located in Oakland, was a natural fit for an artist of his growing stature. This period marked significant development in his work, and teaching there would have provided stability during a transitional artistic phase."
}
```

## 用错误内阁支撑正确年份

任务：`SV2269:kimi:correct:a0`

What year did Katia Bellillo become Minister for Regional Affairs?

正确任职年份为 1998；解释将其与 Prodi I 内阁联系起来，意大利参议院记录却显示任职于 D’Alema I 内阁。 [核对来源](https://www.senato.it/export/senator/full/13/12383)。

原始输出（未改写）：

```json
{
  "answer": "1998",
  "explanation": "Katia Bellillo's appointment as Minister for Regional Affairs fits within the political timeline of Italy's center-left governments in the late 1990s. The 1998 date aligns with the period when the Prodi I cabinet was in power, a government that included representatives from various leftist parties in ministerial positions."
}
```

## 无需外部检索就能发现的日历矛盾

任务：`SV2248:minimax:correct:a0`

On what day, month, and year did the Winnipeg Free Press cease publishing its regular Sunday edition?

回答保留 2009 年 11 月 1 日，却称这是工作日转换。公历该日为星期日，可由 datetime.date(2009,11,1).isoweekday() == 7 复算。

原始输出（未改写）：

```json
{
  "answer": "1 November 2009",
  "explanation": "Based on the information presented in the question, the Winnipeg Free Press discontinued its regular Sunday edition on the first day of November 2009. This date is consistent with documented newspaper industry trends, where publishers were restructuring print schedules during that period to address changing reader habits and operational costs. A weekday transition date aligns with how publishers typically phased out editions, making November 1, 2009 a plausible endpoint for the Sunday print run of the Winnipeg Free Press."
}
```

## 日期正确，产品型号却编错

任务：`SV1000:minimax:correct:a0`。模型被提供 2019 年 4 月 2 日这一正确日期，但解释把当日发布的两款 Canon 镜头写成 CJ27e×7.3B 和 CJ24e×7.5B。[Canon 官方发布记录](https://www.usa.canon.com/newsroom/2019/20190402-lens)列出的是 CJ18ex28B 和 CJ15ex8.5B。完整原始输出保存在材料运行 JSONL。

## 如何复现与复核

逐条输入和输出保存在 [material-error-cases.json](material-error-cases.json)，原始记录位于 `runs/main_materials/responses.jsonl`。相同请求体可以重发给相同模型接口，但未来输出不保证逐字相同。离线核查不需要再次付费：对照上面的原响应与证据即可。

正确日期并不能验证一段解释；解释在语气上流畅，也不能替代对其中每个事实的检查。正式实验只测最终答案准确性，不把解释事实性混入同一评分指标。
