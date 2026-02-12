# Exhibit Review — Gemini 3 Flash (Round 1)

**Role:** Visual exhibit advisor
**Model:** gemini-3-flash-preview (ai_studio)
**Paper:** paper.pdf
**Timestamp:** 2026-02-12T16:54:23.083455
**Route:** Direct Google API + PDF
**Tokens:** 21517 in / 2346 out
**Response SHA256:** 9afdb05a292b13cf

---

# Exhibit-by-Exhibit Review

## Main Text Exhibits

### Figure 1: "Distribution of State Prohibition Adoption Years"
**Page:** 6
- **Formatting:** Clean, minimalist histogram. The vertical dashed line for "US enters WWI" is a helpful touch for top-tier journals.
- **Clarity:** Excellent. The bimodal nature of adoption is immediately apparent.
- **Storytelling:** Strong. It justifies the staggered DiD approach by showing the variation in treatment timing.
- **Labeling:** Clear. Source notes are present.
- **Recommendation:** **KEEP AS-IS**

### Table 1: "Summary Statistics by Census Year"
**Page:** 10
- **Formatting:** Professional "booktabs" style. However, the Panel A label suggests a Panel B that does not exist in this table.
- **Clarity:** Numbers are easy to read, but they are not decimal-aligned.
- **Storytelling:** Good for showing the secular decline of the German-born share and the expansion of treatment.
- **Labeling:** Clear.
- **Recommendation:** **REVISE**
  - Align numbers by decimal point in all columns.
  - Remove "Panel A: Full Sample" unless adding a Panel B (e.g., split by eventual treatment status).

### Table 2: "Pre-Treatment Balance (1890)"
**Page:** 11
- **Formatting:** Consistent with Table 1.
- **Clarity:** Clean. The comparison between groups is stark.
- **Storytelling:** Crucial. It admits the selection bias (treated states were smaller/less German) which motivates the later interaction models.
- **Labeling:** Clear.
- **Recommendation:** **KEEP AS-IS**

### Table 3: "Effect of State Prohibition on German-Born and Foreign-Born Population"
**Page:** 15
- **Formatting:** AER-standard. Variable names (e.g., `german_share`) are left in the header; these should be removed in favor of the descriptive labels below them.
- **Clarity:** The juxtaposition of shares vs. logs is standard and clear.
- **Storytelling:** This table shows the "misleading" average effect. It is a vital part of the paper's narrative arc.
- **Labeling:** Significance stars defined. SEs in parentheses.
- **Recommendation:** **REVISE**
  - Remove the raw code variable names (`german_share`, `log_german`, etc.) from the header. Keep only "German Share", "Log German", etc.
  - Report the dependent variable mean at the bottom of the table to help readers gauge magnitude.

### Table 4: "Sun & Abraham (2021) Heterogeneity-Robust Estimates"
**Page:** 16
- **Formatting:** Standard. Code variables again present in headers.
- **Clarity:** Highly effective. It immediately shows the sign reversal compared to Table 3.
- **Storytelling:** Central to the "Rescue an uninformative average" argument.
- **Labeling:** Clear.
- **Recommendation:** **REVISE**
  - Clean headers (remove `german_share`).
  - Consider merging this into Table 3 as a separate panel (Panel A: TWFE, Panel B: Sun & Abraham) to allow direct comparison of the sign reversal in one exhibit.

### Figure 2: "German-Born Population Share by Treatment Group, 1870–1920"
**Page:** 17
- **Formatting:** Good use of distinct colors and shapes for lines. 
- **Clarity:** High. The 1870 outlier for "Late prohibition" is very visible.
- **Storytelling:** Essential. It visualizes the "Parallel Trends" challenge and why the level differences matter.
- **Labeling:** Legend is clear.
- **Recommendation:** **KEEP AS-IS**

### Figure 3: "Foreign-Born Population Share by Prohibition Status"
**Page:** 18
- **Formatting:** Consistent with Figure 2.
- **Clarity:** High.
- **Storytelling:** Demonstrates that the pattern isn't exclusive to Germans, supporting the "ethnic enclave" spillover theory.
- **Labeling:** Clear.
- **Recommendation:** **MOVE TO APPENDIX**
  - The German-born figure (Fig 2) is the primary interest. This is a supporting robustness check that clutters the main results section.

### Table 5: "Heterogeneous Effects by Pre-Prohibition Brewing Intensity"
**Page:** 19
- **Formatting:** Clean. Again, remove raw variable names from headers.
- **Clarity:** The interaction terms are clearly labeled.
- **Storytelling:** This is the "Money Table." It proves the mechanism.
- **Labeling:** Clear.
- **Recommendation:** **KEEP AS-IS** (with header cleanup)

### Figure 4: "Brewing Intensity and Change in German-Born Share"
**Page:** 20
- **Formatting:** Scatter plot with trend lines and state abbreviations. The overlap of labels (e.g., near 0,0) is a bit messy.
- **Clarity:** The message is clear (negative slope), but the visualization is a bit "noisy."
- **Storytelling:** Good visualization of the cross-sectional logic.
- **Labeling:** Clear.
- **Recommendation:** **REVISE**
  - Use a "repel" algorithm for the state labels so they don't overlap.
  - Make the trend lines more distinct (e.g., solid vs. dashed).

### Table 6: "Heterogeneous Effects by German Enclave Status"
**Page:** 21
- **Formatting:** Consistent.
- **Clarity:** Very high.
- **Storytelling:** Shows the most "dramatic" results of the paper. 
- **Labeling:** Clear.
- **Recommendation:** **KEEP AS-IS**

### Table 7: "Effect of Prohibition on Population Growth"
**Page:** 22
- **Formatting:** Consistent.
- **Clarity:** Clear, though results are null.
- **Storytelling:** Important for distinguishing between "flow" and "stock" effects.
- **Labeling:** Clear.
- **Recommendation:** **MOVE TO APPENDIX**
  - Null results on growth rates are important for completeness but distract from the high-impact level/share results.

### Table 8: "Robustness: Alternative Control Groups"
**Page:** 23
- **Formatting:** Good use of columns for different subsamples.
- **Clarity:** High.
- **Storytelling:** Standard robustness check.
- **Labeling:** Clear.
- **Recommendation:** **MOVE TO APPENDIX**

### Table 9: "Dose-Response: Duration of Prohibition Exposure"
**Page:** 24
- **Formatting:** Consistent.
- **Clarity:** Clear.
- **Storytelling:** Weakest of the main results (marginal significance).
- **Labeling:** Clear.
- **Recommendation:** **MOVE TO APPENDIX**

### Figure 5: "Randomization Inference: Baseline TWFE Coefficient"
**Page:** 25
- **Formatting:** Excellent. The red "True estimate" line is standard for this type of plot.
- **Clarity:** High.
- **Storytelling:** Strong "defense" exhibit. It explains why the positive coefficient in Table 3 shouldn't be taken seriously.
- **Labeling:** Clear.
- **Recommendation:** **KEEP AS-IS**

### Figure 6: "TWFE Event Study: German-Born Share"
**Page:** 26
- **Formatting:** Very "R-default" looking. The y-axis is a bit sparse. The point estimates are small dots that are hard to see.
- **Clarity:** Moderate. The pre-trend is visible but the "noise" makes it hard to parse quickly.
- **Storytelling:** Mandatory for a DiD paper.
- **Labeling:** Clear.
- **Recommendation:** **REVISE**
  - Increase the size of the point estimates (the dots).
  - Use a cleaner ggplot2 or Stata `binscatter` style.
  - Add a horizontal dashed line at y=0.
  - Group years into bins if the 10-year decennial frequency is making it too sparse.

## Appendix Exhibits

### Table 10: "State Prohibition Adoption Dates"
**Page:** 35
- **Formatting:** Multi-column list. Logical.
- **Clarity:** Easy to look up a specific state.
- **Storytelling:** Good reference for the raw data.
- **Recommendation:** **KEEP AS-IS**

### Table 11: "Variable Definitions"
**Page:** 36
- **Formatting:** Simple two-column table.
- **Clarity:** High.
- **Storytelling:** Essential for transparency.
- **Recommendation:** **KEEP AS-IS**

---

## Overall Assessment

- **Exhibit count:** 9 main tables, 6 main figures, 2 appendix tables, 0 appendix figures.
- **General quality:** The tables follow professional conventions but need "polishing" (header cleanup, decimal alignment). The figures are hit-or-miss; the histogram and RI plot are great, while the event study and scatter plot look a bit amateurish for an AER/QJE submission.
- **Strongest exhibits:** Figure 1 (Adoption Histogram), Figure 5 (RI Plot), Table 6 (Enclave Interaction).
- **Weakest exhibits:** Figure 6 (Event Study), Table 3 (Variable names in headers).
- **Missing exhibits:** 
    - **A Map:** A paper about US states and geography *must* have a map showing which states were "High Brewing Intensity" or "German Enclaves."
    - **A Regression Table with all interactions:** Combining Table 5 and 6 into one table (perhaps as columns) would help the reader see the horse race between the "Brewing" mechanism and the "Enclave" mechanism.

**Top 3 improvements:**
1. **Consolidate and Clean Tables:** Merge Table 3 and 4 (TWFE vs. Sun-Abraham) and move robustness/dose-response (Tables 7, 8, 9) to the appendix to create a "leaner" main text.
2. **Add a Map:** Create a shaded US map showing brewing intensity in 1870. This provides the "spatial storytelling" top journals look for in economic history.
3. **Upgrade Figure 6:** Redraw the event study with thicker lines, larger points, and a more professional theme (e.g., `theme_bw()` in R or `scheme s1mono` in Stata).