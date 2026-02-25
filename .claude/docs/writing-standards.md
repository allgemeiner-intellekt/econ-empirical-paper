# Academic Writing Standards — AER/QJE Style

## Target Quality

All papers target top-5 economics journal standards: AER, QJE, Econometrica, JPE, REStud.

---

## Introduction Structure (3–4 pages)

Follow the **Hook → Gap → Contribution → Preview → Roadmap** structure:

1. **Opening hook** (1 paragraph): A policy-relevant fact, statistic, or puzzle that grabs attention
2. **The problem**: Why this matters for policy, welfare, or economic understanding
3. **Literature gap**: Cite 3–5 key papers; explicitly state what is missing
4. **This paper's contribution**: Numbered list (typically 3 points):
   - "(i) We provide the first causal estimates of..."
   - "(ii) We exploit staggered adoption across N states..."
   - "(iii) We test between competing mechanisms..."
5. **Preview of findings**: State the main result with exact numbers: "We find that X increases Y by Z% (SE = W)"
6. **Roadmap**: "The remainder of this paper proceeds as follows. Section 2 describes..."

---

## Quantitative Specificity

**NEVER use vague quantifiers. ALWAYS use exact numbers.**

| Bad | Good |
|-----|------|
| "Many states adopted the policy" | "42 states adopted the IMLC across 8 cohorts (2017–2024)" |
| "We find a significant effect" | "We estimate an ATT of 0.034 (SE = 0.012, p < 0.01)" |
| "The pre-trends look parallel" | "All 5 pre-treatment event-study coefficients are within 0.005 of zero (joint F = 0.82, p = 0.54)" |
| "A large sample" | "128,000 state-quarter-industry observations across 51 jurisdictions and 40 quarters" |
| "Results are robust" | "The ATT ranges from 0.028 to 0.041 across 8 alternative specifications (Table 3)" |

---

## Vague Language Ban

| Banned Phrase | Replacement Pattern |
|---------------|-------------------|
| "This may suggest..." | "The point estimate of 0.034 indicates..." |
| "There appears to be..." | "The coefficient of 0.021 (SE = 0.009) is statistically significant at the 5% level" |
| "Somewhat larger" | "2.3 times larger (0.041 vs 0.018)" |
| "Broadly consistent" | "Within one standard error of the baseline estimate (0.034 vs 0.031)" |
| "The evidence suggests" | "The event-study coefficients (Figure 3) show..." |

---

## Acronym Rule

Define every acronym on first use, then use the abbreviation consistently:

> "The Interstate Medical Licensure Compact (IMLC) was established in 2017. Since its creation, the IMLC has..."

---

## Abstract (~250 words)

Must include:
1. **Method**: "Using a staggered difference-in-differences design with the Callaway-Sant'Anna (2021) estimator..."
2. **Main finding**: Point estimate with confidence interval
3. **Sample**: N observations, time period, geographic scope
4. **Policy implication**: One specific sentence

---

## Section Length Guidelines

| Section | Pages | Key Requirement |
|---------|-------|----------------|
| Abstract | ~250 words | Method + main finding + CI |
| Introduction | 3–4 | Hook-gap-contribution-preview |
| Institutional Background | 2–3 | Specific dates, state counts |
| Data | 2–3 | Source details, summary stats table |
| Empirical Strategy | 3–4 | Estimating equation, threats |
| Results | 4–5 | Main + event study + heterogeneity |
| Robustness | 2–3 | All pre-registered checks |
| Discussion | 2–3 | Honest limitations |
| Conclusion | 1–2 | Policy implications |

**Minimum total: 25 pages** (including references, excluding appendix).

---

## Citation Style

- Use `natbib` with `aer` bibliography style
- In-text: `\citet{author2021}` for "Author (2021) finds..." and `\citep{author2021}` for "...consistent with prior work (Author, 2021)"
- Generate `references.bib` in BibTeX format
- Include DOI where available

---

## Table and Figure References

**Always use active references, never positional.**

| Bad | Good |
|-----|------|
| "The following table shows..." | "Table 1 reports summary statistics for..." |
| "As shown below" | "Figure 3 plots the event-study coefficients" |
| "See the table above" | "Column (3) of Table 2 presents..." |

---

## Results Reporting

- Report point estimate, standard error in parentheses, and significance stars
- Always state clustering level: "Standard errors clustered at the state level"
- For event studies: discuss pre-treatment coefficients explicitly
- Report null results honestly: "We find no statistically significant effect on X (β = 0.003, SE = 0.015)"

---

## Limitations Section

Must be **specific and honest**, not vague disclaimers.

| Bad | Good |
|-----|------|
| "This study has some limitations" | "Three limitations merit discussion" |
| "The data may have issues" | "State-level analysis cannot capture within-state heterogeneity in IMLC implementation intensity" |
| "Results should be interpreted with caution" | "Our estimates identify the average effect across adopting states, which may mask heterogeneity: early adopters (2017 cohort) may differ systematically from late adopters (2023 cohort)" |

---

## Voice and Tone

- **Introduction and Discussion**: Active voice preferred ("We find...", "We exploit...")
- **Methods section**: Passive voice acceptable ("Treatment is defined as...")
- **Results**: Mix of active and passive, prioritize clarity
- Avoid first-person outside of contribution statements
- Professional, precise, confident but not overreaching
