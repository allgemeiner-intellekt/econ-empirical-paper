# Causal Inference Methods — Evaluation Checklists and Code Patterns

## DiD (Difference-in-Differences)

### When to Use
Policy adopted by different units (states, counties) at different times. Need clear treatment/control comparison with pre/post periods.

### 8-Dimension Evaluation Checklist

| # | Dimension | ✓ Pass | ✗ Fail |
|---|-----------|--------|--------|
| 1 | **Pre-treatment period** | ≥5 years for first cohort | <3 years |
| 2 | **Treatment group selection** | Exogenous timing (legislative process, federal pressure) | States self-select based on expected outcomes |
| 3 | **Control group quality** | 5+ never-treated states with similar pre-trends | <3 controls or systematically different |
| 4 | **Cluster count** | ≥20 clusters for asymptotic inference | <10 clusters (use wild bootstrap) |
| 5 | **Concurrent confounders** | No major simultaneous policy changes | COVID, recession, or other reform coincides |
| 6 | **Outcome alignment** | Treatment directly affects measured outcome | Long causal chain, proxy measures |
| 7 | **Time alignment** | Treatment date precisely known; annual/quarterly data matches | Ambiguous rollout, fuzzy implementation |
| 8 | **Effect dilution** | Treatment applies to meaningful share of population | Policy affects tiny fraction of units |

### Estimators

**Callaway-Sant'Anna (2021)** — Default for staggered adoption:
- Handles heterogeneous treatment effects across cohorts
- Group-time ATTs → aggregate to event study or overall ATT
- R: `did::att_gt()` → `did::aggte()`

**Sun-Abraham (2021)** — Alternative heterogeneity-robust estimator:
- Interaction-weighted estimator
- R: `fixest::feols()` with `sunab(first_treat, year)`

**TWFE (Two-Way Fixed Effects)** — Report for comparison but flag as potentially biased:
- Known issues with staggered adoption (negative weights)
- R: `fixest::feols(y ~ treated | unit + time)`

**Borusyak-Jaravel-Spiess (2024)** — Imputation estimator:
- Imputes counterfactual outcomes from untreated observations
- R: `didimputation::did_imputation()`

### Required Robustness Checks
1. Event study plot (pre-treatment coefficients ≈ 0)
2. Placebo test on unrelated outcome
3. Bacon decomposition (identify problematic 2×2 comparisons)
4. Alternative control group (not-yet-treated vs never-treated)
5. Exclude COVID years (if applicable)
6. Alternative estimator (Sun-Abraham or imputation)

### Code Pattern (Callaway-Sant'Anna)

```r
# Group-time ATTs
cs_result <- did::att_gt(
  yname  = "log_outcome",
  tname  = "year",
  idname = "unit_id",
  gname  = "first_treat",     # 0 = never treated
  data   = panel,
  control_group = "nevertreated",
  base_period = "universal"
)

# Overall ATT
agg_overall <- did::aggte(cs_result, type = "simple")

# Event study
agg_es <- did::aggte(cs_result, type = "dynamic", min_e = -5, max_e = 6)

# Cohort-specific ATTs
agg_cohort <- did::aggte(cs_result, type = "group")
```

---

## RDD (Regression Discontinuity Design)

### When to Use
Treatment assigned based on a continuous running variable crossing a known threshold (age cutoffs, test score thresholds, population cutoffs for policy eligibility).

### Evaluation Checklist

| # | Dimension | ✓ Pass | ✗ Fail |
|---|-----------|--------|--------|
| 1 | **Cutoff clarity** | Sharp, legally defined threshold | Fuzzy or ambiguous cutoff |
| 2 | **Manipulation test** | McCrary density test passes (no bunching at cutoff) | Evidence of sorting around cutoff |
| 3 | **Bandwidth selection** | MSE-optimal bandwidth (Calonico-Cattaneo-Titiunik) | Arbitrary bandwidth choice |
| 4 | **Balance test** | Pre-determined covariates smooth through cutoff | Discontinuities in covariates at cutoff |
| 5 | **Placebo cutoffs** | No effect at non-cutoff thresholds | Spurious effects at arbitrary points |
| 6 | **Functional form** | Results robust to polynomial order (linear preferred) | Sensitive to polynomial degree |

### Sharp vs Fuzzy RDD
- **Sharp**: Treatment probability jumps from 0 to 1 at cutoff
- **Fuzzy**: Treatment probability jumps but not from 0 to 1 (use as IV)

### R Packages
- `rdrobust`: MSE-optimal bandwidth, robust bias-corrected inference
- `rddensity`: McCrary/Cattaneo-Jansson-Ma manipulation test
- `rdlocrand`: Randomization inference near cutoff

### Code Pattern

```r
# Sharp RDD with optimal bandwidth
rd_result <- rdrobust::rdrobust(
  y = data$outcome,
  x = data$running_var,
  c = cutoff_value,
  kernel = "triangular",
  bwselect = "mserd"
)
summary(rd_result)

# Manipulation test
density_test <- rddensity::rddensity(data$running_var, c = cutoff_value)
summary(density_test)

# Placebo cutoffs
placebo_cutoffs <- c(cutoff - 5, cutoff - 2, cutoff + 2, cutoff + 5)
```

---

## IV (Instrumental Variables)

### When to Use
Treatment is endogenous; need an instrument that affects the outcome only through its effect on the treatment (exclusion restriction).

### Evaluation Checklist

| # | Dimension | ✓ Pass | ✗ Fail |
|---|-----------|--------|--------|
| 1 | **Relevance** | First-stage F-statistic ≥ 10 (Stock-Yogo) | Weak instrument (F < 10) |
| 2 | **Exclusion restriction** | Instrument affects outcome only through treatment | Plausible direct effect of instrument on outcome |
| 3 | **Exogeneity** | Instrument uncorrelated with error term | Instrument correlated with omitted variables |
| 4 | **Monotonicity** | Instrument shifts treatment in same direction for all | Defiers present |
| 5 | **Overidentification** | Hansen J-test passes (if multiple instruments) | Rejected overidentification test |
| 6 | **LATE interpretation** | Complier population is policy-relevant | Compliers are a tiny/unusual subpopulation |

### Estimators
- **2SLS**: Standard two-stage least squares
- **LIML**: Limited information maximum likelihood (better with weak instruments)
- **Anderson-Rubin**: Robust to weak instruments

### R Packages
- `fixest::feols()`: IV with fixed effects via `| endogenous ~ instrument`
- `ivreg::ivreg()`: Standard 2SLS
- `ivpack`: Weak instrument diagnostics

### Code Pattern

```r
# 2SLS with fixed effects
iv_result <- fixest::feols(
  outcome ~ controls | unit_fe + time_fe | endogenous ~ instrument,
  data = panel,
  cluster = ~unit_id
)

# First-stage F-statistic
fitstat(iv_result, type = "ivf")

# Reduced form
rf <- fixest::feols(outcome ~ instrument + controls | unit_fe + time_fe,
                    data = panel, cluster = ~unit_id)
```

---

## SCM (Synthetic Control Method)

### When to Use
Single or few treated units; want to construct a counterfactual from a weighted combination of untreated units. Classic application: one state/country adopts a policy.

### Evaluation Checklist

| # | Dimension | ✓ Pass | ✗ Fail |
|---|-----------|--------|--------|
| 1 | **Donor pool** | 10+ potential control units | <5 donors |
| 2 | **Pre-treatment fit** | RMSPE < 5% of pre-treatment mean | Poor pre-treatment fit |
| 3 | **Placebo tests** | Treated unit's effect stands out in permutation distribution | Many donors show similar "effects" |
| 4 | **RMSPE ratio** | Post/pre RMSPE ratio in top 10% of permutation distribution | Ratio not extreme |
| 5 | **Weights** | No single donor dominates (weight > 0.5) | One donor gets >80% weight |
| 6 | **Pre-treatment periods** | ≥ post-treatment periods | Very short pre-period |

### R Packages
- `Synth`: Original Abadie-Diamond-Hainmueller
- `gsynth`: Generalized synthetic control (multiple treated units, factor model)
- `augsynth`: Augmented SCM with ridge regularization

### Code Pattern

```r
# Standard SCM
synth_result <- Synth::synth(
  dataprep.out = Synth::dataprep(
    foo = panel,
    predictors = c("predictor1", "predictor2"),
    predictors.op = "mean",
    dependent = "outcome",
    unit.variable = "unit_id",
    time.variable = "year",
    treatment.identifier = treated_unit_id,
    controls.identifier = control_ids,
    time.predictors.prior = pre_years,
    time.optimize.ssr = pre_years,
    time.plot = all_years
  )
)

# Generalized SCM (multiple treated units)
gsynth_result <- gsynth::gsynth(
  outcome ~ treated,
  data = panel,
  index = c("unit_id", "year"),
  force = "two-way",
  se = TRUE,
  nboots = 1000
)
```

---

## DR (Doubly Robust / AIPW)

### When to Use
Observational study where treatment is not randomly assigned; want robustness to misspecification of either the propensity score model or the outcome model.

### Evaluation Checklist

| # | Dimension | ✓ Pass | ✗ Fail |
|---|-----------|--------|--------|
| 1 | **Propensity score** | Logit/probit with good balance post-weighting | Extreme propensity scores (near 0 or 1) |
| 2 | **Outcome model** | Reasonable specification (linear, flexible) | Severely misspecified |
| 3 | **Common support** | Overlap in propensity scores between treated/control | Large regions of no overlap |
| 4 | **Balance** | Standardized differences < 0.1 after weighting | Persistent imbalance |
| 5 | **Sensitivity** | Results robust to adding omitted variables | Large sensitivity parameter needed |

### R Packages
- `DRDID`: Doubly robust DiD (Sant'Anna-Zhao 2020)
- `did`: Callaway-Sant'Anna with DR option (`est_method = "dr"`)

### Code Pattern

```r
# DR DiD (Sant'Anna-Zhao)
dr_result <- DRDID::drdid(
  yname = "outcome",
  tname = "post",
  idname = "unit_id",
  dname = "treated",
  xformla = ~ covariate1 + covariate2,
  data = panel
)

# CS DiD with doubly robust estimation
cs_dr <- did::att_gt(
  yname = "outcome",
  tname = "year",
  idname = "unit_id",
  gname = "first_treat",
  xformla = ~ covariate1 + covariate2,
  est_method = "dr",
  data = panel,
  control_group = "nevertreated"
)
```

---

## LP-IV (Local Projections with Instrumental Variables)

### When to Use
Estimating dynamic causal effects (impulse response functions) when treatment is endogenous. Common in macroeconomics and monetary policy analysis.

### Evaluation Checklist

| # | Dimension | ✓ Pass | ✗ Fail |
|---|-----------|--------|--------|
| 1 | **Instrument strength** | F-stat ≥ 10 at each horizon | Weak instrument at some horizons |
| 2 | **IRF completeness** | Response shown for sufficient horizons (8-20 periods) | Too few horizons |
| 3 | **HAC standard errors** | Newey-West or Driscoll-Kraay for serial correlation | OLS standard errors |
| 4 | **Confidence intervals** | 90% CI shown; width assessed for informativeness | Only point estimates |

### R Packages
- `lpirfs`: Local projections with IV
- `fixest`: Manual LP estimation with `feols()`

### Code Pattern

```r
# Local projections with IV
lp_result <- lpirfs::lp_lin_iv(
  endog_data = data$outcome_leads,      # Matrix of h-step-ahead outcomes
  lags_endog_lin = 4,
  shock = data$instrument,
  instrum = data$instrument,
  confint = 1.96,
  hor = 20
)

# Manual LP with fixest
horizons <- 0:12
lp_coefs <- map_dfr(horizons, function(h) {
  fml <- as.formula(paste0("lead(outcome, ", h, ") ~ controls | fe | treatment ~ instrument"))
  m <- feols(fml, data = panel, cluster = ~unit_id)
  tibble(horizon = h, coef = coef(m)["fit_treatment"], se = se(m)["fit_treatment"])
})
```

---

## Method Selection Decision Tree

```
Is treatment assigned by a cutoff on a running variable?
├── YES → RDD (sharp or fuzzy)
└── NO
    Is treatment staggered across units over time?
    ├── YES → DiD (Callaway-Sant'Anna for staggered)
    │   Only one or few treated units?
    │   └── YES → SCM (synthetic control)
    └── NO
        Is treatment endogenous?
        ├── YES → Do you have a valid instrument?
        │   ├── YES → IV (2SLS)
        │   │   Need dynamic effects? → LP-IV
        │   └── NO → DR (doubly robust) if strong covariates
        └── NO → Standard DiD or panel methods
```
