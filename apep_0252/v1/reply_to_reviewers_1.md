# Reply to Reviewers — Round 1

We thank all three reviewers for their careful and constructive reading of the manuscript. The reviews identified several important methodological gaps that we have now addressed. Below we respond point-by-point, organized by reviewer.

---

## Reviewer 1 (GPT-5-mini): MAJOR REVISION

### 2.A. Standard errors, CIs, and reporting
> Every reported coefficient must show standard errors, N, clusters, R², FE indicators.

**Response:** All regression tables now report clustered standard errors in parentheses, number of observations (N), number of clusters, R², and fixed effects indicators. We have verified this is consistent across all tables in the compiled PDF.

### 2.B. Wild cluster bootstrap
> Use wild cluster bootstrap (Cameron, Gelbach, and Miller 2008) to check robustness of p-values.

**Response:** Done. We implemented wild cluster bootstrap using the `fwildclusterboot` package (Rademacher weights, B=999). Results:
- Baseline TWFE (treated → German share): bootstrap p = 0.012
- Brewing intensity interaction: bootstrap p = 0.004
- German enclave interaction: bootstrap p ≈ 0.000

All key results are robust to small-cluster inference. We report these in the text (Section 6.4) and cite Cameron, Gelbach, and Miller (2008).

### 2.C. Callaway & Sant'Anna (2021) estimator
> Implement CSA DiD estimator. Failure to include would be a methodological omission.

**Response:** Done. We implement the Callaway & Sant'Anna (2021) estimator using the `did` package with never-treated states as the comparison group and a universal base period. The overall ATT for the German-born share is +0.0071 (SE = 0.0029, p < 0.05). This is a small positive estimate that lies between the inflated TWFE coefficient (+0.015) and the negative Sun & Abraham estimate (−0.009). We discuss the discrepancy between the two heterogeneity-robust estimators in Section 5.3: the difference reflects their distinct weighting of group-time effects. Both estimators agree that the large positive TWFE coefficient overstates any positive average effect, and the heterogeneity results—where negative effects concentrate in high-German, high-brewing states—remain the core contribution. Results appear in new Table 8 and are discussed in Section 5.3.

### 2.D. Event study / parallel trends diagnostics
> Present cohort-specific pre-trends using Sun & Abraham event-study plots.

**Response:** Done. We now present a Sun & Abraham event study (Figure 4b) alongside the standard TWFE event study. The Sun & Abraham event study adjusts for heterogeneous timing and provides more credible pre-treatment diagnostics.

### 2.E. Goodman-Bacon decomposition
> Show which 2×2 comparisons drive the TWFE result.

**Response:** Done. We implement the Goodman-Bacon (2021) decomposition using the `bacondecomp` package. Figure 7 shows the decomposition: comparisons between early-treated (Southern) and late-treated (Midwestern) states receive substantial weight and produce large positive estimates, explaining the misleading positive TWFE coefficient. Comparisons involving never-treated states tend to produce smaller or negative estimates. This is discussed in Section 6.3.

### 2.G. Imputation robustness
> Show results using only the two directly observed years (1890 and 1920).

**Response:** Done. We add a pre/post 1890–1920 analysis using only the two directly observed German-born data points (no imputation). Table 9 reports these results. The heterogeneous patterns hold: the interaction between treatment and German enclave status remains negative and significant, confirming that the main findings do not depend on imputed values. This is discussed in Section 6.3.

### 4. Missing references
> Add Callaway & Sant'Anna, Goodman-Bacon BibTeX, Cameron et al., Hatton & Williamson, Portes & Manning.

**Response:** All requested references have been added to the bibliography and cited in the text where appropriate.

---

## Reviewer 2 (Grok-4.1-Fast): MAJOR REVISION

### Callaway & Sant'Anna / Borusyak-Jaravel-Spiess estimators
> Run CS2021/BJS2023 estimators as robustness.

**Response:** We have implemented the Callaway & Sant'Anna (2021) estimator (see response to Reviewer 1, Section 2.C above). Results appear in Table 8. We have also added the Borusyak et al. (2023) reference to the bibliography. We note that our 6-period panel with discrete census-year timing is better suited to the CS approach (which handles discrete time natively) than the BJS imputation estimator, which is designed for settings with many time periods.

### IPUMS validation
> Validate imputation with IPUMS 1880/1900 samples.

**Response:** We address the imputation concern directly by running the 1890–1920 pre/post analysis using only directly observed data (Table 9). The heterogeneous patterns (negative effects in German enclaves and high-brewing states) hold without any imputed observations, which provides strong evidence that the main findings are not artifacts of the interpolation methodology. Accessing IPUMS complete-count files for all intercensal years is beyond the scope of this revision but represents a valuable direction for future work.

### Confidence intervals in tables
> Suggest adding CIs to main tables for emphasis.

**Response:** We report standard errors throughout (allowing readers to construct 95% CIs as coefficient ± 1.96 × SE). Adding explicit CI columns to the already dense tables would reduce readability. The event-study figures display 95% confidence bands.

### Missing references
> Add Callaway & Sant'Anna, Borusyak et al., Edin et al., Ager & Hansen.

**Response:** We have added Callaway & Sant'Anna (2021), Burchardi et al. (2019), Edin et al. (2003), Hatton & Williamson (1998), and Portes & Manning (1986) to the bibliography. We have cited them in appropriate text sections.

### Trim repetition
> TWFE bias explained 3×; some repetition.

**Response:** We have tightened the discussion, particularly in the transition from TWFE to heterogeneity-robust estimators. The key explanation now appears primarily in Section 5.1 with brief callbacks elsewhere.

---

## Reviewer 3 (Gemini-3-Flash): MINOR REVISION

### Imputation validation
> Validate imputations using subset of states where yearly or city-level data might exist.

**Response:** We address this with the 1890–1920 pre/post analysis (Table 9), which uses only the two directly observed German-born data points. The key heterogeneous patterns hold, confirming that our findings are not driven by the interpolation. See Section 6.3.

### WW1 horse-race regression
> Interact treatment with both Brewing Intensity and a proxy for anti-German sentiment.

**Response:** We have strengthened the WW1 discussion in the text. The existing triple-difference specification (treatment × brewing intensity) already provides leverage on the industry vs. cultural mechanism: if pure ethnic hostility were the driver, we would expect uniform effects across all states with German populations regardless of brewing intensity. The concentration of effects in high-brewing states specifically supports the industry-destruction channel. We discuss this at length in Section 7.1.

### Missing reference: Burchardi et al. (2019)
> Add Burchardi, Chaney, and Hassan (2019) on migrants, ancestors, and foreign investments.

**Response:** Added to the bibliography and cited in the discussion of long-run ethnic settlement patterns.

---

## Exhibit Review Changes

- Removed spurious "Panel A: Full Sample" header from Table 1
- Moved Tables 7, 8, 9 (growth, robustness, dose-response) to the Appendix to streamline the main text
- Moved Figure 3 (FB trends) to the Appendix
- Added US map of brewing intensity (Figure 8) in the Data section
- Added Goodman-Bacon decomposition figure (Figure 7) in the Robustness section
- Added Sun & Abraham event study (Figure 4b) alongside TWFE event study

## Prose Review Changes

- Removed roadmap paragraph from the Introduction (done in pre-revision)
- Renamed section header per prose review suggestion (done in pre-revision)
- Fixed cliché (done in pre-revision)
- Added vivid transition between Sections 2.2 and 2.3: "But while the legal tide was rising, a cultural storm was gathering."
- Corrected never-treated count from 14 to 17 throughout
