# 选题 01：配偶髋部骨折冲击对照护者抑郁的影响（性别不平等视角）

## 研究问题（Gender Equality）
在中国家庭内，照护责任往往呈现显著的性别分工。一个强烈且相对“意外”的健康冲击——**配偶髋部骨折**——是否会显著抬升幸存/照护方的抑郁水平？这种影响在妻子与丈夫之间是否存在差异？

这是一类更贴近“性别平等”的因果推断问题：同样的家庭冲击，是否通过照护分工、情绪劳动与机会成本对女性造成更大的心理代价。

---

## 数据与变量（仅 CHARLS）
**波次**：2013 / 2015 / 2018（不使用 2020 的心理健康量表，避免语境不可比问题）  
**样本**：夫妻配对样本（同一 `householdID` 下 `ID` 后两位为 `01/02` 的两位受访者）

### 处理（Treatment）
配偶髋部骨折：
- 2013/2015：`Health_Status_and_Functioning.dta` 中 `da025`（Fractured Your Hip）
- 2018：`Health_Status_and_Functioning.dta` 中 `da025_w4`（Fractured Hip since ZIWTime?）

构造“晚期处理”（2015→2018）：
- 限制：配偶在 2013 与 2015 均无髋部骨折（`da025==2` → 0）
- 处理组：2018 报告 **2015 以来发生髋部骨折**（`da025_w4==1`）
- 对照组：2018 未发生（`da025_w4==2`）

### 结果（Outcome）
照护者抑郁（CES-D 10项，总分）：
- 2013/2015：`Health_Status_and_Functioning.dta` 中 `dc009–dc018`
- 2018：`Cognition.dta` 中 `dc009–dc018`
- 反向计分：`dc013`、`dc016`（按 `5 - 原值`）

### 协变量（建议）
`Demographic_Background.dta`：
- 性别：`ba000_w2_3`
- 年龄（由出生年推得；2018 可用 `ba004_w3_1`）

---

## 识别策略（吸取失败选题的教训）
### 核心设计：差分中的差分（DiD）+ 明确的前趋势检验
把“配偶髋部骨折（2015→2018）”视为外生冲击，比较处理组与对照组在：
1) **处理前（2013→2015）**抑郁变化是否相同（平行趋势检验）
2) **处理后（2015→2018）**抑郁变化是否出现显著差异（主效应）

相比你已有的失败案例（丧偶错期DiD），本题的关键改进点是：
- 选择更“突发/意外”的健康事件（髋部骨折通常由跌倒等意外触发），降低照护预期效应污染；
- 仍然**先做前趋势检验**，不通过就直接放弃/改设计。

---

## 仓库内“简单验证”（已用 R 快检）
基于本仓库数据的快速核查（脚本见 `analysis/topic_screening.R`）：

- 三期平衡夫妻样本（2013/2015/2018）中，满足“配偶2013&2015无髋部骨折”的照护者：`N = 9,265`
- 其中配偶在 2015→2018 发生髋部骨折：`treated N = 88`

### 平行趋势检验（2013→2015）
处理组相对对照组的抑郁变化差异：
- `+0.643` CES-D 分（p = `0.287`）→ **未发现显著前趋势差异**

### 处理效应（2015→2018）
处理组相对对照组的抑郁变化差异：
- `+2.153` CES-D 分（p = `0.015`）→ **显著抬升抑郁**

这类“冲击→抑郁”效应量在 CHARLS 的 CES-D 量表上已经不小，且在小样本下仍显著，属于“更可能做出显著性结果”的候选题。

---

## 主要回归（建议写法）
以变化量形式实现 DiD（更直观、也便于前趋势检验）：

1) 前趋势：  
`ΔCESD(2013→2015) = α + β * Treated + γ * Female + ε`

2) 主效应：  
`ΔCESD(2015→2018) = α + τ * Treated + γ * Female + ε`

建议将标准误聚类在 `householdID`（夫妻共享冲击与误差项）。

---

## 稳健性与扩展（建议但不必一开始就做）
- **排除照护者本人也发生髋部骨折/严重跌倒**（避免共同健康冲击）
- 以 2013 抑郁水平分组：基线心理健康差的人是否更脆弱
- 异质性：`Treated × Female`（妻子是否更受冲击；需要更大 treated N）
- 替代结果：睡眠、疼痛、ADL/IADL（模块同源、可比性更强）

---

## 相关文献线索（网络调研要点）
（仅用于定位研究位置，不引入外部数据）
- Ma, J., Yang, H., Hu, W., & Khan, H. T. A. (2022). *Spousal Care Intensity, Socioeconomic Status, and Depression among the Older Caregivers in China: A Study on 2011–2018 CHARLS Panel Data*. **Healthcare**, 10(2), 239. DOI: 10.3390/healthcare10020239
- Ichioka, S., et al. (2021). *Factors related to caregiver burden among caregivers of patients with hip fracture*. **Journal of Bone and Mineral Metabolism**.（髋部骨折与照护负担）
- Johnson, A. M., et al. (2023). *Depression among caregivers of older adult hip fracture patients*. **Journal of Family Nursing**.（髋部骨折照护与抑郁）
