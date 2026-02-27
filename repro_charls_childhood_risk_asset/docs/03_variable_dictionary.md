## 阶段 3：变量构造与字典（完成于 2026-02-27）

## 1. 执行脚本与产物

- 执行脚本：`src/02_construct_variables.R`
- 数据产物：
  - `output/analysis_dataset.csv`
  - `output/analysis_dataset.rds`
  - `output/analysis_dataset_missingness.csv`
- 日志产物：
  - `logs/variable_construction_summary.log`

## 2. 构造口径总览

样本基础：使用阶段 2 样本 `analysis_sample_stage2`（`N=14687`），按 `ID` 合并以下 2018 模块：
- `Health_Status_and_Functioning.dta`
- `Cognition.dta`
- `Work_Retirement.dta`

统一清洗规则：
- 数值字段先转数值型，`<0` 统一记为缺失。
- 情绪变量 `dc011/dc013/dc014` 仅保留 `1-4`，将 `8/9` 记为缺失。

## 3. 变量字典（核心）

| 变量名 | 类型 | 来源字段 | 构造规则 | 取值方向 |
|---|---|---|---|---|
| `Risk_Dummy` | 被解释变量 | 阶段 2 资产构造 | `1(risk_asset_total>0)` | 1=持有风险资产 |
| `Risk_Ratio` | 被解释变量 | 阶段 2 资产构造 | `risk_asset_total / financial_asset_total`（限制在[0,1]） | 越大=风险资产占比越高 |
| `childhealth` | 核心解释变量 | `rachchlt` | 保留 `1-5` | 数值越大=童年健康越差 |
| `age` | 控制变量 | `iyear - ba004_w3_1` | 阶段 2 已构造 | 越大=年龄越高 |
| `gender` | 控制变量 | `ba000_w2_3` | 男=1，女=0 | 1=男性 |
| `hukou` | 控制变量 | `zbc004` | 非农/统一户口=1，农业户口=0（无户口记缺失） | 1=非农属性 |
| `marriage` | 控制变量 | `be001` | 已婚/与配偶暂时分居=1，其余=0 | 1=当前有婚姻关系 |
| `work` | 稳健性控制 | `fa002_w4` | 非农工作=1，否则=0 | 1=有非农工作 |
| `work_any` | 稳健性备选 | `fa002_w4`,`fa006_w3_1` | 非农或农业任一工作=1，否则=0 | 1=有任意工作 |
| `hospital` | IV（论文口径） | — | 当前数据不可得，设为全缺失 | — |
| `hospital_proxy` | IV 代理（非等价） | `rachhospital` | 住院经历 yes/no 映射为 1/0 | 1=童年因健康住院 |
| `education` | 机制变量 | `bd001_w2_4` | 保留 `1-11` 并将 11 合并到 10 | 越大=教育程度越高 |
| `health` | 机制变量 | `da002` | 保留 `1-5` | 越大=成年健康越差 |
| `lntotalasset` | 机制变量 | `financial_asset_total` | `log(1 + financial_asset_total)` | 越大=资产水平更高 |
| `depressed` | 机制变量 | `dc011` | 保留 `1-4` | 越大=更抑郁 |
| `hopeful` | 机制变量 | `dc013` | 保留 `1-4` | 越大=更乐观 |
| `fear` | 机制变量 | `dc014` | 保留 `1-4` | 越大=更恐惧 |
| `under60` | 异质性变量 | `age` | `age<=60` 记1，否则0 | 1=60岁及以下 |
| `edu` | 异质性变量 | `bd001_w2_4` | 高中及以上(>=6)=1，否则0 | 1=高教育组 |

## 4. 缺失情况（关键变量）

见 `output/analysis_dataset_missingness.csv`，核心结论：
- 基准回归核心变量（`Risk_Dummy/Risk_Ratio/childhealth/age/gender/marriage`）缺失极低或为 0。
- `hukou` 缺失 `1` 个。
- 机制变量存在可预期缺失：
  - `health` 缺失 `806`
  - `depressed` 缺失 `1268`
  - `hopeful` 缺失 `1734`
  - `fear` 缺失 `1102`
- `hospital` 全缺失（`14687`），当前无法按论文定义直接做 IV。

## 5. 影响复现结果的问题与处理

问题 1：论文 IV `hospital` 变量缺失。  
- 影响：阶段 5 的 2SLS 不能按论文原定义直接复现。  
- 处理：
  - 在数据集中保留 `hospital`（全缺失）与 `hospital_proxy`（`rachhospital`）并明确“仅代理、非等价”；
  - 阶段 5 主文将报告该限制，避免将代理变量结果误判为论文 IV 结果。

问题 2：`lntotalasset` 目前由个人金融资产口径构造。  
- 影响：可能与论文“总资产（风险+非风险）”口径存在偏差。  
- 处理：
  - 阶段 7 做机制回归时并行报告该口径限制；
  - 后续如定位到更完整资产口径字段，再替换并重跑机制结果。

## 6. 阶段 3 验收结论

- 已满足阶段 3 要求：
  - 代码：`src/02_construct_variables.R`
  - 输出：`output/analysis_dataset.*`
  - 文档：`docs/03_variable_dictionary.md`
- 阶段 3 状态：完成，可进入阶段 4（基准回归复现，表2）。
