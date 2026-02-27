## 阶段 1：数据清点与可用性核验（更新于 2026-02-27）

## 1. 文件可用性

- 已核验文件：`data/H_CHARLS_LH_a.dta`
- 文件格式：Stata 117，可正常读取
- 数据规模：`20656` 行，`351` 列

## 2. 主键与联结可行性

- `ID`：无缺失、无重复（`20656/20656` 唯一）
- 可用于与 2018 主样本按个体 ID 进行一对一联结
- 其他辅助键：`householdID`、`communityID`

## 3. 与研究问题相关的可用变量（Life History）

- 童年健康核心：
  - `rachchlt`：15 岁前相对健康自评（5 档）
- 童年健康经历：
  - `ramischlth`：15 岁前因健康停学
  - `rachbedhlth`：15 岁前因健康卧床
  - `rachhospital`：15 岁前因健康住院
  - `rachhospital3`：15 岁前住院 3 次
  - `rachvaccine`：童年疫苗接种
- 童年家庭背景代理：
  - `ramomoccup_c`：女性监护人职业（17 岁前）
  - `radadoccup_c`：男性监护人职业（17 岁前）

## 4. 已确认缺口

- 当前文件不含以下计划变量：
  - `familystarved`
  - `nofood`
- 检查方式：
  - 变量名检索：未命中
  - 变量标签检索（`food/starv/famine/hunger`）：未命中
- 原因判断：
  - `H_CHARLS_LH_a.dta` 为 harmonized 子集，未包含原始问卷中的全部童年贫困/饥饿题目。

## 5. 对执行计划的影响

- 可先完成：
  - 阶段 0-5（样本、变量、基准回归、IV）
  - 阶段 7-10（机制、异质性、汇总与交付）
- 需延期补跑：
  - 阶段 6 中“加入 `familystarved`、`nofood`、童年家庭经济直接指标”的稳健性列
- 临时替代（弱代理）：
  - 可用 `ramomoccup_c`、`radadoccup_c` 作为童年 SES 代理控制，但不能等价替代饥饿变量。

## 6. 数据到位后的补跑清单

- 补充导入 2014 Life History 原始相关模块（含 `C3_a`、`C4` 对应变量）
- 更新 `src/02_construct_variables.*` 与 `src/05_robustness.*`
- 重生成并比对：
  - `output/tables/table_robustness.*`
  - `docs/06_robustness.md`
  - `docs/09_reproduction_report.md`
  - `docs/10_limitations_and_gaps.md`
