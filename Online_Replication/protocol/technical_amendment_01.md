# 正式网络请求前的本地采集器修正

首次启动时，R curl异步函数的第二个位置参数被误当作handle，实际是data，触发本地参数类型检查错误。错误发生于第一次multi_add注册时、multi_run之前；没有执行网络传输，没有产生模型答案。

保留原冻结文件`freeze_v1_before_local_setup_fix.json`和`probe/local_setup_no_network_attempt.jsonl`。将handle改成具名参数；正式HTTP前再次验证并冻结。该修正不修改题目、提示、评分、任务顺序或预算，也不针对任何答案重试。首次误写的“attempt”日志是未发送的本地尝试，不计实际HTTP请求。
