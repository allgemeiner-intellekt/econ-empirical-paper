# Replication Report

**Paper ID:** apep_0116
**Title:** Betting on Jobs? The Employment Effects of \\
Legal Sports Betting in the United States\thanks{This paper is a revision of APEP-0038. See \url{https://github.com/anthropics/auto-policy-evals/tree/main/papers/apep_0038
**Replication Date:** 2026-01-30
**Replicator:** Claude Code

---

## Summary

**Classification:** PARTIAL WITH ERRORS

**Overall Assessment:**
1 of 9 scripts failed. Results may be incomplete.

### Execution Summary

- **Total Scripts:** 9
- **Successful:** 8
- **Failed:** 1

---

## 1. Computing Environment

- **Platform:** macOS-15.6.1-arm64-arm-64bit-Mach-O
- **Processor:** arm
- **Python Version:** 3.14.2
- **R Version:** R version 4.5.2 (2025-10-31) -- "[Not] Part in a Rumble"

### R Packages
```
> 
>         pkgs <- c("fixest", "rdrobust", "did", "ggplot2", "modelsummary", "haven", "tidyverse")
>         installed <- installed.packages()
>         for (p in pkgs) {
+             if (p %in% rownames(installed)) {
+                 cat(sprintf("%s: %s
+ ", p, installed[p, "Version"]))
+             }
+         }
fixest: 0.13.2
rdrobust: 3.0.0
did: 2.3.0
ggplot2: 4.0.1
modelsummary: 2.5.0
haven: 2.5.5
tidyverse: 2.0.0
>         
>
```

---

## 2. Code Inventory

**R Scripts:** 9
**Python Scripts:** 0
**Main Script:** 00_packages.R

| Script | Language |
|--------|----------|
| `00_packages.R` | R |
| `01_fetch_qcew.R` | R |
| `01b_create_cached_qcew.R` | R |
| `02_fetch_policy.R` | R |
| `03_clean_data.R` | R |
| `04_main_analysis.R` | R |
| `05_robustness.R` | R |
| `06_figures.R` | R |
| `07_tables.R` | R |

---

## 3. Execution Results

| Script | Success | Duration | Exit Code |
|--------|---------|----------|-----------|
| `00_packages.R` | Yes | 1.7s | 0 |
| `01_fetch_qcew.R` | **No** | 600.1s | -1 |
| `01b_create_cached_qcew.R` | Yes | 1.8s | 0 |
| `02_fetch_policy.R` | Yes | 1.4s | 0 |
| `03_clean_data.R` | Yes | 1.4s | 0 |
| `04_main_analysis.R` | Yes | 2.5s | 0 |
| `05_robustness.R` | Yes | 5.2s | 0 |
| `06_figures.R` | Yes | 3.0s | 0 |
| `07_tables.R` | Yes | 1.4s | 0 |

### Errors

#### 01_fetch_qcew.R

```
TIMEOUT: Script exceeded 10 minute limit
```


---

## 4. Figure Comparisons

| Figure | Original | Generated | Status |
|--------|----------|-----------|--------|
| `fig1_event_study.pdf` | Yes | Yes | Visual inspection required |
| `fig4_mobile_heterogeneity.pdf` | Yes | Yes | Visual inspection required |
| `fig4_mobile_heterogeneity.png` | Yes | Yes | Visual inspection required |
| `fig1_event_study.png` | Yes | Yes | Visual inspection required |
| `fig5_robustness.pdf` | Yes | Yes | Visual inspection required |
| `fig6_leave_one_out.png` | Yes | Yes | Visual inspection required |
| `fig2_parallel_trends.png` | Yes | Yes | Visual inspection required |
| `fig6_leave_one_out.pdf` | Yes | Yes | Visual inspection required |
| `fig2_parallel_trends.pdf` | Yes | Yes | Visual inspection required |
| `fig5_robustness.png` | Yes | Yes | Visual inspection required |
| `fig3_treatment_map.pdf` | Yes | Yes | Visual inspection required |
| `fig3_treatment_map.png` | Yes | Yes | Visual inspection required |

---

## 5. Classification

### Final Classification: PARTIAL WITH ERRORS

**Justification:**
1 of 9 scripts failed. Results may be incomplete.

---

## 6. Next Steps

1. Fix failing scripts
2. Re-run replication
3. Visually compare outputs

---

## Appendix: File Locations

- **Execution Log:** `logs/execution.log`
- **Generated Figures:** `figures/`
- **Generated Tables:** `tables/`
- **Original Paper:** `/Users/dyanag/auto-policy-evals/papers/apep_0116/paper.pdf`
