# 选题备忘：计划生育老年奖扶（60岁触发）对代际转移/照护的因果效应（CHARLS 内部可做）

## 1. 研究问题（可写成论文标题）
**计划生育老年奖扶（Elderly Family Planning Subsidy）在 60 岁触发**，是否会改变：
- 子女对父母的金钱支持（挤入/挤出）？
- 父母对孙辈照护供给（时间再分配）？
- 上述效应是否在“只有一个存活子女”家庭（尤其是“独女 vs 独子”）中更显著（性别公平/代际规范渠道）？

## 2. 核心识别困难与解决方案
### 2.1 最大混杂：60 岁同时触发“农村养老金领取”
如果只在“仅一存活子女”样本内做 60 岁 RDD，**60 岁养老金（广覆盖）**会与奖扶（窄覆盖）同时变化，难以区分。

**解决思路：Difference-in-Discontinuities（DiDisc）+（可选）双内生变量 2SLS**
- 关键对照：同为农村户口、同一年龄附近，“仅一存活子女” vs “多子女”。
- 直觉：养老金在两组都在 60 岁跳变；奖扶主要只在“仅一存活子女”组显著跳变。
- 因此，60 岁处两组“跳变差”的差，可用于识别奖扶带来的**增量效应**。

进一步，为了显式剥离“养老金跳变在两组可能略不同”的问题，可用 **2SLS（两个处理、两个工具）**：
- 内生处理：`pension_receipt`（或金额）、`fp_subsidy_receipt`（或金额）
- 工具变量：`post60`、`post60 × onechild`
  - `post60` 强预测养老金
  - `post60 × onechild` 强预测奖扶

## 3. 数据与变量（以 2018 波为主）

### 3.1 波次选择
**主波次：2018（`data/temp_2018/`）**
- 优点：收入模块里奖扶与养老金变量清晰；家庭转移模块信息丰富；户口变量可用。

> 备注：2020 的 `Family_Information.dta` 在本仓库版本里是 household-level（无 `ID`），不便与个体收入/健康直接合并，不作为主分析波次。

### 3.2 样本与关键分组
- 限定农村户口：`data/temp_2018/Demographic_Background.dta` 的 `zbc004`（1=农业户口）
- “仅一存活子女”分组：
  - `data/temp_2018/Family_Information.dta` 的 `xchildalive_*`（1=Alive, 2=Dead）
  - 构造 `n_child_alive = Σ 1{xchildalive_k == 1}`，定义 `onechild = 1{n_child_alive == 1}`

（可扩展异质性）
- “独女 vs 独子”：`xchildgender_*`（需要先定位唯一存活子女的序号）

### 3.3 running variable（年龄）
2018 建议用“出生年月 + 访谈年月”构造月龄，避免直接用问卷里的年龄变量不稳定。
- 出生年/月：`data/temp_2018/Demographic_Background.dta` 的 `ba004_w3_1`（year）, `ba004_w3_2`（month）
- 访谈年/月：`data/temp_2018/Sample_Infor.dta` 的 `iyear`, `imonth`
- 月龄：`age_month = (iyear - birth_year)*12 + (imonth - birth_month)`（birth_month 缺失可用 6 月近似）
- running variable：`run = age_month/12 - 60`
- 断点：`post60 = 1{run >= 0}`

### 3.4 处理变量（奖扶与养老金）
**奖扶（计划生育老年补贴）**
- 文件：`data/temp_2018/Individual_Income.dta`
- 领取指示：`ga003_w4_s6`（本数据里 0=No, 6=Yes）
- 领取金额：`ga003_w4_6`

**养老金（用于处理混杂）**
- 文件：`data/temp_2018/Individual_Income.dta`
- 领取指示：`ga003_w4_s1`（0/1）
- 领取金额：`ga003_w4_1`

### 3.5 结果变量（建议先做“代际转移/照护”）
**子女对父母的金钱支持**
- 文件：`data/temp_2018/Family_Transfer.dta`
- 逐子女金额：`ce009_1_*`（Total Money Support from child k）
- 构造：`money_from_children = rowSums(ce009_1_*, na.rm=TRUE)`；也可做 `any_money = 1{money_from_children>0}`

**照护孙辈（时间供给）**
- 文件：`data/temp_2018/Family_Transfer.dta`
- `cf001`（Take Care of GrandChildren）

> 建议用 `log1p(money_from_children)` 与 `any_money` 两套口径（金额右偏很重）。

## 4. 可行性快速核查（2018，已在本仓库数据上跑过）
在 2018、农业户口（`zbc004==1`）样本中，取 `|age-60|<=2` 年窗口：
- 样本量约 `N≈1015`，其中 `onechild==1` 约 `N≈126`
- 奖扶领取率（`ga003_w4_s6==6`）：
  - 多子女组：60 岁前约 `0.5%`，60 岁后约 `2.0%`
  - 仅一存活子女组：60 岁前约 `10.7%`，60 岁后约 `50.0%`
- DiDisc 一阶（回归 `fp_subsidy_receipt ~ post60*onechild + run + run*post60`）中，`post60×onechild` 的系数约 `0.38`，且极显著（强第一阶段）。
- 养老金在两组都在 60 岁显著上升，且两组跳变量差异不大（但不保证为 0），因此推荐用“双处理 2SLS”显式控制。

结论：**第一阶段足够强，选题可继续推进**；主要挑战是窗口内“onechild”样本较小，需要谨慎做带宽与稳健性。

## 5. 建议的主回归（给写作用）

### 5.1 DiDisc（Reduced form）
以 `Y` 为结果（如 `log1p(money_from_children)`）：

`Y = α + β1·post60 + β2·onechild + β3·(post60×onechild) + f(run) + post60·g(run) + ε`

- `β3` 为 DiDisc 估计：一存活子女组在 60 岁处相对多子女组的“额外跳变”。

### 5.2 双处理 2SLS（推荐）
第二阶段（局部线性）：

`Y = α + θ1·pension + θ2·fp_subsidy + f(run) + post60·g(run) + u`

第一阶段：
- `pension ~ post60 + (post60×onechild) + f(run) + post60·g(run)`
- `fp_subsidy ~ post60 + (post60×onechild) + f(run) + post60·g(run)`

工具变量：
- `Z1 = post60`
- `Z2 = post60×onechild`

解释：
- `θ2` 是在“同时允许养老金影响”的条件下，奖扶的局部因果效应（更接近政策解释）。

## 6. 关键稳健性与“踩坑清单”
- **带宽敏感性**：`0.5y / 1y / 2y / 3y` 比较，必要时用 `rdrobust` 风格的局部多项式与偏误修正（用 R 包实现）。
- **协变量平衡/安慰剂**：对教育（`bd001_w2_4`）、性别（`ba000_w2_3`）、婚姻（`be001`）等做相同 DiDisc，不应在 60 岁出现显著“额外跳变”。
- **养老金差异跳变**：用同一规格对养老金领取/金额做 DiDisc，确认 `post60×onechild` 不大；若不为 0，坚持使用双处理 2SLS。
- **样本定义稳健**：`onechild` 可替换为（a）“仅 1 个存活生物子女”（若 `xchildtype_*` 可识别），（b）剔除 `n_child_alive==0` 或子女信息全缺者。
- **金额变量截尾/稳健**：对 `money_from_children` 做 winsorize、分位数回归或 `IHS` 变换作稳健性。
- **操纵检验**：检查出生年月/年龄在断点处是否堆积（年龄以月为 running variable，理论上更难操纵，但仍应做 density check）。

## 7. 下一步（如果要我继续做）
1) 把 2018 的变量构造封装成一个可复用的 R 脚本（生成分析数据集 + 基础图 + 一阶/二阶回归表）。  
2) 把 DiDisc 与双处理 2SLS 两套结果做成一页 “table + figure”，并跑完稳健性（带宽/安慰剂/截尾）。  

