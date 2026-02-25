---
name: pre-analysis-plan
description: >-
  Generate a detailed pre-analysis plan and lock it with a SHA-256 hash
  to prevent post-hoc specification changes.
disable-model-invocation: true
---

# Pre-Analysis Plan — Generate and Lock Research Plan

You generate a detailed pre-analysis plan that prevents post-hoc specification changes via SHA-256 hash locking.

## Input

One of:
- Selected idea from `/ideate` output (`ideas.md`, `ideas_ranked.json`)
- User-provided research question and design details
- `research_potential.md` from `/explore-data` for data context

## Required Sections

### 1. Title
Final paper title in "catchy: descriptive" format.

### 2. Research Question
One clear sentence ending with a question mark.

### 3. Motivation (1 paragraph)
- Policy context and importance
- Key prior work (2–3 citations)
- The specific gap this paper fills

### 4. Identification Strategy

**Design name and citation** (e.g., "Staggered DiD using Callaway-Sant'Anna (2021)")

**Treatment definition with complete coding:**
List ALL units with treatment status. For US state-level:
```
| State FIPS | Abbreviation | State Name | Treatment Year |
|-----------|-------------|-----------|---------------|
| "01" | AL | Alabama | 2017 |
| "02" | AK | Alaska | 0 |  ← never treated
| ... (all 51 jurisdictions) |
```

For non-US or other units: equivalent complete listing.

**Control group definition**: Never-treated, not-yet-treated, or both.

**Estimating equation in LaTeX**:
```latex
$$Y_{st} = \alpha_s + \gamma_t + \sum_g \sum_t \beta_{g,t} \cdot \mathbb{1}[G_s = g] \cdot \mathbb{1}[t \geq g] + \varepsilon_{st}$$
```

**Variable definitions**: Define every symbol ($Y_{st}$, $\alpha_s$, $\gamma_t$, $G_s$, $\beta_{g,t}$).

### 5. Power Assessment

| Dimension | Count |
|-----------|-------|
| Pre-treatment periods | N |
| Post-treatment periods | N |
| Treated clusters | N |
| Never-treated clusters | N |
| Total observations (units × periods) | N |

### 6. Expected Effects and Mechanisms

**Primary hypotheses** (numbered):
1. H1: [Policy] increases/decreases [outcome] by [expected magnitude and direction]
2. H2: ...

**Mechanism tests**: How to distinguish competing explanations.

**Heterogeneity predictions** (derived from theory, NOT data-driven):
- By [subgroup 1]: expect larger/smaller because [theoretical reason]
- By [subgroup 2]: ...

### 7. Robustness Checks (8–10 numbered)

Must include a mix from all three layers:
- **Design layer**: Alternative estimator, alternative control group
- **Sample layer**: Exclude subsets, restrict time period
- **Specification layer**: Alternative FE, different outcome transformation

Example list:
1. Event study with pre-treatment coefficients (parallel trends test)
2. Placebo test on [unrelated outcome]
3. Alternative estimator: [Sun-Abraham / imputation / other]
4. Not-yet-treated as control group
5. Exclude COVID years (2020–2021)
6. Bacon decomposition of TWFE
7. Sub-group analysis: [specific subgroups]
8. Pre-2020 cohorts only
9. [Method-specific check]
10. [Additional check]

### 8. Data Sources Table

| Source | Variables | Granularity | Years | Access |
|--------|-----------|-------------|-------|--------|
| [Name] | [vars] | State × quarter | 2012–2024 | Public API |

## SHA-256 Lock

After generating `initial_plan.md`, compute the SHA-256 hash:

```bash
shasum -a 256 initial_plan.md
```

Save `pre_analysis.md`:
```markdown
# Pre-Analysis Plan Lock

**Plan file:** initial_plan.md
**SHA-256:** [hash]
**Locked at:** [ISO-8601 timestamp]

Any deviation from this plan must be:
1. Explicitly documented in deviations.json
2. Justified with a reason (e.g., "Referee requested additional test")
3. Flagged as exploratory in the paper
```

## Output

- `initial_plan.md` — Full pre-analysis plan
- `pre_analysis.md` — SHA-256 lock document

## After Output

Show the user the plan summary and ask for approval before locking.

Tell the user: "Pre-analysis plan locked. Run `/generate-code` to generate the R analysis pipeline."
