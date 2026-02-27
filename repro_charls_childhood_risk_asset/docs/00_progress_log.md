# 复现执行过程日志

## 2026-02-27 阶段 0 完成记录

- 验收范围：复现工程骨架是否齐备。
- 验收结果：
  - `repro_charls_childhood_risk_asset/` 根目录存在；
  - `README.md`、`src/`、`output/`、`logs/`、`docs/`、`config/` 均存在；
  - 执行计划文档 `docs/00_execution_plan.md` 已就位。
- 结论：阶段 0 达到计划要求，可进入阶段 1（数据清点与可用性核验）。

## 2026-02-27 阶段 1 完成记录

- 验收范围：`data/temp_2018/*.dta` 与 `data/H_CHARLS_LH_a.dta` 的可读性、键字段、联结可行性、关键变量可得性。
- 执行脚本：`src/00_data_inventory_check.R`。
- 产出文件：
  - `logs/data_inventory_summary.log`
  - `output/data_inventory_2018_modules.csv`
  - `output/data_inventory_2018_household_keys.csv`
  - `output/data_inventory_lh_keyvars.csv`
  - `docs/01_data_inventory.md`
- 关键结果：
  - 2018 模块 `14/14` 可读取；
  - `12` 个模块可用 `ID` 联结，`2` 个家庭层模块通过 `householdID` 联结且无缺失、无重复；
  - Life History 文件 `ID` 无缺失、无重复；
  - 2018 与 Life History 的 `ID` 交集为 `18298`（存在样本收缩）；
  - `familystarved`、`nofood` 变量不可得（需待原始模块后补跑阶段 6 子任务）。
- 结论：阶段 1 达到计划要求，可进入阶段 2（样本构建与清洗规则落地）。

## 2026-02-27 阶段 2 完成记录

- 验收范围：样本构建、清洗规则落地、样本流失统计与阶段文档输出。
- 执行脚本：`src/01_build_sample.R`。
- 产出文件：
  - `output/sample_flow.csv`
  - `output/analysis_sample_stage2.csv`
  - `output/analysis_sample_stage2.rds`
  - `logs/sample_build_summary.log`
  - `logs/sample_size_sensitivity.log`
  - `logs/iv_variable_precheck.log`
  - `docs/02_sample_construction.md`
- 关键结果：
  - 最终分析样本量：`14687`；
  - 风险资产持有率（`Risk_Dummy` 均值）：`9.78%`；
  - 样本流失中最大环节为“缺失童年健康信息”（`-1952`）；
  - 论文样本量 `14019` 尚未完全对齐（差 `668`），已完成敏感性探索并记录。
- 新识别风险：
  - 论文 IV `hospital`（两小时内可就医便利）未在当前 harmonized Life History 中定位到同义变量，可能影响阶段 5 的 2SLS 复现。
- 结论：阶段 2 达到计划要求，可进入阶段 3（变量构造与变量字典）。

## 2026-02-27 阶段 3 完成记录

- 验收范围：核心变量、控制变量、机制变量、异质性变量、IV 变量可得性处理与字典化文档。
- 执行脚本：`src/02_construct_variables.R`。
- 产出文件：
  - `output/analysis_dataset.csv`
  - `output/analysis_dataset.rds`
  - `output/analysis_dataset_missingness.csv`
  - `logs/variable_construction_summary.log`
  - `docs/03_variable_dictionary.md`
- 关键结果：
  - 分析数据集规模：`14687 x 53`；
  - `Risk_Dummy`、`Risk_Ratio`、`childhealth`、控制变量已按统一口径构造；
  - 机制与异质性变量（`education/health/lntotalasset/depressed/hopeful/fear/under60/edu`）已构造完成；
  - 论文 IV `hospital` 当前不可得，已保留空列并同步构造非等价代理 `hospital_proxy`（`rachhospital`）供敏感性分析。
- 新识别风险：
  - 机制变量 `lntotalasset` 目前采用“个人金融资产口径”近似，可能与论文“总资产口径”存在偏差。
- 结论：阶段 3 达到计划要求，可进入阶段 4（基准回归复现，表2）。

## 2026-02-27 阶段 4 完成记录

- 验收范围：表 2 基准模型（Logit + OLS）与稳健标准误复现。
- 执行脚本：`src/03_baseline_models.R`。
- 产出文件：
  - `output/tables/table2_reproduced.csv`
  - `output/tables/table2_reproduced_full.csv`
  - `output/tables/table2_model_diagnostics.csv`
  - `output/tables/table2_paper_compare.csv`
  - `output/tables/table2_ols_sensitivity.csv`
  - `logs/baseline_models_summary.log`
  - `docs/04_baseline_results.md`
- 关键结果（`childhealth`）：
  - Logit (1)：`-0.0493*`；
  - Logit (2)：`-0.0304`；
  - OLS (3)：`-0.0011`；
  - OLS (4)：`-0.0003`。
- 复现偏差：
  - Logit 两列与论文方向和量级接近；
  - OLS 两列方向一致但不显著，未复现论文显著性。
- 已探索方案：
  - 对 OLS 做了样本/口径敏感性（`financial_asset_total>0`、`Risk_Ratio>0`、winsor、窄分母），仍未恢复显著性。
- 结论：阶段 4 达到计划要求，可进入阶段 5（内生性处理复现，表3）；但需在后续报告中持续标注 OLS 偏差来源未完全定位。
