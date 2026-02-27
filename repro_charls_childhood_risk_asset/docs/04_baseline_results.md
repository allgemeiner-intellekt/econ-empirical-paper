## 阶段 4：基准回归复现（表 2）（完成于 2026-02-27，已做增强复核）

## 1. 执行脚本与产物

- 主脚本：`src/03_baseline_models.R`
- 增强复核脚本：`src/03a_baseline_ols_grid_search.R`
- 结果表：
  - `output/tables/table2_reproduced.csv`
  - `output/tables/table2_reproduced_full.csv`
  - `output/tables/table2_model_diagnostics.csv`
  - `output/tables/table2_paper_compare.csv`
  - `output/tables/table2_ols_sensitivity.csv`
  - `output/tables/table2_ols_grid_search.csv`
  - `output/tables/table2_ols_grid_top10.csv`
- 日志：
  - `logs/baseline_models_summary.log`
  - `logs/baseline_ols_grid_search.log`

## 2. 基准模型设定（与论文表 2 对齐）

- 模型 (1)：`Risk_Dummy ~ childhealth`（Logit）
- 模型 (2)：`Risk_Dummy ~ childhealth + age + gender + hukou + marriage`（Logit）
- 模型 (3)：`Risk_Ratio ~ childhealth`（OLS）
- 模型 (4)：`Risk_Ratio ~ childhealth + age + gender + hukou + marriage`（OLS）
- 标准误：`HC1` 稳健标准误。

## 3. 主结果（childhealth）

- (1) `Risk_Dummy` Logit：`-0.0493*`（SE `0.0277`，`p=0.0750`，`N=14687`）
- (2) `Risk_Dummy` Logit + controls：`-0.0304`（SE `0.0283`，`p=0.2832`，`N=14686`）
- (3) `Risk_Ratio` OLS：`-0.0011`（SE `0.0016`，`p=0.4805`，`N=14687`）
- (4) `Risk_Ratio` OLS + controls：`-0.0003`（SE `0.0016`，`p=0.8628`，`N=14686`）

## 4. 与论文表 2 对照

论文表 2 报告（`childhealth`）：
- (1) `-0.045`
- (2) `-0.032`
- (3) `-0.003`
- (4) `-0.002`

本次复现差值（复现值 - 论文）：
- (1) `-0.0043`
- (2) `+0.0016`
- (3) `+0.0019`
- (4) `+0.0017`

结论：
- Logit 两列方向和量级接近论文；
- OLS 两列方向一致但系数偏小且不显著。

## 5. 增强复核：OLS 全量网格搜索（448 方案）

### 5.1 设计

网格维度：
- 分母口径：`32` 组（在基础分母 `cash+deposit+bond+stock+fund+lend` 上，枚举是否加入 `emoney/other_fin/housing_fund/jizikuan/unpaid_salary`）
- 风险资产口径：`2` 组（`stock+fund`；`stock+fund+lend`）
- 样本方案：`7` 组（`all`、`financial_asset_total_gt0`、`risk_ratio_gt0`、`winsor_top1`、`winsor_top2`、`trim_totalasset_p1_99`、`trim_totalasset_p2_98`）

合计：`32 × 2 × 7 = 448` 个场景（`896` 条模型记录）。

### 5.2 最接近论文 OLS 目标的方案

按目标误差 `|beta(3)-(-0.003)| + |beta(4)-(-0.002)|` 排序：
- Top 1（以及 Top 2/3 的相近变体）为：
  - 风险口径：`stock+fund+lend`
  - 分母：`cash+deposit+bond+stock+fund+lend+housing_fund+unpaid_salary`
  - 样本：`winsor_top1`（或 `all/winsor_top2`）
  - 结果：
    - (3) 约 `-0.0015`（`p≈0.36`）
    - (4) 约 `-0.0006`（`p≈0.73`）

### 5.3 复核结论

- 在当前可得数据下，广泛口径变换后 OLS 仍无法逼近论文显著性（最佳也不显著）。
- `Risk_Ratio` 的主偏差不太可能由单一分母口径造成，更可能来自：
  - 论文未公开的样本清洗细节（尤其 `N=14019` 的形成路径）；
  - 资产变量映射与缺失处理口径差异；
  - 可能存在加权/抽样框架差异（2018 权重文件存在，但论文未披露是否加权；在当前样本上尝试按 `INDV_weight` 加权的 OLS 未能恢复显著性，详见后续复现报告可补充）。

## 5.4 新增复核：资产缺失值处理（NA→0，impute0）

动机：阶段 2 在构造 `Risk_Ratio` 前要求金融资产分母组件“完全可观测”（complete-case），可能导致样本选择差异；论文未披露对资产缺失的具体口径，因此补充“将资产缺失记为 0”作为敏感性方案。

实现方式：
- 在阶段 2 的 **S4**（保留核心控制变量可用）之后、执行 complete-case 之前，保存中间样本：
  - `output/analysis_sample_stage2_step5_pre_asset_complete_cases.rds`
- 在该样本上对资产组件执行 `NA -> 0`，并重新跑与 5.1 相同的 OLS 口径网格：
  - 脚本：`src/03b_baseline_ols_grid_search_impute0.R`
  - 输出：`output/tables/table2_ols_grid_search_impute0.csv`、`output/tables/table2_ols_grid_top10_impute0.csv`

关键结论（Top 1 场景）：
- (3) 约 `-0.0019`（`p≈0.25`，`N=15598`）
- (4) 约 `-0.0009`（`p≈0.60`，`N=15598`）

结论：即使将资产缺失按 0 处理并扩大样本，`Risk_Ratio` 的 OLS 仍无法恢复论文表 2 的显著性；该偏差更可能来自论文不可观测的清洗细节/样本约束或资产口径差异（非单一缺失处理规则所致）。

## 6. 可用于报告的理论性表述

- 当前证据更稳健地支持“童年健康与风险资产参与存在负相关”（Logit 列）。
- 对“风险资产持有比例”的线性效应，在大量 0 值与口径敏感性下表现出明显不稳定，提示该机制更可能体现在“是否参与”而非“参与后比例”层面。

## 7. 阶段 4 验收结论

- 阶段 4 已完成并补充增强复核。
- 复现状态：
  - `Risk_Dummy`：接近论文；
  - `Risk_Ratio`：方向一致但显著性未复现。
