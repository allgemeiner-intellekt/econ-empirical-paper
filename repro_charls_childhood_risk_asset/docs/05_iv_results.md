## 阶段 5：内生性处理复现（表 3）（完成于 2026-02-27，已做增强复核）

## 1. 执行脚本与产物

- 主脚本：`src/04_iv_2sls.R`
- 增强复核脚本：`src/04a_iv_candidate_scan.R`
- 结果表：
  - `output/tables/table3_reproduced.csv`
  - `output/tables/table3_reproduced_all.csv`
  - `output/tables/table3_first_stage.csv`
  - `output/tables/table3_iv_availability.csv`
  - `output/tables/table2_table3_compare.csv`
  - `output/tables/table3_iv_candidate_scan.csv`
  - `output/tables/table3_iv_candidate_top.csv`
- 日志：
  - `logs/iv_2sls_summary.log`
  - `logs/iv_search_extended.log`
  - `logs/iv_candidate_scan.log`

## 2. 官方 IV（hospital）可得性与落地方式

论文口径：`hospital` 为童年就医可及性（两小时内可就医）。

当前执行口径：
- 在 harmonized LH 可直接落地且与命名最接近的变量为 `rachhospital`（童年因健康住院）。
- 因此在本复现中将 `hospital_proxy = rachhospital` 作为“可执行版本”进行 2SLS，同时明确其与论文叙述的 IV 定义不完全同义。

## 3. 使用 `rachhospital` 的 2SLS 结果（表 3 当前主复现）

二阶段 `childhealth` 系数：
- (1) `Risk_Dummy`：`0.0493`（SE `0.0323`，`p=0.1270`）
- (2) `Risk_Dummy` + controls：`0.0029`（SE `0.0302`，`p=0.9230`）
- (3) `Risk_Ratio`：`0.0138`（SE `0.0196`，`p=0.4811`）
- (4) `Risk_Ratio` + controls：`-0.0113`（SE `0.0188`，`p=0.5466`）

第一阶段：
- F 值约 `107.74-112.99`（相关性强）。

对照论文表 3（`-0.221, -0.108, -0.130, -0.068`）：
- 当前结果方向与论文不一致（仅第4列为负），且显著性明显不足。

## 4. 增强复核：IV 候选扫描（5 个候选）

候选来源（均为 LH 童年健康相关离散变量）：
- `miss_school_health`（`ramischlth`）
- `bedbound_health`（`rachbedhlth`）
- `hospitalized_childhood`（`rachhospital`）
- `hospitalized_3plus`（`rachhospital3`）
- `vaccinated_childhood`（`rachvaccine`）

### 4.1 关键发现

- 满足“4列系数均为负且第一阶段 F>10”的候选有 3 个：
  - `vaccinated_childhood`
  - `hospitalized_3plus`
  - `bedbound_health`
- 其中按“与论文表 3 总体差距”排序，`vaccinated_childhood` 最接近（但第1/3列绝对值明显更大）。

### 4.2 代表性候选对照

1) `vaccinated_childhood`：
- 二阶段约 `[-0.462, -0.162, -0.214, -0.045]`
- 第一阶段 F 最小值约 `12.35`
- 现象：方向一致，但量级过大（前3列偏离显著）。

2) `hospitalized_3plus`：
- 二阶段约 `[-0.012, -0.032, -0.016, -0.028]`
- 第一阶段 F 最小值约 `138.06`
- 现象：方向一致但系数偏小。

3) `bedbound_health`：
- 二阶段约 `[-0.008, -0.007, -0.002, -0.002]`
- 第一阶段 F 最小值约 `421.36`
- 现象：方向一致但几乎接近零。

## 5. 与阶段 4 联动解释（可直接用于报告）

阶段 4 显示：`childhealth` 与风险资产投资呈负向相关（尤其参与概率）。

阶段 5 显示：
- 当 IV 取 `rachhospital` 时，2SLS 结果方向不稳定；
- 当改用其他童年健康事件变量作为 IV 时，方向可转为负，但系数量级在“过小”和“过大”之间波动明显。

可报告的理论性表述：
- **相关关系稳健**：童年健康较差与成年风险资产参与更低的相关性得到重复支持。  
- **因果识别敏感**：在当前 harmonized 可得候选中，IV 选择对二阶段结果高度敏感，说明“工具变量的外生性假设”是结果分歧核心来源。  
- **识别边界**：在缺少与论文描述完全同义的“就医可及性”原始字段时，当前 2SLS 应被解释为“受限识别与敏感性分析”，而非论文主结论的等价复现。

## 6. 复现状态总结

- 表 3 已可运行并有完整输出；
- 但“官方 IV 定义的因果结论”尚未完全复现；
- 当前最接近论文方向的候选 IV 已定位并量化，后续可在原始 2014 Life History 模块到位后做最终替换与补跑。
