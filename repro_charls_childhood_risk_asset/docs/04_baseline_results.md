## 阶段 4：基准回归复现（表 2）（完成于 2026-02-27）

## 1. 执行脚本与产物

- 执行脚本：`src/03_baseline_models.R`
- 结果表：
  - `output/tables/table2_reproduced.csv`（核心系数）
  - `output/tables/table2_reproduced_full.csv`（全部回归系数）
  - `output/tables/table2_model_diagnostics.csv`（拟合指标）
  - `output/tables/table2_paper_compare.csv`（与论文系数对照）
  - `output/tables/table2_ols_sensitivity.csv`（OLS 偏差排查）
- 日志：`logs/baseline_models_summary.log`

## 2. 模型设定（与论文口径对齐）

- 模型 (1)：`Risk_Dummy ~ childhealth`（Logit）
- 模型 (2)：`Risk_Dummy ~ childhealth + age + gender + hukou + marriage`（Logit）
- 模型 (3)：`Risk_Ratio ~ childhealth`（OLS）
- 模型 (4)：`Risk_Ratio ~ childhealth + age + gender + hukou + marriage`（OLS）
- 标准误：全部使用 `HC1` 稳健标准误。

## 3. 复现结果（childhealth）

- (1) `Risk_Dummy` Logit：`-0.0493*`（SE `0.0277`，`p=0.0750`，`N=14687`）
- (2) `Risk_Dummy` Logit + controls：`-0.0304`（SE `0.0283`，`p=0.2832`，`N=14686`）
- (3) `Risk_Ratio` OLS：`-0.0011`（SE `0.0016`，`p=0.4805`，`N=14687`）
- (4) `Risk_Ratio` OLS + controls：`-0.0003`（SE `0.0016`，`p=0.8628`，`N=14686`）

## 4. 与论文表 2 对照（childhealth）

论文报告（参考值）：
- (1) `-0.045`
- (2) `-0.032`
- (3) `-0.003`
- (4) `-0.002`

本次复现差值（复现值 - 论文值）：
- (1) `-0.0043`
- (2) `+0.0016`
- (3) `+0.0019`
- (4) `+0.0017`

结论：
- Logit 两列方向和量级基本接近论文；
- OLS 两列方向一致但绝对值偏小且不显著，未复现论文显著性。

## 5. 影响复现结果的问题与已探索方案

问题：`Risk_Ratio` 回归显著性偏弱，影响表 2 完整复现。

已探索（`table2_ols_sensitivity.csv`）：
- 限制样本 `financial_asset_total > 0`；
- 仅保留 `Risk_Ratio > 0` 子样本；
- 对 `Risk_Ratio` 进行 99% winsor；
- 使用更窄分母口径（现金+存款+债券+股票+基金+借出款）。

结果：
- `childhealth` 系数均未达到统计显著，且量级仍显著小于论文 OLS 列。

判断：
- 当前差异更可能来自上游口径（资产定义、缺失处理、样本筛选）而非单一回归设定。

## 6. 阶段 4 验收结论

- 已满足阶段 4 要求：
  - 代码：`src/03_baseline_models.R`
  - 输出：`output/tables/table2_reproduced.*`
  - 文档：`docs/04_baseline_results.md`
- 阶段 4 状态：完成，可进入阶段 5（内生性处理复现，表 3）。
