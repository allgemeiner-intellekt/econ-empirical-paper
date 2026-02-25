# Empirical Economics Research System

Modular system for producing publication-quality empirical economics papers with causal inference methods. Supports original research from data exploration to compiled PDF, and replication of published papers.

## Quick Start

| Command | What it does |
|---------|-------------|
| `/econ-paper` | **Full orchestrated workflow** — data exploration → ideation → pre-analysis → code → execution → writing → compilation, with quality gates |
| `/explore-data` | Profile a local dataset (CSV, Stata, SPSS, Excel) — variable dictionary, panel diagnostics, research potential |
| `/ideate` | Generate 5 scored research ideas — data-driven or domain-driven |
| `/pre-analysis-plan` | Lock a research plan with SHA-256 hash |
| `/generate-code` | Generate complete R analysis pipeline (API or local data) |
| `/run-analysis` | Execute pipeline and verify outputs |
| `/write-paper` | Generate LaTeX manuscript (AER/QJE style, 25+ pages) |
| `/compile-paper` | Compile PDF and package deliverables |
| `/replicate` | Reproduce a published paper's results |
| `/robustness-check` | Add robustness tests (placebo, alt estimator, sample restriction) |
| `/referee-response` | Draft response to referee reports with new analyses |

## Agents (invoked by skills or orchestrator)

| Agent | Role |
|-------|------|
| `code-reviewer` | Audit R scripts for bugs (FIPS, log(0), missing tryCatch) — read-only |
| `econometrician` | Validate identification strategy credibility — read-only |
| `referee` | Simulate hostile Reviewer 2 — read-only |
| `academic-writer` | AER-style prose generation — writes .tex/.bib |
| `data-engineer` | Data pipelines and panel construction — writes .R, runs Rscript |

## Core Principles

- **Quantitative specificity** — never "many states," always "42 states across 8 cohorts"
- **Three-layer robustness** — design (alt estimators) + sample (subsamples) + specification (alt FE)
- **Pre-analysis lockdown** — SHA-256 hash; deviations logged in `deviations.json`
- **Honest limitations** — specific boundaries, not vague disclaimers
- **Quality gates** — agent reviews at 4 checkpoints (see `.claude/docs/quality-gates.md`)

## Documentation (loaded on demand by skills/agents)

| File | Content |
|------|---------|
| `.claude/docs/conventions.md` | Code standards, naming, directory structure |
| `.claude/docs/writing-standards.md` | AER/QJE academic writing rules |
| `.claude/docs/pitfalls.md` | Common bugs (FIPS, log(0), COVID gap, merge explosion) |
| `.claude/docs/quality-gates.md` | Gate definitions and hook integration |
| `.claude/docs/replication-guide.md` | Paper replication workflow |

## References (domain knowledge)

| File | Content |
|------|---------|
| `.claude/references/causal-methods.md` | DiD, RDD, IV, SCM, DR checklists and code |
| `.claude/references/code-patterns.md` | R pipeline templates and figure/table patterns |
| `.claude/references/data-sources.md` | BLS, FRED, Census API reference |
| `.claude/references/ideation-guide.md` | Idea evaluation framework |
