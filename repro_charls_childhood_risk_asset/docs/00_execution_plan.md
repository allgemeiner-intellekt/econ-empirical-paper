## CHARLS 论文复现分阶段执行计划（待审核）

- 数据状态更新（2026-02-27）：
  - 已确认 `data/H_CHARLS_LH_a.dta` 可用，可提供 `childhealth` 相关变量（如 `rachchlt`）及部分童年健康经历变量。
  - 已确认该 harmonized Life History 文件不包含 `familystarved`、`nofood`（对应原始问卷 `C4`、`C3_a`），相关原始数据仍在申请中。
  - 执行策略：先完成不依赖上述缺口变量的阶段；阶段 6 中“童年饥饿/家庭贫困直接控制”子任务延期，待数据获批后补跑并更新文档。

- [x] 阶段 0：建立复现工程骨架。目标：在根目录新建文件夹 `repro_charls_childhood_risk_asset/`，统一放置代码、结果、日志和文档；产物：`README.md`、`src/`、`output/`、`logs/`、`docs/`、`config/` 基础结构。（完成日期：2026-02-27）
- [x] 阶段 1：数据清点与可用性核验。目标：核验 `CHARLS 2018` 与 `2014 Life History` 是否齐全、字段是否可读、主键是否可联结；产物：`docs/01_data_inventory.md`（含文件清单、关键字段、缺失风险、替代方案）。（完成日期：2026-02-27）
- [ ] 阶段 2：样本构建与清洗规则落地。目标：按论文口径完成合并、去缺失、去异常，形成分析样本；产物：`src/01_build_sample.*`、`output/sample_flow.csv`、`docs/02_sample_construction.md`（含最终样本量与每步筛选损失）。
- [ ] 阶段 3：变量构造。目标：完成 `Risk_Dummy`、`Risk_Ratio`、`childhealth`、控制变量、IV(`hospital`)、机制变量、异质性变量构造；产物：`src/02_construct_variables.*`、`output/analysis_dataset.*`、`docs/03_variable_dictionary.md`。
- [ ] 阶段 4：基准回归复现（表2）。目标：`Risk_Dummy` 用 Logit，`Risk_Ratio` 用 OLS，使用稳健标准误；产物：`src/03_baseline_models.*`、`output/tables/table2_reproduced.*`、`docs/04_baseline_results.md`（与论文系数方向和量级对照）。
- [ ] 阶段 5：内生性处理复现（表3）。目标：以 `hospital` 为工具变量做 2SLS，报告第一阶段 F 值与二阶段结果；产物：`src/04_iv_2sls.*`、`output/tables/table3_reproduced.*`、`docs/05_iv_results.md`。
- [ ] 阶段 6：稳健性检验。目标：加入 `work`、`familystarved`、`nofood`、童年家庭经济状况控制，并对 `Risk_Ratio` 使用 Tobit；产物：`src/05_robustness.*`、`output/tables/table_robustness.*`、`docs/06_robustness.md`。
- [ ] 阶段 7：机制分析复现（表4-5）。目标：复现人力资本/财富积累与情绪性格两条机制回归；产物：`src/06_mechanism.*`、`output/tables/table4_reproduced.*`、`output/tables/table5_reproduced.*`、`docs/07_mechanism.md`。
- [ ] 阶段 8：异质性分析复现（表6-7）。目标：复现年龄与教育异质性（含交互项与对应 IV 列）；产物：`src/07_heterogeneity.*`、`output/tables/table6_reproduced.*`、`output/tables/table7_reproduced.*`、`docs/08_heterogeneity.md`。
- [ ] 阶段 9：结果汇总与可重复运行封装。目标：提供一键运行脚本与复现偏差说明；产物：`run_all.*`、`docs/09_reproduction_report.md`（逐表对照论文）、`docs/10_limitations_and_gaps.md`。
- [ ] 阶段 10：最终交付检查。目标：检查路径、代码可运行性、文档完整性、输出可追溯性；产物：根目录下完整复现文件夹与最终交付清单。

## 当前执行顺序（按数据可得性调整）

- [ ] 先执行：阶段 0-5、阶段 7-10（不依赖 `familystarved/nofood` 可先完成主体复现）。
- [ ] 暂缓执行：阶段 6 中“加入 `familystarved`、`nofood`、童年家庭经济状况直接指标”的子任务。
- [ ] 数据到位后补跑：阶段 6 缺失子任务 + 受其影响的结果汇总文档（`docs/06_robustness.md`、`docs/09_reproduction_report.md`、`docs/10_limitations_and_gaps.md`）。

## 阶段验收标准（统一口径）

- [ ] 每个阶段均有“代码文件 + 输出文件 + 说明文档”三件套。
- [ ] 所有表格均可由脚本自动再生成，不依赖手工改表。
- [ ] 每个核心变量均在字典中有“来源字段、构造公式、取值方向”说明。
- [ ] 对无法完全复现处给出明确原因（数据缺失、口径差异、字段不可得）。
