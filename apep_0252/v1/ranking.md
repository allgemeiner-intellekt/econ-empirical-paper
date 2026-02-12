# Research Idea Ranking

**Generated:** 2026-02-12T14:53:59.190736
**Model:** openai/gpt-5.2 (reasoning: high)
**Tokens:** 7298

---

### Rankings

**#1: State Prohibition and the Destruction of the German-American Brewing Elite (1870–1920)**
- **Score: 74/100**
- **Strengths:** Strongly original question with a plausible mechanism (targeted destruction of an ethnic-industry elite) and excellent microdata scale (full-count census). Treatment has many adopting states, enabling modern staggered DiD/event-study methods and credible heterogeneity/DDD strategies.
- **Concerns:** Pre-trend testing is inherently limited by decennial data (and the missing 1890 census), and WWI-era anti-German sentiment overlaps with late adopters in ways that may not be fully purged even with DDD. Also, the outcome can easily be diluted/misaligned if defined too broadly (e.g., all Germans rather than brewery-linked Germans).
- **Novelty Assessment:** **High.** Prohibition is heavily studied, but I’m not aware of a well-identified economics paper on *ethnic elite destruction/occupational downgrading* via prohibition using full-count census microdata and a DDD channel design.
- **DiD Assessment:**
  - **Pre-treatment periods:** **Marginal** (effectively 3 pre-waves for 1907+ adopters; large gaps; limited dynamic testing)
  - **Selection into treatment:** **Marginal** (temperance politics likely correlated with underlying social trends; not plausibly exogenous)
  - **Comparison group:** **Marginal** (never-/later-treated states exist, but they differ systematically; needs careful weighting/matching and region trends)
  - **Treatment clusters:** **Strong** (~25–30 adopters in main 1907–1919 window)
  - **Concurrent policies:** **Marginal → Weak risk** (WWI/anti-German policies 1917–1919 are a first-order confound; **mitigation:** restrict main analysis to adoption ≤1916 and show robustness)
  - **Outcome-Policy Alignment:** **Strong (if outcome is brewery-linked)**: prohibition directly collapses brewing production/employment; occupational downgrading among brewers/brewery owners/managers is tightly connected to the policy mechanism. **Weak if** the outcome is “all Germans’ OCCSCORE” without industry/occupation targeting.
  - **Data-Outcome Timing:** **Marginal** (census is as-of **April 1**; state prohibition effective dates vary—often mid-year—so “first treated census” exposure differs by state; needs an exposure measure like “law in force ≥12 months before April 1”)
  - **Outcome Dilution:** **Strong (conditional)** if the estimand is defined on brewers/brewery industry workers or high-exposure German subgroups; **Weak** if averaging over all German workers (most unaffected).
- **Recommendation:** **PURSUE (conditional on: (i) primary specification restricts to adoption ≤1916 or explicitly models WWI shocks; (ii) treatment exposure is aligned to April 1 census timing; (iii) main outcomes are brewery-linked to avoid dilution; (iv) show pre-trend/placebo checks using non-brewing Germans and other ethnic groups).**

---

**#2: Compulsory Schooling Laws and Elite Occupational Persistence (1852–1918)**
- **Score: 61/100**
- **Strengths:** Very feasible data/treatment coding (well-documented dates; many states; long horizon) and a genuinely interesting *new outcome* (elite persistence) even though the policy is classic. High statistical power is likely.
- **Concerns:** This policy is extremely studied and adoption is not plausibly exogenous—often bundled with broader Progressive Era reforms and industrialization/child labor changes—so a DiD on elite persistence risks being “compulsory schooling paper #101” with fragile identification unless you build a convincing design around confounds and timing.
- **Novelty Assessment:** **Marginal.** The *outcome* is novel, but the *policy* is among the most mined in applied micro/econ history; referees will demand unusually strong design/robustness.
- **DiD Assessment:**
  - **Pre-treatment periods:** **Strong** (for many states, multiple pre-census waves exist; enough to test leads at least in decennial form)
  - **Selection into treatment:** **Marginal** (adoption likely responds to underlying modernization trends; not a clean mandate shock)
  - **Comparison group:** **Marginal** (late adopters—often Southern—differ structurally; needs region-specific trends/stacked DiD and careful comparability checks)
  - **Treatment clusters:** **Strong** (≈48 states + DC over time)
  - **Concurrent policies:** **Marginal** (child labor laws, compulsory vaccination, Jim Crow schooling institutions, etc.; must show robustness or incorporate controls/alternative comparisons)
  - **Outcome-Policy Alignment:** **Marginal**: schooling laws affect children’s human capital, which can affect mobility/persistence, but the mapping from “attendance law” → “adult occupational rank persistence” is long-lag and mediated.
  - **Data-Outcome Timing:** **Strong** (adult occupational outcomes observed many years after law passage; decennial census reduces partial-year exposure issues)
  - **Outcome Dilution:** **Marginal** because the proposed sample (co-resident father-son pairs) is selective and not the full affected population; also the law affects cohorts, not everyone in the cross-section.
- **Recommendation:** **CONSIDER (upgrade to PURSUE if you shift to cohort-based exposure—state × birth cohort—and/or linked individuals across censuses rather than only co-resident pairs; and pre-specify robustness to Progressive Era co-movements).**

---

**#3: State Inheritance Tax Adoption and Intergenerational Elite Persistence (1885–1916)**
- **Score: 47/100**
- **Strengths:** High conceptual novelty and direct policy relevance to modern debates on wealth taxation and dynastic persistence. Staggered adoption could, in principle, support credible event studies.
- **Concerns:** Two major feasibility/identification threats: (i) you currently don’t have verified, research-ready adoption dates; and (ii) inheritance taxes hit a tiny share of decedents/wealth, so using broad occupational persistence outcomes (especially via co-resident father-son pairs) is likely **severely diluted** and underpowered, with adoption timing plausibly endogenous to inequality/politics.
- **Novelty Assessment:** **High.** Early state inheritance/estate tax adoption is not a saturated DiD topic in economics, especially not tied to intergenerational persistence.
- **DiD Assessment:**
  - **Pre-treatment periods:** **Weak** as proposed (with only 1880/1900/1910/1920, many early adopters have ≤1 pre period; you’d have to restrict to later adopters, losing variation)
  - **Selection into treatment:** **Marginal → Weak risk** (adoption likely tied to fiscal needs and inequality/political economy trends correlated with mobility)
  - **Comparison group:** **Weak** by late period (by 1916 only ~5 never-treated states remain; comparisons become thin and non-comparable)
  - **Treatment clusters:** **Strong** in theory (many adopters), but effective variation collapses late due to near-universal adoption
  - **Concurrent policies:** **Marginal** (Progressive Era reforms coincide; hard to isolate)
  - **Outcome-Policy Alignment:** **Marginal**: inheritance tax is a wealth-at-death policy; OCCSCORE persistence is an indirect proxy for dynastic wealth transmission.
  - **Data-Outcome Timing:** **Strong** (adult outcomes observed well after policy adoption; minimal partial-year issues)
  - **Outcome Dilution:** **Weak** (tax affects a small top-wealth slice; co-resident father-son OCCSCORE persistence mostly reflects non-estate-tax-exposed families).
- **Recommendation:** **SKIP (unless redesigned).** A viable redesign would (a) obtain full statutory parameters (rates/exemptions) and (b) link to wealth-at-death/probate/elite surname measures or top-tail outcomes (e.g., top 1% occupation/business ownership), otherwise dilution + weak pre-trends will dominate.

---

**#4: Civil Service Reform and the Decline of Patronage Elites (1883–1920)**
- **Score: 33/100**
- **Strengths:** Potentially important and under-studied distributional question (who gets government jobs when merit systems arrive). If measurement were clean, this could be influential.
- **Concerns:** As written, it has multiple near-dealbreakers: unclear/unfinished treatment-date dataset, likely small/clustered early adoption, and serious measurement risk in identifying “government workers” and their occupational standing consistently in pre-1940 census coding. Without clean treatment timing and outcome measurement, DiD won’t be credible.
- **Novelty Assessment:** **Moderate-High.** There is political science work, but less clean causal micro evidence on composition effects; still, novelty can’t compensate for weak feasibility.
- **DiD Assessment:**
  - **Pre-treatment periods:** **Marginal** (decennial waves exist, but only helpful if policy dates are precise)
  - **Selection into treatment:** **Marginal → Weak risk** (reform likely adopted in response to corruption/patronage scandals and governance problems correlated with outcomes)
  - **Comparison group:** **Marginal** (reforming states differ; may be urban/industrial)
  - **Treatment clusters:** **Weak** for 1883–1920 window (early adopters are few; inference fragile)
  - **Concurrent policies:** **Marginal** (urbanization and other governance reforms coincide)
  - **Outcome-Policy Alignment:** **Weak** if “government worker” cannot be cleanly measured; then the outcome is not actually capturing merit reform’s target margin.
  - **Data-Outcome Timing:** **Marginal** (policy effective dates vs April 1 census measurement could misclassify early years; solvable only after date reconstruction)
  - **Outcome Dilution:** **Marginal → Weak** depending on whether you can isolate the *covered* civil service workforce (many government jobs may be exempt initially).
- **Recommendation:** **SKIP** (unless you first build/validate a high-quality state reform statute dataset and demonstrate credible pre-1920 measurement of government sector employment/occupation in IPUMS).

---

### Summary

This is an unusually creative batch in terms of questions, but three of the four proposals have serious design fragility stemming from (i) limited pre-trend leverage in decennial historical data, (ii) endogenous Progressive Era policy bundling, and/or (iii) outcome dilution/measurement. **Idea #1 is the best bet** because it combines high novelty with excellent data scale and a mechanism that can be made tight (brewery-linked Germans), **provided** you proactively solve WWI overlap and treatment-exposure timing. Ideas #2–#4 are “possible” only with substantial redesign; #3 and #4 in their current forms trip the checklist (notably dilution/comparison group/measurement) and should not be prioritized.