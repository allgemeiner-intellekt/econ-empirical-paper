## 阶段 2：样本构建与清洗规则落地（完成于 2026-02-27）

## 1. 执行脚本与产物

- 执行脚本：`src/01_build_sample.R`
- 关键输出：
  - `output/sample_flow.csv`
  - `output/analysis_sample_stage2.csv`
  - `output/analysis_sample_stage2.rds`
  - `logs/sample_build_summary.log`
- 复现问题探索日志：
  - `logs/sample_size_sensitivity.log`
  - `logs/iv_variable_precheck.log`

## 2. 合并数据来源（均为仓库现有 CHARLS 数据）

- 2018 基础样本：`data/temp_2018/Sample_Infor.dta`
- 2018 人口学：`data/temp_2018/Demographic_Background.dta`
- 2018 个人金融资产：`data/temp_2018/Individual_Income.dta`
- 2014 Life History（harmonized）：`data/H_CHARLS_LH_a.dta`

联结键：
- 个体层统一使用 `ID`。

## 3. 样本构建与清洗规则

### 3.1 基础样本筛选

1) 起始样本：2018 `Sample_Infor` 全部个体。  
2) 保留 `crosssection == 1` 且 `died == 0`。  
3) 计算年龄 `age = iyear - birth_year`，并保留 `age >= 45`。  

其中：
- `birth_year` 取 `ba004_w3_1`（出生年份，缺失远少于 `ba002_1`）。

### 3.2 童年健康与基准控制

4) 童年健康变量 `childhealth_raw = rachchlt`，保留 `1-5` 有效值。  
5) 保留基准控制变量非缺失：
- `gender_raw`（`ba000_w2_3`）
- `hukou_raw`（`zbc004`）
- `marriage_raw`（`be001`）

### 3.3 风险资产构造前的数据清洗

6) 对数值变量统一执行缺失清洗：`x < 0 -> NA`。  
7) 对“是否持有 + 金额”型变量采用条件清洗：
- 指示变量 `==1`：金额取原值；
- 指示变量 `==2`：金额置 `0`；
- 其余编码（如 `999`）：置 `NA`。

### 3.4 金融资产与风险资产（阶段 2 口径）

- 风险资产金额（分子）：
  - `stock_amt`（股票）
  - `fund_amt`（基金）
  - `lend_amt`（借出款）
- 全部金融资产金额（分母）：
  - `cash_amt`、`emoney_amt`、`deposit_amt`、`bond_amt`、`stock_amt`、`fund_amt`、`other_fin_amt`、`housing_fund_amt`、`jizikuan_amt`、`unpaid_salary_amt`、`lend_amt`

并构造：
- `Risk_Dummy = 1(risk_asset_total > 0)`
- `Risk_Ratio = risk_asset_total / financial_asset_total`（若分母 `<=0` 则记为 `0`）

8) 保留可计算 `Risk_Ratio` 的样本（分母组件完整），并剔除异常比例（`Risk_Ratio < 0` 或 `>1`）。

## 4. 样本流失结果（与 `sample_flow.csv` 一致）

- S0 起始样本：`20813`
- S1 保留横截面且存活：`17970`（-2843）
- S2 保留 `age>=45`：`17559`（-411）
- S3 保留童年健康可用：`15607`（-1952）
- S4 保留核心控制变量可用：`15599`（-8）
- S5 保留金融资产分母组件完整：`14687`（-912）
- S6 剔除异常 `Risk_Ratio`：`14687`（-0）

阶段 2 最终样本：`N = 14687`。

## 5. 与论文样本量（N=14019）的差异及影响

当前可复现样本量高于论文 `668`（`14687 - 14019`）。

已完成的差异探索：
- 若强制 `financial_asset_total > 0`，样本降至 `12382`（过度收缩）。
- 若按金融资产总额去除顶端 `1%` 极端值，样本为 `14540`。
- 若去除顶端 `2%`，样本为 `14393`。

结论：仅靠常见极值处理无法自然收敛到 `14019`，说明论文的缺失处理、极值规则或资产口径可能与当前阶段实现存在细节差异。

## 6. 已识别的复现风险与解决方案

风险 1：样本量与论文不完全一致。  
- 影响：后续回归系数可能出现量级偏差。  
- 解决：
  - 阶段 3 建立“变量字典 + 口径对照”，逐项核对资产分母构成；
  - 在阶段 4-5 进行口径敏感性回归并记录最接近论文结果的口径。

风险 2：IV 变量 `hospital`（两小时内可就医便利）尚未在当前 harmonized Life History 中定位到对应字段。  
- 现状：`logs/iv_variable_precheck.log` 仅命中 `rachhospital/rachhospital3`（疾病住院经历），与论文 IV 定义不等价。  
- 影响：阶段 5 的 2SLS 复现可能受阻。  
- 解决：
  - 待原始 2014 Life History 模块到位后优先补定位该 IV；
  - 暂不以 `rachhospital` 直接替代 IV，避免识别假设失真。

## 7. 阶段 2 验收结论

- 已满足阶段 2 要求：
  - 代码：`src/01_build_sample.R`
  - 输出：`output/sample_flow.csv` + 分析样本文件
  - 文档：`docs/02_sample_construction.md`
- 阶段 2 状态：完成，可进入阶段 3（变量构造与字典化）。
