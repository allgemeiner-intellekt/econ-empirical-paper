# Grandchild Care and Female Labor Supply: Causal Feasibility Brief

## Research question
Does starting (or stopping) care of grandchildren reduce labor force participation of middle‑aged women in CHARLS?

## Data and key variables (CHARLS only)
- Waves: 2013, 2015, 2018 (panel).
- Outcome: `any_work` (agriculture + non‑farm, harmonized across waves).
- Treatment: `care_gc_bin` from `cf001` (care of grandchildren, binary).
- Controls: individual fixed effects, wave fixed effects; robustness adds parent‑care `cf004` (2013/2015) and `cf004_w4_*` (2018, aggregated).

## Identification strategy
Individual FE + wave FE:
```
any_work_it = alpha_i + lambda_t + beta1*care_it + beta2*(care_it*female_i) + e_it
```
Interpretation: `beta1` is the effect for men; `beta1 + beta2` is the effect for women.
Standard errors clustered at the individual level.

## Main FE results (age<=70, fixed sex/birth year by ID)
Source: `analysis/es_grandchild_care_step1.R`
- Baseline FE:
  - `care_gc_bin` = +0.0469 (p=0.002) for men
  - `care_gc_bin*female` = -0.0796 (p<0.001)
  - Female net effect: about -0.0327
- Women‑only FE:
  - All women: -0.0331 (p=0.028)
  - Women age<=60: -0.0516 (p=0.018)

## Robustness and placebo checks (key ones)
Source: `analysis/es_grandchild_care_step1.R`

1. Control for caring for parents (time‑varying)
   - Add parent care + interaction (with missing indicators).
   - `care_gc_bin*female` remains negative and significant (about -0.0788, p<0.001).
   - Interpretation: grandchild care effect is not absorbed by parent care.

2. Lead (placebo) test: future care predicting current work
   - Pooled lead model: `care_lead` positive (p=0.010), but interaction with female not significant.
   - Women‑only lead: `care_lead` not significant (p=0.439).
   - Interpretation: no evidence that women reduce work before they start caring.

3. Reverse‑causality check: current work predicting future care
   - `care_{t+1} ~ any_work_t` not significant in pooled or women‑only samples.
   - Interpretation: current employment does not predict future care status.

4. Late‑starter pretrend (care2015=0, treated if care2018=1)
   - Pretrend (2013->2015) interaction with female: not significant.
   - Post (2015->2018) interaction with female: not significant.
   - Interpretation: no detectable female pretrend, but limited power.

## What this implies for causal credibility
Strengths:
- Within‑person FE reduces time‑invariant confounding.
- Female effect is stable and negative across core specifications.
- Placebo and reverse‑causality diagnostics do not show clear violations for women.
- Parent‑care control does not attenuate the female effect.

Limitations:
- Only 3 waves; placebo/pretrend tests have limited power.
- Treatment is binary (care yes/no), which may mask intensity changes.
- Potential remaining time‑varying confounders (health shocks, child employment) not fully measured.

## Bottom line
For a reader familiar with causal inference, the FE design with multiple placebo checks supports a credible negative effect of grandchild care on female labor supply (about 3–5 p.p.), while acknowledging limited pretrend power and a coarse treatment measure. The evidence is reasonably defensible for a paper that is transparent about these constraints.
