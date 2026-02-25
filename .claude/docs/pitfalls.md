# Common Pitfalls — Known Issues and How to Avoid Them

## Data Type Pitfalls

### FIPS Codes as Numeric
**Problem**: Converting FIPS codes to numeric drops leading zeros. Alabama (`"01"`) becomes `1`, making joins fail.
**Fix**: Always store as character: `state_fips = "01"`. Use `sprintf("%02d", x)` if converting from numeric.
**Detection**: Search for `as.numeric` or `as.integer` near any variable with "fips" in the name.

### never-treated Coding
**Problem**: The `did` package requires `first_treat = 0` for never-treated units. Using `NA`, `Inf`, or `9999` causes silent errors or crashes.
**Fix**: Always set `treat_year = 0` in the treatment `tribble()` for never-treated states.
**Detection**: Check `unique(panel$first_treat)` — should include 0, not NA.

### log(0) = -Inf
**Problem**: `log(0)` returns `-Inf`, which propagates through regressions silently or causes estimation failure.
**Fix**: Always use `log(x + 1)` or `log1p(x)`.
**Detection**: Search for `log(` without `+ 1` in the argument.

---

## Data Source Pitfalls

### ACS 2020 1-Year Data Missing
**Problem**: The Census Bureau did not release 2020 1-year ACS estimates due to COVID-19 data collection disruptions.
**Fix**: Skip 2020 in ACS year loops: `setdiff(2014:2023, 2020)`. Use 2020 5-year ACS if needed (different population threshold: 65,000 vs all areas).
**Detection**: Check if year range includes 2020 when calling ACS API.

### COVID-19 2020 Disruption
**Problem**: 2020–2021 data is confounded by pandemic effects across virtually all economic outcomes.
**Fix**: (1) Exclude COVID years as a robustness check, (2) include year-specific controls for 2020–2021, (3) consider pre-2020 cohorts only.
**Detection**: If treatment timing overlaps with 2020, flag as potential confound.

### BLS QCEW Suppressed Cells
**Problem**: BLS suppresses employment/wage data for cells with few establishments (privacy protection). These appear as blank or "0" rather than true zeros.
**Fix**: Check for implausible zeros in industry-specific data. Filter using `disclosure_code` field if available.

### Census API Rate Limits
**Problem**: Census API has undocumented rate limits. Rapid sequential calls may get HTTP 429 or silently return errors.
**Fix**: `Sys.sleep(2)` between Census API calls (more conservative than BLS). Use API key.

---

## Panel Construction Pitfalls

### Merge Row Explosion
**Problem**: A many-to-many join silently creates duplicate rows, inflating sample size and deflating standard errors.
**Fix**: Always check row count before and after every join:
```r
n_before <- nrow(df)
df <- df %>% left_join(other, by = "key")
n_after <- nrow(df)
cat(sprintf("Join: %d → %d rows\n", n_before, n_after))
```

### Unbalanced Panels
**Problem**: DiD estimators assume panel structure. Missing unit-period observations can bias results if non-random.
**Fix**: Check balance with `table(panel$year)` and `panel %>% count(unit_id) %>% count(n)`. Report attrition statistics.

### Time Alignment
**Problem**: Annual treatment dates in quarterly data — which quarter counts as "treated"? Mid-year enactment treated differently by Q1 vs Q3.
**Fix**: Document treatment timing precisely. For staggered DiD, use the first full period after enactment.

---

## Estimation Pitfalls

### Negative Weights in TWFE
**Problem**: Two-way fixed effects with staggered adoption produces biased estimates due to negative weights on some 2×2 comparisons.
**Fix**: Use heterogeneity-robust estimators: Callaway-Sant'Anna (2021), Sun-Abraham (2021), or Borusyak-Jaravel-Spiess (2024). Report TWFE for comparison only.
**Detection**: Run Bacon decomposition (`bacondecomp`) to visualize the problem.

### Cluster Count Too Low
**Problem**: Fewer than ~20 clusters → asymptotic cluster-robust SEs are unreliable.
**Fix**: If clusters < 20, use wild cluster bootstrap (`fwildclusterboot`). Report both.
**Detection**: Check `n_distinct(panel$cluster_var)`.

### Selection into Treatment
**Problem**: States that adopt policies may be systematically different from non-adopters in ways correlated with outcomes.
**Fix**: (1) Test for pre-treatment differences, (2) discuss legislative history for exogeneity, (3) use matching or inverse propensity weighting as robustness.

---

## Local Data File Pitfalls

### Stata .dta Files
**Problem**: Variable labels are stored as attributes, not visible in `head()` or `str()`.
**Fix**: Use `haven::read_dta()`. Access labels with `attr(df$var, "label")`. Convert value labels with `haven::as_factor(df$var)`.
**Detection**: Check `class(df$var)` — labelled variables show `haven_labelled`.

### SPSS .sav Files
**Problem**: Similar to Stata — labels stored in metadata, value labels need conversion.
**Fix**: Use `haven::read_sav()`. Same label handling as Stata files.

### Large Files (>500MB)
**Problem**: `read.csv()` and `readr::read_csv()` are slow for very large files.
**Fix**: Use `data.table::fread()` for CSV (10–50× faster). For Stata/SPSS, `haven` is already efficient but consider reading in chunks for multi-GB files.

### Character Encoding
**Problem**: Chinese survey data (CFPS, CGSS, CHARLS) may use GB2312/GBK encoding, not UTF-8.
**Fix**: Specify encoding: `haven::read_dta("file.dta", encoding = "UTF-8")` or try `"GBK"` if garbled. For CSV: `fread("file.csv", encoding = "UTF-8")`.

### Excel Multi-Sheet
**Problem**: Survey data in .xlsx may span multiple sheets (e.g., one per wave/year).
**Fix**: List sheets with `readxl::excel_sheets("file.xlsx")`, then loop: `map_dfr(sheets, ~read_xlsx("file.xlsx", sheet = .x))`.
