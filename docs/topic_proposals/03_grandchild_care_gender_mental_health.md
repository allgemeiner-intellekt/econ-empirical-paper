# 选题 03：照料孙辈对抑郁的影响是否存在“性别反转”（个体固定效应）

## 研究问题（Gender Equality）
隔代照料既可能是“负担”（对女性），也可能是“社会参与/意义感来源”（对男性）。同一项家庭角色变化，是否在心理健康上呈现**性别差异甚至方向相反**？

> 当个体开始照料孙辈后，抑郁（CES-D）如何变化？这种变化在男性与女性之间是否显著不同？

---

## 数据与变量（仅 CHARLS）
**波次**：2013 / 2015 / 2018（不使用 2020 CES-D 语境不同版本）

### 处理变量：是否照料孙辈
`Family_Transfer.dta`：`cf001`（Take Care of GrandChildren），二值化同选题 02。

### 结果变量：CES-D 10项总分
- 2013/2015：`Health_Status_and_Functioning.dta`，`dc009–dc018`
- 2018：`Cognition.dta`，`dc009–dc018`
- 反向计分：`dc013`、`dc016`（`5-原值`）
- 2018 的 `8=不知道/9=拒绝` 等非常规取值应重编码为 NA（避免假高/假低）

---

## 识别策略
与选题 02 同：个体 FE + 波次 FE，利用同一人照护状态变化识别抑郁变化，并关注性别异质性：

`CESD_it = α_i + λ_t + β1 * care_it + β2 * (care_it × female_i) + ε_it`

---

## 仓库内“简单验证”（已用 R 快检）
在 `age<=70` 的面板样本中（脚本见 `analysis/topic_screening.R`）：

- 面板观测：`N = 19,048`
- 个体数：`11,298`

固定效应结果（CES-D 为因变量）：
- 男性（基准组）：`care` 系数约 `-0.415`（p = `0.038`）
- 女性相对男性差异：`care × female` 约 `+0.494`（p = `0.102`）

解读：男性开始照料孙辈后抑郁显著下降；女性并未出现相同改善（女性净效应约 `-0.415+0.494≈+0.08`）。

在 `age<=65` 的限制下，性别差异更清晰：
- 男性 `care ≈ -0.520`（p ≈ `0.047`）
- `care × female ≈ +0.709`（p ≈ `0.049`）

这类“同一家庭角色变化对男女心理回报不同”的发现，天然与性别平等讨论相关，并且在 FE 框架下已经有显著/边际显著信号，属于可推进的选题。

---

## 关键风险与建议的稳健性
- **反向因果**：抑郁变化可能影响是否愿意照护。建议用 2013→2015 的抑郁变化预测 2015→2018 的照护进入（或做 lead/lag 安慰剂）。
- **共同冲击**：例如子女生育/搬迁同时影响照护与抑郁。可加入家庭结构变动控制（仍在 CHARLS 内，例如同住、子女数量变化等）。
- **强度异质性**：若能构造“照护哪位子女的孩子/照护对象数量”（`cf002_s*`）与“孙辈数量（16岁以下）”（`Family_Information.dta` 的 `cb068_*`），可做剂量反应分析。

---

## 相关文献线索（网络调研要点）
CHARLS 上关于隔代照料与心理健康的研究已经较多，但对“性别差异/机制”仍可更聚焦（例如情绪回报 vs 负担渠道），便于把本文放在性别平等框架下，例如：
- Wang, Y., Hu, P., & Li, B. (2024). *Association between grandchild caregiving and depression in older adults: A study from the China Health and Retirement Longitudinal Study*. **Frontiers in Psychiatry**, 15, 1424582. DOI: 10.3389/fpsyt.2024.1424582
- Wang, T., et al. (2024). *Care of grandchildren and depression of grandparents in China: a propensity score matching difference-in-differences approach*. **International Journal of Geriatric Psychiatry**. DOI: 10.1002/gps.6091
- Wu, Q., Glaser, K., & Avendano, M. (2022). *Is transition to grandparenthood always associated with better mental health? Evidence from English and Chinese longitudinal panel data*. **SSM – Population Health**, 20, 101272. DOI: 10.1016/j.ssmph.2022.101272
