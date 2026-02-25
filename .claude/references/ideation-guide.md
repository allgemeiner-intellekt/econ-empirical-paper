# Ideation Guide — Research Idea Evaluation Framework

## Five-Dimension Scoring

Each research idea is evaluated on 5 dimensions. Use ✓ (strong), ⚠️ (concerns), or ✗ (fatal flaw) for each.

### 1. Novelty (★1-5)

Does this fill a genuine gap in the literature?

| Rating | Criteria |
|--------|----------|
| ✓ Strong | No existing causal study on this exact policy-outcome pair; research gap explicitly identified in prior work |
| ⚠️ Concerns | 1-2 existing studies but different outcome/method; incremental rather than new |
| ✗ Fatal | Well-studied policy with multiple existing DiD/RDD papers on same outcomes |

**How to check:** Search Google Scholar for "[policy name] [method]" and "[policy name] causal effect." Count papers published in the last 5 years.

### 2. Identification Credibility (★1-5)

Is the causal identification strategy convincing?

| Rating | Criteria |
|--------|----------|
| ✓ Strong | Clear exogenous variation; staggered adoption across 10+ states; 5+ years pre-treatment; no obvious confounders |
| ⚠️ Concerns | Fewer than 8 treated units; short pre-period (3-4 years); potential selection into treatment |
| ✗ Fatal | Treatment coincides with major confound (COVID, Great Recession); fewer than 3 pre-treatment periods; treatment is endogenous |

**Key checks:**
- Pre-treatment period ≥ 5 years for first cohort
- ≥ 8 treated units (states/counties)
- ≥ 5 never-treated or not-yet-treated controls
- No simultaneous policy changes confounding the treatment

### 3. Data Feasibility (★1-5)

Can we actually get the data needed?

| Rating | Criteria |
|--------|----------|
| ✓ Strong | Public API available (FRED, BLS, Census); no key required or key easily obtainable; state-year granularity sufficient |
| ⚠️ Concerns | Requires restricted-access data; API unreliable; only county-level available but need finer granularity |
| ✗ Fatal | Data doesn't exist at required granularity; behind paywall with no access; outcome variable not measured |

**Verified data sources (APEP standard):**
- BLS QCEW: employment, wages, establishments by state-quarter-industry (no key needed)
- Census ACS: demographics, commuting, income by state-year (key recommended)
- FRED: macro series (no key needed for basic access)

### 4. Outcome Alignment (★1-5)

Does the measured outcome actually capture the theoretical mechanism?

| Rating | Criteria |
|--------|----------|
| ✓ Strong | Direct outcome measure (e.g., healthcare employment for healthcare licensing reform) |
| ⚠️ Concerns | Proxy outcome; long causal chain between policy and measured variable |
| ✗ Fatal | Outcome cannot plausibly be affected by the policy; measurement is too noisy |

### 5. Policy Relevance (★1-5)

Is this question important for real-world policy?

| Rating | Criteria |
|--------|----------|
| ✓ Strong | Active policy debate; affects large population; results could inform ongoing legislation |
| ⚠️ Concerns | Historical policy with limited current relevance; small affected population |
| ✗ Fatal | Purely academic exercise with no policy implications |

---

## Fatal Flaw Checklist

Before pursuing any idea, verify NONE of these apply:

- [ ] **COVID confound**: Treatment period overlaps with 2020-2021 pandemic effects and cannot be separated
- [ ] **Pre-treatment period < 3 years**: Cannot credibly test parallel trends
- [ ] **Fewer than 5 treated units**: Insufficient variation for inference
- [ ] **No never-treated control**: All units eventually treated with no clean control group
- [ ] **Endogenous treatment timing**: States that adopt the policy are systematically different in ways correlated with the outcome
- [ ] **Data doesn't exist**: Required outcome variable not measured at necessary granularity
- [ ] **Well-studied question**: 3+ existing causal studies with same method and outcome

---

## Idea Template

Each idea should follow this structure:

```markdown
## Idea N: [Catchy Title: Descriptive Subtitle]

**Policy:** [Name], adopted by [X] US states between [year range]. [1-2 sentences on mechanism].
Specific adoption: [list cohorts with state counts and years].

**Outcome:** [Data source] — [specific variables] at [granularity], [year range].

**Identification:** [Method] using [estimator]. Treatment = [definition].
[X] distinct adoption cohorts, [Y] never-treated states.
Pre-treatment: [start]-[end] ([Z] years/quarters).

**Why it's novel:**
1. [Specific framing contribution]
2. [Specific empirical contribution]
3. [Citation to closest existing work + how this differs]
4. [Optional: explicit research gap citation]

**Feasibility check:**
- Variation: [count of treated units, cohorts, controls]. ✓/⚠️/✗
- Data: [source + accessibility]. ✓/⚠️/✗
- Pre-periods: [length]. ✓/⚠️/✗
- Not overstudied: [count of existing papers]. ✓/⚠️/✗
- Sample: [calculation of N]. ✓/⚠️/✗
```

---

## Example: Strong Idea (PURSUE)

From APEP paper apep_0236:

> **Idea 1: Licensing to Log In: The IMLC and Healthcare Supply Creation**
>
> - **Novelty ★★★★★**: Only 1 existing DiD paper (Deyo et al. 2023, focused on practice counts not employment). MOST Policy Initiative explicitly notes "little quantitative research."
> - **Identification ★★★★☆**: 42 treated states, 8 adoption cohorts, 7-8 never-treated. Pre-treatment 2012-2016 (5 years). Clean staggered adoption.
> - **Data ★★★★★**: BLS QCEW (no API key, state-quarter-industry). Census ACS (key available).
> - **Outcome ★★★★★**: Healthcare employment directly measures the mechanism (more licensed physicians → more healthcare jobs).
> - **Policy ★★★★★**: Active compact with ongoing state adoptions; directly informs interstate licensing reform debate.
>
> **Verdict: PURSUE** — Score 77/100

## Example: Rejected Idea (SKIP)

From APEP paper apep_0236:

> **Idea 3: PSYPACT and Mental Health Access**
>
> - **Novelty ★★★★☆**: No existing causal study — genuinely novel.
> - **Identification ★★☆☆☆**: Compact starts July 2020. Pre-treatment period is only 2 quarters. **FATAL.**
> - **Data ★★★☆☆**: QCEW accessible but mental health sub-industry codes may be suppressed.
> - **Outcome ★★★★☆**: Direct measure available.
> - **Policy ★★★★★**: Mental health crisis is first-order policy issue.
>
> **Verdict: SKIP** — Score 32/100. Fatal flaw: COVID confound + insufficient pre-treatment period.

---

## Ranking Output Format

After evaluating all 5 ideas, produce:

1. **Ranking table** (in `ideas.md`):

```markdown
| Idea | Novelty | Identification | Feasibility | Verdict |
|------|---------|---------------|-------------|---------|
| 1. [Title] | ★★★★★ | ★★★★☆ | ★★★★★ | **PURSUE** |
| 2. [Title] | ★★★☆☆ | ★★★★☆ | ★★★☆☆ | CONSIDER |
| 3. [Title] | ★★★★☆ | ★★☆☆☆ | ★★☆☆☆ | SKIP (reason) |
```

2. **JSON rankings** (in `ideas_ranked.json`):

```json
{
  "timestamp": "ISO-8601",
  "rankings": [
    {
      "rank": 1,
      "title": "Idea title",
      "score": 77,
      "recommendation": "PURSUE",
      "conditions": ["condition 1", "condition 2"]
    }
  ]
}
```

Use **conditional recommendations** when appropriate:
> "PURSUE (conditional on: (i) QCEW data available at required NAICS level, (ii) pre-2020 cohorts provide sufficient variation, (iii) no simultaneous federal policy change)"
