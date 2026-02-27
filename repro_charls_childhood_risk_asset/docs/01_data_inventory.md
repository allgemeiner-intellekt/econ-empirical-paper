## 阶段 1：数据清点与可用性核验（完成于 2026-02-27）

## 1. 核验范围与方法

- 核验对象：`data/temp_2018/*.dta` 与 `data/H_CHARLS_LH_a.dta`。
- 自动化脚本：`src/00_data_inventory_check.R`。
- 输出产物：
  - `logs/data_inventory_summary.log`
  - `output/data_inventory_2018_modules.csv`
  - `output/data_inventory_2018_household_keys.csv`
  - `output/data_inventory_lh_keyvars.csv`

## 2. 2018 数据可用性结论

- 2018 波次模块文件总数：`14`。
- 可读取文件：`14`，不可读取文件：`0`。
- 含个体键 `ID` 的模块：`12`。
- 不含 `ID` 的模块：`2`（`Household_Income.dta`、`Housing.dta`）。

不含 `ID` 的两个家庭层文件已进一步核验：
- `householdID` 无缺失、无重复。
- 可通过 `householdID` 稳定并入个体样本（按家庭键一对多扩展到个体）。

## 3. Life History 文件可用性结论

- 文件：`data/H_CHARLS_LH_a.dta`
- 数据规模：`20656` 行，`351` 列。
- 主键质量：
  - `ID` 缺失：`0`
  - `ID` 唯一值：`20656`
  - 结论：Life History 可作为个体层一对一联结源。

## 4. 2018 与 Life History 联结可行性

基于 `data/temp_2018/Sample_Infor.dta` 与 `data/H_CHARLS_LH_a.dta` 的 `ID`：
- 2018 唯一 `ID`：`20813`
- Life History 唯一 `ID`：`20656`
- 交集 `ID`：`18298`
- 覆盖率：
  - Life History 被 2018 覆盖 `88.58%`
  - 2018 被 Life History 覆盖 `87.92%`

结论：可联结，但不是全覆盖。后续阶段需在样本流程中显式记录“2018-LH 交集筛选”导致的样本损失。

## 5. 关键变量可得性（Life History）

已可得：
- `rachchlt`（童年健康核心变量）
- `ramischlth`、`rachbedhlth`、`rachhospital`、`rachhospital3`、`rachvaccine`
- `ramomoccup_c`、`radadoccup_c`

当前缺失：
- `familystarved`
- `nofood`

## 6. 对复现阶段的影响与解决方案

影响 1：稳健性子任务变量缺口。
- 问题：`familystarved/nofood` 在 harmonized Life History 中不可得。
- 影响阶段：阶段 6 的“童年饥饿/家庭贫困直接控制”列无法立即复现。
- 解决方案：
  - 当前按计划先推进阶段 0-5、7-10。
  - 待原始 2014 Life History 相关模块数据获批后补跑阶段 6 缺失子任务，并回写阶段 9-10 汇总文档。

影响 2：联结覆盖非 100%。
- 问题：2018 与 Life History `ID` 交集为 `18298`，存在样本收缩。
- 解决方案：
  - 在阶段 2 输出 `sample_flow.csv`，单独列出“因缺失 LH 信息被剔除”的数量与比例。
  - 主结果与稳健性均统一在交集样本口径下运行，避免样本口径漂移。

## 7. 阶段 1 验收结论

- 已满足阶段 1 目标：文件齐全性、字段可读性、主键联结性、缺失风险与替代方案均已形成文档化结论。
- 阶段 1 状态：完成，可进入阶段 2（样本构建与清洗规则落地）。
