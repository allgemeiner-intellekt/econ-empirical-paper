# Initial Research Plan: State Prohibition and the German-American Brewing Elite

## Research Question

Did state prohibition laws destroy the German-American brewing elite, and did this forced elimination of an ethnic enclave economy reduce intergenerational mobility for German-Americans?

## Background

The brewing and distilling industry was the economic cornerstone of German-America in the late 19th century. At its peak (~1914), the US had ~1,400 breweries representing $800 million in capital (roughly $18 billion in 2010 dollars), with 88,000 direct employees and 300,000 in dependent sectors. The industry was overwhelmingly German-American: the Busch, Pabst, Schlitz, Miller, and Yuengling dynasties exemplified an ethnic elite built on a single industry. Between 1881 and 1919, 33 states adopted statewide prohibition before the 18th Amendment, systematically destroying this ethnic elite class.

No economics paper has studied prohibition's effect on ethnic elite composition or intergenerational mobility using quasi-experimental methods.

## Identification Strategy

**Primary design:** Staggered difference-in-differences (DiD) exploiting the differential timing of state prohibition laws across 33 states (1881–1919).

**Treatment:** State adopts statewide prohibition. Binary indicator: 1 if state s has prohibition in effect at census year t.

**Estimator:** Callaway and Sant'Anna (2021) heterogeneity-robust DiD estimator, with not-yet-treated states as the comparison group.

**Secondary design:** Triple-difference (DDD) separating three channels:
- State × Time: effect of prohibition on all workers
- State × German × Time: differential effect on German-Americans
- State × German × Brewing × Time: industry-destruction channel vs. ethnic discrimination

The DDD allows disentangling the industry-specific effect (prohibition destroys brewing) from the ethnic-targeting effect (anti-German WWI sentiment), since WWI sentiment should affect ALL German-Americans equally, while prohibition specifically targets those in brewing.

## Exposure Alignment

- **Who is treated:** Working-age adults in states that adopted prohibition, with German-born/German-origin workers and brewing industry workers as the most directly affected subpopulations.
- **Primary estimand:** ATT on German-American occupational standing (OCCSCORE percentile) in prohibition states.
- **Placebo population:** Non-German workers in non-brewing occupations (should not be differentially affected).
- **Design:** DiD (primary) + DDD (mechanism isolation).

## Expected Effects and Mechanisms

1. **First stage:** Prohibition should sharply reduce the share of workers in the brewing/beverage industry in dry states.
2. **Occupational downgrading:** German-Americans in dry states should experience occupational downgrading as the brewing industry—their primary ethnic enclave economy—disappears. Those displaced from brewing should move to lower-ranked occupations.
3. **Intergenerational persistence:** If brewing was a pathway to middle/upper-class status for German-Americans, its elimination could REDUCE intergenerational upward mobility for this group.
4. **Counter-intuitive possibility:** Prohibition might have INCREASED overall social mobility by destroying a concentrated elite, even as it harmed the specific ethnic group that comprised that elite.

## Primary Specification

### Main DiD (Outcome: German-born OCCSCORE percentile)
$$Y_{st} = \alpha_s + \gamma_t + \beta \cdot Prohibition_{st} + X_{st}'\delta + \epsilon_{st}$$

Where:
- $Y_{st}$: Mean OCCSCORE percentile of German-born workers in state $s$, census year $t$
- $Prohibition_{st}$: Binary indicator for statewide prohibition in state $s$ at time $t$
- $\alpha_s, \gamma_t$: State and year fixed effects
- $X_{st}$: State-level controls (share foreign-born, urbanization rate, manufacturing employment share)

### DDD Specification (Individual-level)
$$Y_{ist} = \alpha_s + \gamma_t + \beta_1(German_i \times Prohibition_{st}) + \beta_2(Brewer_i \times Prohibition_{st}) + \beta_3(German_i \times Brewer_i \times Prohibition_{st}) + \epsilon_{ist}$$

$\beta_3$ identifies the causal effect of prohibition on German brewers specifically, beyond general anti-German effects and general prohibition effects.

## Power Assessment

- **Census waves:** 1870, 1880, 1900, 1910, 1920 (5 waves; 1890 lost to fire)
- **Pre-treatment periods:** 3 (1870, 1880, 1900) for the main treatment wave (1907+)
- **Treated clusters:** ~28 states adopt 1907–1919
- **Post-treatment periods per cohort:** 1–2 depending on adoption timing
- **Sample size (1% sample):** ~40 million person-years across all waves; ~135,000 German-born per wave
- **Expected MDE:** With 28 treated states and state-level clustering, MDE for a 0.10 SD change in OCCSCORE should be achievable

## Data Sources

1. **IPUMS USA:** 1% samples for 1870, 1880, 1900, 1910, 1920 census years
   - Variables: YEAR, STATEFIP, AGE, SEX, RACE, BPL, MBPL, FBPL, OCC1950, OCCSCORE, IND1950, RELATE, SERIAL

2. **State prohibition adoption dates:** Compiled from:
   - 1922 Encyclopaedia Britannica article on Prohibition
   - Blocker, Fahey & Tyrrell (2003), "Alcohol and Temperance in Modern History"
   - NCSL historical records

## Planned Robustness Checks

1. **Bacon decomposition:** Verify which timing comparisons drive results
2. **Honest DiD:** Sensitivity to pre-trend violations (Rambachan & Roth 2023)
3. **Placebo tests:**
   - Non-German workers in brewing (should be affected by prohibition but not anti-German sentiment)
   - German workers in non-brewing occupations (affected by anti-German sentiment but not prohibition)
   - Female workers (largely excluded from brewing)
4. **Alternative outcomes:** Migration (out-migration of German-Americans from dry states), literacy rates, home ownership
5. **Alternative control groups:** Drop early adopters (Kansas, Maine) to avoid contamination
6. **Permutation inference:** Randomization inference for p-values
