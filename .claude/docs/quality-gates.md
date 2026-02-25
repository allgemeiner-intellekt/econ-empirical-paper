# Quality Gates — Automated and Agent-Based Review Checkpoints

## Overview

The APEP workflow includes 4 quality gates at critical junctures. Each gate must pass before the workflow proceeds.

---

## Gate 1: Identification Strategy Review (Post-Ideation)

**Trigger**: After `/ideate` completes and user selects an idea
**Reviewer**: `econometrician` agent
**Input**: Selected idea from `ideas.md` + `ranking.md`

**Pass criteria**:
- Verdict is **CREDIBLE** or **CONCERNS** (not **FATAL FLAW**)
- If CONCERNS: reviewer's recommended additional checks are added to the robustness plan

**Fail action**: Return to `/ideate` with feedback. Generate alternative ideas addressing the fatal flaw.

---

## Gate 2: Code Review (Post-Code Generation)

**Trigger**: After `/generate-code` completes
**Reviewer**: `code-reviewer` agent
**Input**: All scripts in `code/` directory

**Pass criteria**:
- **Critical Issues = 0**
- Warnings are acceptable but should be reviewed

**Fail action**: Fix all critical issues, then re-run code-reviewer. Iterate until Critical = 0.

---

## Gate 3: Output Verification (Post-Execution)

**Trigger**: After `/run-analysis` completes
**Automated checks** (via `post_execution_verify.py` hook + manual verification):

| Check | Threshold | Action if Fail |
|-------|-----------|---------------|
| `figures/*.pdf` count | ≥ 8 | Re-run `05_figures.R` |
| `tables/*.tex` count | ≥ 4 | Re-run `06_tables.R` |
| `data/analysis_panel.rds` size | > 1 KB | Re-run `02_clean_data.R` |
| `data/main_results.rds` exists | Yes | Re-run `03_main_analysis.R` |
| No NA in key estimates | Check `estimates_table.csv` | Diagnose data issues |

**Pass criteria**: All checks pass.
**Fail action**: Diagnose which script failed, fix, re-run from that script onward.

---

## Gate 4: Paper Review (Post-Writing)

**Trigger**: After `/write-paper` completes
**Reviewer**: `referee` agent
**Input**: `paper.tex`, `figures/`, `tables/`, `pre_analysis.md`, `initial_plan.md`

**Pass criteria**:
- No **unaddressed** Major Concerns
- Pre-Analysis Plan compliance: all planned analyses reported

**Fail action**: Address each Major Concern (revise paper.tex or run additional analysis), then re-review.

---

## Hook Integration

Hooks fire automatically on tool events. They provide real-time quality checks without requiring explicit invocation.

### PostToolUse Hooks

| Hook | File | Trigger | What it Checks |
|------|------|---------|---------------|
| R Lint | `lint_r_code.py` | Write/Edit on `*.R` | source() first line, log(0), bare API calls, FIPS-as-numeric |
| Plan Integrity | `check_plan_integrity.py` | Write/Edit on `initial_plan.md` | SHA-256 hash matches `pre_analysis.md`; logs deviations |
| Output Verify | `post_execution_verify.py` | Bash with `Rscript`/`bash` | Figure count, table count, data file existence |

### PreToolUse Hooks

| Hook | File | Trigger | What it Checks |
|------|------|---------|---------------|
| Pre-Execution | `pre_execution_check.py` | Bash with `Rscript`/`bash` | code/ directory complete, data/ exists, env vars set |
| Pre-Compile | `pre_compile_validate.py` | Bash with `pdflatex` | \input{} paths exist, \includegraphics{} paths exist, references.bib non-empty |

---

## Pre-Analysis Plan Integrity

The pre-analysis plan is locked with a SHA-256 hash after user approval:

```
initial_plan.md  →  shasum -a 256  →  stored in pre_analysis.md
```

**Any modification to `initial_plan.md` after locking**:
1. Hook detects hash mismatch
2. Deviation recorded in `deviations.json`:
   ```json
   {
     "deviations": [
       {
         "timestamp": "2026-02-25T14:30:00Z",
         "file": "initial_plan.md",
         "description": "Added robustness check #9: Oster bounds",
         "justification": "Referee requested sensitivity analysis",
         "old_hash": "sha256:abc...",
         "new_hash": "sha256:def..."
       }
     ]
   }
   ```
3. Paper must acknowledge deviation in the Robustness section

---

## Progress Tracking

`progress.json` tracks workflow state:

```json
{
  "project_dir": "paper_imlc_healthcare",
  "current_stage": 5,
  "stages_completed": [1, 2, 3, 4],
  "mode": "data-first",
  "pre_analysis_hash": "sha256:abc123...",
  "deviations": [],
  "gate_results": {
    "gate_1": {"passed": true, "verdict": "CREDIBLE", "timestamp": "..."},
    "gate_2": {"passed": true, "critical_issues": 0, "timestamp": "..."},
    "gate_3": {"passed": false, "reason": "Only 6 figures", "timestamp": "..."}
  }
}
```

Support commands:
- "Continue from where I left off" → Read `progress.json`, resume at `current_stage`
- "Redo stage 5" → Reset `current_stage = 5`, re-run
- "Skip to stage 7" → Set `current_stage = 7` (warn if prerequisites missing)
