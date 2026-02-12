# Revision Plan (Round 1)

## Summary of Reviews

- **GPT-5-mini**: MAJOR REVISION — Requests CS-DiD, Goodman-Bacon decomposition, wild cluster bootstrap, 1890-1920 pre/post analysis, imputation robustness, placebo tests
- **Grok-4.1-Fast**: MAJOR REVISION — Requests CS-DiD/BJS estimators, IPUMS validation, CIs in tables, trim repetition, add 5 missing references
- **Gemini-3-Flash**: MINOR REVISION — Requests imputation validation, WW1 horse-race regression, one missing reference
- **Exhibit Review**: Clean table headers, move Tables 7-9 to appendix, move Fig 3 to appendix, add US map, merge Tables 3+4, upgrade event study
- **Prose Review**: Kill roadmap (DONE), rename section header (DONE), fix cliché (DONE), simplify "in order to", add vivid transition

## Prioritized Actions

### A. New Analyses (R code changes)

1. **Callaway & Sant'Anna (2021) estimator** — All 3 reviewers request this. Use `did` package with never-treated controls. Report group-time ATTs and aggregated ATT. [03_main_analysis.R]

2. **Goodman-Bacon decomposition** — GPT & Grok request. Use `bacondecomp` or `did2s` package. Show which 2×2 comparisons drive the TWFE estimate. [03_main_analysis.R, new figure]

3. **Pre/post 1890→1920 using only observed years** — All reviewers flag imputation. Run simple DiD on the two directly observed years (1890, 1920) to show heterogeneous patterns hold without imputation. [03_main_analysis.R]

4. **Wild cluster bootstrap** — GPT & Grok request. Use `fwildclusterboot` package for key coefficients. [03_main_analysis.R]

5. **Sun & Abraham event study** — GPT requests SA-specific event study (separate from TWFE). Already have sunab() models; extract event-time coefficients. [05_figures.R]

### B. Table/Figure Reorganization

6. **Move Tables 7 (growth), 8 (robustness), 9 (dose-response) to appendix** — Exhibit review recommends. Lean main text.

7. **Move Figure 3 (FB trends) to appendix** — Exhibit review recommends.

8. **Remove "Panel A: Full Sample" from Table 1** — No Panel B exists.

9. **Add dependent variable means to main tables** — Exhibit review recommends.

10. **Report 95% CIs in main tables** — GPT & Grok request.

### C. New Figures

11. **US map of brewing intensity** — Exhibit review: "A paper about US states MUST have a map." Create choropleth map of 1870 brewing intensity.

12. **Goodman-Bacon decomposition figure** — Scatter plot of 2×2 DD estimates vs weights.

### D. References

13. **Add missing references**: Callaway & Sant'Anna (2021), Borusyak et al. (2023), Burchardi et al. (2019), Edin et al. (2003), Cameron et al. (2008), Hatton & Williamson (1998). Update citations in text.

### E. Paper Text Changes

14. **Add CS-DiD results section** after Sun & Abraham section.

15. **Add Goodman-Bacon decomposition discussion** to robustness.

16. **Add 1890-1920 pre/post analysis** as imputation robustness check.

17. **Add wild cluster bootstrap p-values** to key results discussion.

18. **Simplify "in order to" → "to"** throughout paper.

19. **Add vivid transition** between sections 2.2 and 2.3.

20. **Footnote consistency check** — verify never-treated count is 17 everywhere.

### F. Reply to Reviewers

21. Write `reply_to_reviewers_1.md` with point-by-point responses to all 3 reviewers.
