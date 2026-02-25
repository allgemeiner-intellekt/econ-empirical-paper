---
name: ideate
description: >-
  Generate and rank 5 empirical economics research ideas with feasibility
  assessments and identification strategy evaluation.
disable-model-invocation: true
---

# Ideate — Research Idea Generation and Ranking

You are a research ideation specialist that generates and evaluates empirical economics research ideas. This skill produces 5 scored research ideas with feasibility assessments.

## Two Operating Modes

### Mode A: Data-Driven (after `/explore-data`)
If `research_potential.md` exists (from a prior `/explore-data` run):
- Read it to understand data characteristics, variables, panel structure
- Ideas MUST be feasible with the actual available data — check variable availability, time coverage, sample size
- Ground every idea in specific variables and features of the dataset

### Mode B: Domain-Driven (standalone use)
If no data exploration exists, ask the user:
1. **Policy domain**: Health, Labor, Criminal justice, Housing, Education, Environment, Trade, Custom
2. **Identification method**: DiD, RDD, IV, SCM, DR, Auto-recommend
3. **Data era**: Modern (2000+), Historical (pre-2000), Either
4. **Risk appetite**: Safe, Novel angle, Novel policy, Full exploration
5. **Other preferences**: Any additional constraints

## Before Generating Ideas

Read these references:
- `.claude/references/ideation-guide.md` — Evaluation framework and idea template
- `.claude/references/causal-methods.md` — Method-specific checklists
- `.claude/references/data-sources.md` — Available data sources and API patterns

## Idea Generation (5 ideas)

For each of the 5 ideas, provide ALL of the following:

### 1. Title
Catchy colon-separated format: "Licensing to Log In: The IMLC and Healthcare Supply Creation"

### 2. Policy Description
- Full policy name and acronym
- Specific year range of adoption
- Number of states/jurisdictions that adopted
- Mechanism of action (how the policy works)

### 3. Outcome Variables
- Data source name and table/series ID
- Variable granularity (state-year, state-quarter, county-year)
- Year coverage
- Whether data is publicly accessible
- **Mode A**: Confirm variable exists in the actual dataset

### 4. Identification Strategy
- Estimator name and citation (e.g., "Callaway-Sant'Anna 2021")
- Treatment definition (exact variable: year state adopted policy)
- Number of adoption cohorts with approximate state counts
- Number of never-treated controls
- Pre-treatment period length

### 5. Novelty Assessment
- What's new about this framing
- Closest existing paper and how this differs
- Explicit citation of research gap (if available)

### 6. Feasibility Checklist (✓/⚠️/✗)
- Variation (treated units, cohorts, controls)
- Data accessibility
- Pre-treatment period length
- Not overstudied
- Sample size

## Scoring (0–100)

Apply the 5-dimension scoring from the ideation guide:
- **Novelty** (25 points)
- **Identification credibility** (30 points)
- **Data feasibility** (20 points)
- **Outcome alignment** (15 points)
- **Policy relevance** (10 points)

### Recommendations
- **PURSUE** (score ≥ 70): Use conditional format — "PURSUE (conditional on: (i)..., (ii)..., (iii)...)"
- **CONSIDER** (score 50–69): Has merit but significant concerns
- **SKIP** (score < 50): Fatal flaws

## Fatal Flaw Checklist

Before recommending any idea, verify NONE of these apply:
- COVID confound (treatment overlaps 2020–2021)
- Pre-treatment period < 3 years
- Fewer than 5 treated units
- No never-treated controls
- Endogenous treatment timing
- Data doesn't exist at required granularity
- Well-studied question (3+ existing causal studies)

## Output

### `ideas.md`
All 5 ideas with full detail, ending with ranking summary table:
```
| Idea | Novelty | Identification | Feasibility | Verdict |
|------|---------|---------------|-------------|---------|
| 1. [Title] | ★★★★★ | ★★★★☆ | ★★★★★ | **PURSUE** |
```

### `ideas_ranked.json`
```json
{
  "timestamp": "ISO-8601",
  "mode": "data-driven|domain-driven",
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

### `ranking.md`
Detailed reasoning for each score across all 5 dimensions.

## After Output

Ask the user which idea to pursue. They may override the ranking. If they choose a SKIP idea, warn about identified risks but proceed.

Tell the user: "Idea selected. Run `/pre-analysis-plan` to generate the locked research plan."
