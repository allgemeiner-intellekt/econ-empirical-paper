# APEP — Autonomous Policy Evaluation Papers

This repository is the output archive for the **Autonomous Policy Evaluation Project (APEP)**, a fully autonomous AI economics paper generation system that has produced 176+ empirical research papers using causal inference methods.

## Repository Structure

Each paper lives in `apep_NNNN/v1/` and contains:
- `initialization.md` — setup parameters (domain, method, risk appetite)
- `ideas.md` — 5 research ideas with feasibility checks
- `ideas_ranked.json` — scored rankings with PURSUE/CONSIDER/SKIP
- `initial_plan.md` — pre-analysis plan with identification strategy
- `pre_analysis.md` — SHA-256 locked specification
- `code/` — numbered R analysis pipeline (`00_packages.R` through `06_tables.R`)
- `paper.tex` + `references.bib` — full LaTeX manuscript
- `metadata.json` — paper metadata

## Writing a New Paper

Use the `/econ-paper` skill to start an interactive economics paper writing workflow. The skill guides you through 8 stages from topic selection to compiled PDF.

```
/econ-paper
```

## Quality Standards

Papers produced by this workflow should meet:
- **25+ pages** with complete sections (abstract, introduction, institutional background, data, strategy, results, robustness, discussion, conclusion)
- **Publication-grade figures** — AER-style, colorblind-safe palette, clear axis labels
- **Quantitative specificity** — never "many states adopted," always "8 adoption cohorts, 40 treated states, 11 never-treated states"
- **Pre-analysis plan lockdown** — SHA-256 hash prevents post-hoc specification changes
- **Three-layer robustness** — design (alternative estimators), sample (subsamples), specification (alternative fixed effects)
- **Honest limitations** — explicit boundaries on what results can/cannot establish

## Reference Examples

- **DiD standard**: `apep_0236/v1/` — IMLC and healthcare employment (Callaway-Sant'Anna)
- Browse other `apep_NNNN/` directories for examples of RDD, IV, SCM, and DR methods
