# Official price check during collection

Checked 2026-10-03. The collector retains its frozen conservative guard of CNY20 per million input tokens and CNY50 per million output tokens for paid providers. It does not spend up to a new budget after this check.

- [DeepSeek official CNY price page](https://api-docs.deepseek.com/zh-cn/quick_start/pricing/) lists V4 Pro at CNY9 input (cache miss) and CNY27 output per million tokens at peak, with lower off-peak rates. The frozen guard exceeds those peak rates.
- [Moonshot official chat price page](https://platform.moonshot.cn/docs/pricing/chat) lists `kimi-k2.6` at CNY6.50 input (cache miss) and CNY27 output per million tokens. The frozen guard exceeds these rates. The public HTML was read directly after the web reader timed out.

Cache discounts and lower time-of-day rates are not used to lower the existing reported cost guard or to expand the planned sample. These observations support the conservative token estimate but are not account invoices. HKU MiniMax quota cash pricing is still unknown and its tokens remain separate.
