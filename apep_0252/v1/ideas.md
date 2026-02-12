# Research Ideas

## Idea 1: State Prohibition and the Destruction of the German-American Brewing Elite (1870–1920)

**Policy:** Statewide prohibition laws adopted between 1881 and 1919 by ~33 states before the 18th Amendment. Staggered adoption: Kansas (1881), North Dakota (1889), Georgia/Oklahoma (1907), North Carolina/Mississippi (1908), Tennessee (1909), West Virginia (1912), Colorado/Oregon/Virginia/Washington (1914), Arizona/Arkansas/Idaho/Iowa/South Carolina (1915), Michigan/Montana/Nebraska/South Dakota (1916), Indiana/New Hampshire/New Mexico/Utah (1917), Florida/Nevada/Ohio/Texas/Wyoming (1918), Kentucky (1919).

**Outcome:** IPUMS complete-count census data (1870, 1880, 1900, 1910, 1920). Variables: OCC1950, OCCSCORE, IND1950, BPL (birthplace), MBPL/FBPL (parental birthplace), STATEFIP, AGE, SEX, RELATE. Key outcome: occupational rank (OCCSCORE percentile) of German-born and second-generation German-Americans.

**Identification:** Staggered DiD exploiting differential timing of state prohibition laws. Treatment: state adopts statewide prohibition. Unit: state × census year. Comparison: not-yet-treated states (Callaway & Sant'Anna 2021). Triple-difference (DDD) separating German vs. non-German workers and brewing vs. non-brewing occupations to isolate the industry-destruction channel from anti-German sentiment.

**Why it's novel:** Prohibition is studied for crime, health, and temperance — but not for its effect on ethnic elite formation. The brewing industry was the economic backbone of German-America: ~1,400 breweries, $800M capital, 88,000+ direct employees. Prohibition destroyed this ethnic elite class. No economics paper has studied this with DiD methods.

**Feasibility check:**
- Variation: 28+ states adopt prohibition 1907–1919, staggered adoption ✓
- Data: IPUMS API key available; OCCSCORE, IND1950 (brewing = beverage manufacturing), BPL available for all census years 1870–1920 ✓
- Novelty: No existing APEP paper on this; no published DiD study of prohibition's effect on ethnic elite composition ✓
- Sample size: Full-count census = millions of observations; German-born = hundreds of thousands per wave ✓
- Pre-periods: 3 (1870, 1880, 1900 for 1907+ adopters; 1890 census destroyed by fire) — marginal but standard for historical census DiD
- Treated clusters: ~28 states (1907–1919 wave) ≥ 20 ✓

**DiD Feasibility Screen:**
| Criterion | Assessment |
|-----------|-----------|
| Pre-treatment periods | 3 waves (1870, 1880, 1900) — marginal (1890 census lost to fire) |
| Treated clusters | ~28 states (1907–1919 wave) — STRONG |
| Selection into treatment | Mixed: Southern states (moral/racial), Progressive states (temperance) — MARGINAL |
| Comparison group | ~15 states dry only via 18th Amendment (1920) — adequate |
| Outcome-policy alignment | Prohibition → brewing employment, occupational mobility — STRONG |
| Concurrent policies | WWI anti-German sentiment (1917–18) — DDD design separates channels |


## Idea 2: State Inheritance Tax Adoption and Intergenerational Elite Persistence (1885–1916)

**Policy:** State inheritance/estate taxes adopted by ~43 states between 1826 and 1916 (with most adoption 1885–1916 following New York's 1885 law). By 1916, only 5 states lacked inheritance taxes. Staggered adoption over ~30 years creates DiD variation.

**Outcome:** IPUMS complete-count census data (1880, 1900, 1910, 1920). Measure intergenerational elite persistence via co-resident father-son pairs: probability that sons of high-OCCSCORE fathers maintain top-quintile occupational rank.

**Identification:** Staggered DiD with state inheritance tax adoption as treatment. Outcome: intergenerational occupational rank correlation (higher = more elite persistence). States that adopt inheritance taxes earlier should show LOWER elite persistence if the tax reduces dynastic wealth accumulation.

**Why it's novel:** No existing DiD study of Progressive Era state inheritance taxes. The modern estate tax literature (Young & Varner 2011, Bakija & Slemrod 2004) focuses on behavioral responses. The intergenerational elite persistence angle is completely new.

**Feasibility check:**
- Variation: ~43 states over 30 years — potentially STRONG ✓
- Data: IPUMS co-resident father-son pairs + OCCSCORE ✓
- Novelty: No published DiD on this topic ✓
- CRITICAL BLOCKER: Exact state-by-state adoption dates are NOT freely available online. Would require JSTOR/library access to Bullock (1907) or West (1893). **Cannot verify dates without primary source access.** ✗


## Idea 3: Compulsory Schooling Laws and Elite Occupational Persistence (1852–1918)

**Policy:** Compulsory school attendance laws adopted by 48 states + DC between 1852 (Massachusetts) and 1918 (Mississippi). Well-documented adoption dates available from Clay, Lingwall & Stephens (NBER WP 18477).

**Outcome:** IPUMS complete-count census data. Measure: probability that sons of top-quintile OCCSCORE fathers remain in top quintile, comparing states before vs. after compulsory schooling adoption.

**Identification:** Staggered DiD with compulsory schooling as treatment. Novel outcome: elite persistence rather than returns to schooling. Hypothesis: compulsory schooling could REDUCE elite persistence (by equalizing human capital) or INCREASE it (if elites respond by investing in private education, widening the gap).

**Why it's novel:** Compulsory schooling is heavily studied for returns to education (Acemoglu & Angrist 2000) and internal migration (Rauscher 2022), but NO paper studies its effect on intergenerational elite persistence. The angle is genuinely new.

**Feasibility check:**
- Variation: 48 states, 66 years — STRONG ✓
- Data: IPUMS available ✓
- Novelty: New angle on well-studied policy — MARGINAL (risk of "just another compulsory schooling paper")
- Pre-periods: Many for late adopters (Southern states, 1905–1918) ✓
- Concern: Policy is extensively studied; hard to publish in top journal without dramatically new results


## Idea 4: Civil Service Reform and the Decline of Patronage Elites (1883–1920)

**Policy:** State-level civil service merit system laws adopted at different times. New York (1883), Massachusetts (1884), Illinois (1895), Wisconsin (1905), others through 1920s. Replaced patronage (where political elites controlled government jobs) with merit-based hiring.

**Outcome:** IPUMS census data on government employment shares, occupational composition of government workers.

**Identification:** Staggered DiD. Treatment: state adopts civil service merit law. Outcome: change in socioeconomic composition of government workers (measured by OCCSCORE of government employees).

**Why it's novel:** Limited economics literature on civil service reform's effects on who holds government jobs. The political science literature studies bureaucratic quality but not the distributional consequences for patronage elites.

**Feasibility check:**
- Variation: Need to verify exact dates for 20+ states — UNCERTAIN
- Data: IPUMS government employment indicators available ✓
- Novelty: Genuinely new angle ✓
- BLOCKER: Exact state adoption dates not readily available. Industry/class-of-worker variables in IPUMS may not cleanly identify government workers before 1940. ✗
