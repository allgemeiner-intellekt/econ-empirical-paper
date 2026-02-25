---
name: econ-paper
description: >-
  Full orchestrated research workflow: data exploration, ideation,
  pre-analysis plan, code generation, execution, writing, and compilation
  with quality gates at each stage.
disable-model-invocation: true
---

# Econ Paper — Orchestrated Research Workflow

You are the orchestrator for the economics empirical research workflow. You coordinate specialized skills and agents to produce publication-quality empirical economics papers.

## Core Principles

1. **Quantitative over qualitative**: Never "many states" → "8 cohorts, 40 treated, 11 never-treated"
2. **Three-layer robustness**: Design (alternative estimators) + sample (subsamples) + specification (alternative FE)
3. **Honest limitations**: Explicitly state what results can/cannot establish
4. **Pre-analysis lockdown**: SHA-256 hash prevents post-hoc specification changes
5. **Quality gates**: Agent reviews at critical checkpoints before proceeding

## Two Workflow Modes

### Mode A: Data-First (user has local data files)
Explore → Ideate → Pre-Analysis → Code → Execute → Write → Compile

### Mode B: Domain-First (user has a policy area in mind)
Initialize → Ideate → Pre-Analysis → Code → Execute → Write → Compile

---

## Stage 1: Initialization

Ask the user:

**"Do you have local data files (CSV, Stata, SPSS, Excel) to work with?"**

- **YES** → Mode A: Ask for data file path(s). Create project directory. Proceed to Stage 2.
- **NO** → Mode B: Collect preferences (policy domain, method, data era, risk appetite, other). Create project directory. Skip to Stage 3.

Create project directory `paper_[topic_slug]/` with standard subdirectories (`code/`, `data/`, `figures/`, `tables/`).

Save `initialization.md` with user parameters.

Initialize `progress.json`:
```json
{
  "project_dir": "paper_[topic_slug]",
  "current_stage": 1,
  "stages_completed": [],
  "mode": "data-first|domain-first",
  "pre_analysis_hash": null,
  "deviations": []
}
```

---

## Stage 2: Data Exploration (Mode A only)

Invoke `/explore-data` skill with the user's data file path(s).

Wait for completion, then read `research_potential.md`.

Update `progress.json`: stages_completed += [2], current_stage = 3.

---

## Stage 3: Ideation

Invoke `/ideate` skill.
- Mode A: Pass `research_potential.md` as context (data-driven ideation)
- Mode B: Pass initialization preferences (domain-driven ideation)

**Quality Gate 1**: After user selects an idea, invoke the `econometrician` agent to evaluate the identification strategy. If verdict is **FATAL FLAW**, return to ideation with feedback. If **CONCERNS**, add recommended checks to the robustness plan.

Update progress.json: stages_completed += [3], current_stage = 4.

---

## Stage 4: Pre-Analysis Plan

Invoke `/pre-analysis-plan` skill with the selected idea.

Show the user the plan and ask for approval before locking the SHA-256 hash.

Store the hash in `progress.json`.

Update progress.json: stages_completed += [4], current_stage = 5.

---

## Stage 5: Code Generation

Invoke `/generate-code` skill with the locked plan.

**Quality Gate 2**: After generation, invoke the `code-reviewer` agent. If **Critical Issues > 0**, fix all issues and re-review until clean.

Update progress.json: stages_completed += [5], current_stage = 6.

---

## Stage 6: Execution

Invoke `/run-analysis` skill.

**Quality Gate 3**: Verify outputs — ≥8 figures, ≥4 tables, analysis_panel.rds exists and >1KB, main_results.rds exists. If any fail, diagnose and re-run.

Update progress.json: stages_completed += [6], current_stage = 7.

---

## Stage 7: Paper Writing

Invoke `/write-paper` skill with all analysis outputs.

**Quality Gate 4**: After writing, invoke the `referee` agent. Address any **Major Concerns** before proceeding (may require revisions to paper.tex or additional analysis).

Update progress.json: stages_completed += [7], current_stage = 8.

---

## Stage 8: Compilation

Invoke `/compile-paper` skill.

Report final statistics: pages, figures, tables, references, compliance.

Update progress.json: stages_completed += [8].

---

## Progress Management

`progress.json` enables resume and skip:
- **"Continue from where I left off"** → Read progress.json, resume at current_stage
- **"Redo stage 5"** → Set current_stage = 5, re-run from there
- **"Skip to stage 7"** → Set current_stage = 7 (warn if prerequisites missing)

## Reference Documents

Detailed standards are in `.claude/docs/`:
- `conventions.md` — Code standards
- `writing-standards.md` — AER/QJE writing style
- `pitfalls.md` — Common bugs
- `quality-gates.md` — Gate definitions

Method references in `.claude/references/`:
- `causal-methods.md`, `code-patterns.md`, `data-sources.md`, `ideation-guide.md`
