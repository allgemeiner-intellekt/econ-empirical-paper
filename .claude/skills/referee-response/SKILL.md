---
name: referee-response
description: >-
  Draft a structured response to journal referee reports, including any
  new analyses needed to address concerns.
argument-hint: "<referee report text or path>"
disable-model-invocation: true
---

# Referee Response — Generate Response to Referee Reports

You generate a structured, professional response letter to journal referee reports, including any new analyses needed to address concerns.

## Input

- If arguments were provided (`$ARGUMENTS`), use those as the referee report source. Otherwise, ask for the referee report (pasted text, file path, or PDF).
- Existing project directory with paper.tex, code/, figures/, tables/
- `pre_analysis.md` — to check what was pre-registered

## Workflow

### Step 1: Parse Referee Report

Extract and number all concerns:
```
Major Concern 1: [summary]
Major Concern 2: [summary]
...
Minor Concern 1: [summary]
Minor Concern 2: [summary]
...
```

### Step 2: Classify Each Concern

For each concern, determine:
- **(a) Addressable with existing results**: Can point to existing table/figure/analysis
- **(b) Requires new analysis**: Need to run additional robustness check or analysis
- **(c) Disagree — need rebuttal**: Provide evidence-based counter-argument

### Step 3: Generate New Analyses (type b)

For each concern requiring new analysis:
1. Use `/robustness-check` patterns to generate new R scripts
2. Execute the new analysis
3. Generate new figures/tables as needed
4. Record in `deviations.json` if not pre-registered

### Step 4: Draft Response Letter

Generate `referee_response.tex`:

```latex
\documentclass[12pt]{article}
\usepackage[margin=1in]{geometry}
\usepackage{setspace}\onehalfspacing
\usepackage{xcolor}
\usepackage{booktabs}
\usepackage{hyperref}

\definecolor{refereecolor}{rgb}{0.1,0.1,0.6}
\definecolor{responsecolor}{rgb}{0,0,0}

\newcommand{\refereetext}[1]{\textcolor{refereecolor}{\textit{#1}}}
\newcommand{\response}[1]{\textcolor{responsecolor}{#1}}

\begin{document}

\title{Response to Referee Report}
\author{}
\date{\today}
\maketitle

We thank the referee for their careful reading and constructive suggestions.
We address each concern below.

\section*{Major Concerns}

\subsection*{Major Concern 1}

\refereetext{[Quote or paraphrase the referee's concern]}

\response{[Our response. Be specific, reference exact tables/figures/numbers.
If new analysis was conducted, describe it and present results.
If we disagree, provide evidence-based reasoning.]}

\subsection*{Major Concern 2}
...

\section*{Minor Concerns}

\subsection*{Minor Concern 1}
...

\section*{Summary of Changes}

\begin{itemize}
\item Added [new analysis] to address Major Concern 1 (new Table X, Figure Y)
\item Revised Section Z to clarify [issue] per Minor Concern 3
\item [List all changes made to the paper]
\end{itemize}

\end{document}
```

### Step 5: Track Changes in Paper

For each change made to `paper.tex`:
- Note the section and what was modified
- If substantial new content, mark clearly

## Response Tone

- **Respectful**: "We thank the referee for this important observation"
- **Specific**: Always reference exact numbers, tables, figures
- **Quantitative**: "The new analysis shows β = 0.032 (SE = 0.013), consistent with our main result of 0.034"
- **Never dismissive**: Even for unreasonable requests, provide evidence-based explanation
- **Constructive**: Frame changes as improvements, not concessions

## Response Patterns

### For "identification not credible" concerns:
- Present additional robustness checks
- Show pre-treatment trend evidence
- Discuss institutional details supporting exogeneity
- Acknowledge remaining limitations honestly

### For "missing robustness check" requests:
- Run the requested check via `/robustness-check`
- Present results clearly
- Discuss whether and how results change

### For "writing clarity" concerns:
- Revise the specific passages
- Quote the new text in the response

### For "data concerns":
- Provide additional sample statistics
- Run analysis on subsamples
- Document data construction more carefully

## Output

- `referee_response.tex` — Complete response letter
- New R scripts in `code/` (07_*, 08_*) for any new analyses
- New figures in `figures/` and tables in `tables/`
- Updated `deviations.json` for post-hoc analyses
- List of changes to `paper.tex` (user should review before applying)

## After Completion

Summarize: how many concerns addressed, what new analyses were run, what paper changes are recommended.
