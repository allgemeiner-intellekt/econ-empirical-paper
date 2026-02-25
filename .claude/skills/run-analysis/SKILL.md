---
name: run-analysis
description: >-
  Execute the R analysis pipeline and verify that outputs meet quality
  thresholds.
disable-model-invocation: true
---

# Run Analysis — Execute Pipeline and Verify Outputs

You execute the R analysis pipeline and verify that outputs meet quality standards.

## Input

- `code/` directory containing all R scripts (00–06) and `run_all.sh`
- `data/` directory (may be empty if `01_fetch_data.R` creates it)

## Before Executing

Read `.claude/docs/quality-gates.md` for Gate 3 output verification requirements.

## Execution

### Full Pipeline Run
```bash
cd [project_dir]/code
chmod +x run_all.sh
bash run_all.sh
```

### Partial Re-Run
If the user requests "start from script 03":
```bash
cd [project_dir]/code
for script in 03_*.R 04_*.R 05_*.R 06_*.R; do
  echo "Running $script..."
  Rscript "$script"
done
```

## Error Handling

If a script fails:

1. **Read the error message** carefully
2. **Diagnose the root cause**:
   - `Error in library(X)`: Missing package → add to `00_packages.R` and re-run
   - `HTTP 429` / `timeout`: API rate limit → increase `Sys.sleep()` and retry
   - `object 'X' not found`: Missing variable → check data loading in prior script
   - `cannot open connection`: File path issue → check relative paths
   - `NAs introduced by coercion`: Type conversion issue → check data types
3. **Fix the code** in the failing script
4. **Re-run from the failed script onward** (not the entire pipeline)
5. **Maximum 3 retry attempts per script** — if still failing after 3 fixes, report to user

## Output Verification (Gate 3)

After successful execution, verify:

| Check | Threshold | How to Verify |
|-------|-----------|--------------|
| `data/analysis_panel.rds` exists | Size > 1KB | `ls -la ../data/analysis_panel.rds` |
| `data/main_results.rds` exists | File present | `ls ../data/main_results.rds` |
| `figures/` PDF count | ≥ 8 | `ls ../figures/*.pdf \| wc -l` |
| `tables/` .tex count | ≥ 4 | `ls ../tables/*.tex \| wc -l` |
| No NA in key estimates | Check CSV | Read `estimates_table.csv` |

## Results Report

After verification, report to the user:

```markdown
## Execution Summary

**Status**: ✓ Complete (all scripts ran successfully)

### Key Results
- **Overall ATT**: [estimate] (SE = [se], p = [pval])
- **Significance**: [***/**/*]
- **N observations**: [count]
- **N treated states**: [count]
- **N never-treated states**: [count]
- **Pre-treatment trend**: [assessment — parallel trends supported or not]

### Output Files
- Figures: [count] PDFs in figures/
- Tables: [count] .tex files in tables/
- Data: analysis_panel.rds ([size])

### Unexpected Findings
- [Any anomalies, null results, or surprises]
```

## After Execution

Tell the user: "Analysis complete. Key results: [1-line summary]. Run `/write-paper` to generate the manuscript."
