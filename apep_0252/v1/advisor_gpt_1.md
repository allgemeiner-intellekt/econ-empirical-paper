# Advisor Review - GPT-5-mini

**Role:** Academic advisor checking for fatal errors
**Model:** openai/gpt-5-mini
**Paper:** paper.pdf
**Timestamp:** 2026-02-12T16:53:54.832480
**Route:** OpenRouter + LaTeX
**Tokens:** 18918 in / 3324 out
**Response SHA256:** 4fdda022393f24f8

---

FINDING SUMMARY (high level)
- I found FATAL errors that must be fixed before submission. Most are internal inconsistencies about the sample and treatment coding (Data-Design / Internal Consistency), plus a couple of completeness issues (visible placeholders). Fix these before referees see the paper.

FATAL ERRORS (each must be fixed)

FATAL ERROR 1: Data-Design Alignment / Internal Consistency
  Location: Data section (Sec. 3), Footnote on sample; Appendix Table "State Prohibition Adoption Dates" (App. A.4); various places in main text (Introduction, Institutional Background)
  Error: Inconsistent treatment/sample definitions regarding Maine and Kansas and inconsistent statements about how many states are in the sample and how many are treated.
    - Main text repeatedly uses Kansas as an example of an early adopter (e.g., Introduction, Sec. 2.2) and the prohibition dates table (App. A.4) lists Kansas (1881) and Maine (1851).
    - Sec. 3 (Data) footnote and sample description state: "The panel includes 47 states ... excluding Maine and Kansas as very early adopters" and elsewhere "Maine and Kansas are excluded because they adopted prohibition decades before the next-earliest state" (Sec. 3.1).
    - The paper also at different points refers to 33 treated states between 1881 and 1919, 31 treated states, "after excluding Maine and Kansas ... 31 as treated" (Introduction footnote), and the Appendix table lists Maine and Kansas among the adoption dates. The summary stats table reports treated (%) by year implying certain coding (e.g., Treated = 2 in 1890, 2 in 1900, 15 in 1910, 100 in 1920) but these percentages and counts cannot be reconciled with the inconsistent inclusion/exclusion statements.
  Why this is fatal:
    - The DiD identification and treatment indicator depend critically on which jurisdictions are coded as treated and when. Inconsistent statements about whether Maine and Kansas are in the sample (and whether they are coded as treated) imply the treatment timing / exposure variable is not well-defined. That can produce entirely different estimation samples, different first-stage variation (who is treated when), and invalidates all DiD estimates until clarified and corrected.
  How to fix:
    - Decide unambiguously whether Maine and Kansas are included in the analysis sample. If they are excluded, remove them everywhere (prohibition dates table, discussions, counts) and explicitly state why (e.g., adopt year pre-1870 makes them unsuitable).
    - If they are included, then (a) include them consistently in the sample description and in all tables/footnotes, (b) report how they are treated in the panel (their adoption years), and (c) adjust any statements that said they were excluded.
    - Recompute and report sample sizes, N by year, and the number of treated units/cohorts consistently after the decision. Update all text passages that state “33 states”, “31 treated”, “16 never-treated”, etc., so every numeric statement matches the actual coding.
    - Be explicit about the universe (states + DC + territories) and the rule for including late-admitted states. Provide a clear table (in main text or appendix) with the exact sample used in estimation (list of included jurisdictions, treatment adoption year as coded, and whether ever-treated in the sample).

FATAL ERROR 2: Internal Consistency — Contradictory statements about number of treated / never-treated jurisdictions
  Location: Introduction, Sec. 2.2, Sec. 3.1, Appendix A.4, footnotes
  Error: Conflicting counts of treated and never-treated jurisdictions:
    - Introduction and other places state “thirty-three states adopted statewide prohibition between 1881 and 1919.”
    - The Appendix table and footnotes describe 17 never-treated jurisdictions and elsewhere "16 units serve as never-treated controls and 31 as treated." These counts are inconsistent with one another and with the statement about 33 treated states.
  Why this is fatal:
    - In a staggered-treatment DiD design, the number of treated cohorts, number of never-treated controls, and which units are in which group determine the estimand and weights. Inconsistent reporting undermines confidence that the analyses were run on the sample claimed and that the reported coefficients correspond to a coherent estimand.
  How to fix:
    - Reconcile all counts. Produce and display (in the Appendix) a single authoritative table listing each jurisdiction in the analysis, its inclusion status, and the coded adoption year. Then update every textual claim (e.g., “33 treated states”, “16 never-treated”) to match that table.
    - Ensure the summary statistics table (Table 1) is computed from that exact sample and report the total number of state-year observations (and explain any unbalancedness and why certain state-years are missing).

FATAL ERROR 3: Completeness / Internal Consistency — Treated indicator definition ambiguous vs. census timing
  Location: Sec. 3.4 (State Prohibition Adoption Dates), main equations (Sec. 4), Table summaries (Table: Summary Statistics)
  Error: The treatment indicator is defined as "Treated_{st} equals one if state s had statewide prohibition in effect at the time of census year t's enumeration." But the precise mapping of adoption year to census-year exposure is not fully specified (e.g., if adoption occurs mid-decade, how is the census-year coded?), and the sample includes many states that adopted prohibition within the same decade as a census (e.g., 1916–1919 adoptions with the 1920 census). The paper needs to be explicit whether a state that adopts in year X is coded treated for the census in year X (if adoption precedes census date) or only for subsequent censuses.
  Why this is fatal:
    - Ambiguity in how adoption years map into decennial census years directly affects whether particular state-year observations are pre- or post-treatment. With many adoptions clustered right before 1920, inconsistent coding could flip many observations from pre- to post-treatment and materially change estimates.
  How to fix:
    - Explicitly state the coding rule: e.g., Treated_{st} = 1 if AdoptionYear_s ≤ CensusYear_t (and clarify whether the census enumeration date is used, and how mid-decade adoptions are handled). Provide examples for borderline cases (states adopting in 1916–1919).
    - Report and include in the appendix a table that, for each state and each census year in the panel, shows the Treated_{st} coding used in the regressions (so a referee can verify which observations are post-treatment).
    - Re-run analyses if this changes coding and update reported coefficients.

FATAL ERROR 4: Completeness — Visible placeholder / default values in front matter
  Location: Title footnote on first page (author footnote): "Total execution time: \apepcurrenttime{} (cumulative: \apepcumulativetime{})." Default set to "N/A" if timing_data.tex not found.
  Error: The manuscript currently prints "N/A" for execution time in the author footnote (via the \IfFileExists fallback). This is a visible placeholder in the compiled document.
  Why this is fatal:
    - The instructions require no "NA"/"TBD"/"PLACEHOLDER" strings remaining in the submitted manuscript. Visible placeholders can be interpreted as an unfinished draft and will likely cause a desk rejection at some journals.
  How to fix:
    - Either (a) include timing_data.tex with real values so the placeholders are replaced, or (b) remove the timing footnote entirely or replace with a final text string that does not contain "N/A" or other placeholders before submission.

FATAL ERROR 5: Completeness / Potentially Fatal — Regression tables are \input{} from external files but not displayed/embedded in the LaTeX source here / lack of N and standard-error reporting check
  Location: All regression/table displays (e.g., Table~\ref{tab:twfe}, \input{tables/tab2_twfe}, \input{tables/tab2b_sunab}, \input{tables/tab3_heterogeneity}, etc.)
  Error: The LaTeX source uses many \input{tables/...} commands to pull in tables. I cannot see the contents of those table files here. The paper's text reports coefficients and SEs, but I cannot verify that each regression table includes required items (N, standard errors, significance markers). The Completeness checks in the assignment require explicit verification that regression tables include sample sizes and standard errors. If any of those external table files omit N or SEs, that is a fatal error.
  Why this is fatal:
    - Journal submissions require complete regression tables with sample sizes and standard errors. If any regression table omits N or SEs, or contains placeholders like "NA"/"TBD" in cells, the submission is incomplete and will be desk-rejected or returned for revision.
  How to fix:
    - Before submission, ensure each table file (the contents of tables/*.tex) includes:
       * A clear report of sample size (N or number of state-year observations) for each column/specification.
       * Standard errors (clustered at state) reported either in parentheses or as footnotes/confidence intervals.
       * No "NA", "NaN", "Inf", "TBD", or "XXX" placeholders anywhere in the table cells or notes.
    - Add an explicit check in your build process to fail if any \input table file contains "NA", "TBD", or empty cells.
    - If possible, also include the number of clusters (states) used for cluster-robust SEs.

ADDITIONAL (non-fatal but important) NOTES — fix these before submission
- Data imputation clarity: You already discuss the imputation for German-born counts; make sure the main text emphasizes that the two directly observed years (1890, 1920) bracket the key treatment window and show sensitivity analyses that rely only on years with direct observations (e.g., 1890 vs 1920 cross-section / difference) so readers can assess robustness without relying on imputed intermediate years.
- Treatment timing and event-study power: You note limited post-treatment observations for late-adopters (1916–1919). This is not a fatal error but must be emphasized clearly in limitations and in your interpretation of event studies. Consider labeling event-study x-axis and confidence intervals to show how many treated cohorts contribute to each point.
- Make the "always included appendix table" (jurisdiction × census-year × Treated flag) available as an online supplement so reviewers can replicate treatment coding.

CONCLUSION
You need to resolve the sample/treatment inconsistencies (Errors 1–3) and eliminate placeholders / ensure table completeness (Errors 4–5) before submitting. These are fatal because they bear directly on the validity of the treatment assignment and on whether the manuscript is a finished product suitable for referees.

ADVISOR VERDICT: FAIL