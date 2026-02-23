# Public Data Sources — API Reference

## BLS Quarterly Census of Employment and Wages (QCEW)

The primary data source for APEP labor market papers. Covers employment, wages, and establishments by industry and geography.

### Key Facts
- **Granularity:** State × quarter × industry (NAICS)
- **Coverage:** 2014-present via API; historical via flat files
- **API key:** Not required
- **Rate limit:** Undocumented; use `Sys.sleep(0.5)` between calls

### API Endpoint

```
https://data.bls.gov/cew/data/api/{YEAR}/a/industry/{NAICS_CODE}.csv
```

- `{YEAR}`: 4-digit year (2014-2023)
- `{NAICS_CODE}`: Industry code (e.g., `62` for Healthcare, `621` for Ambulatory)

### Common NAICS Codes

| Code | Industry | Use Case |
|------|----------|----------|
| `10` | Total, all industries | Baseline |
| `44-45` | Retail Trade | Placebo |
| `62` | Health Care and Social Assistance | Healthcare papers |
| `621` | Ambulatory Health Care | Telehealth-intensive |
| `622` | Hospitals | Physical-presence healthcare |
| `72` | Accommodation and Food Services | Placebo |
| `23` | Construction | Infrastructure papers |
| `31-33` | Manufacturing | Trade/industrial policy |

### R Code Pattern

```r
fetch_qcew_industry <- function(year, industry_code) {
  url <- sprintf(
    "https://data.bls.gov/cew/data/api/%d/a/industry/%s.csv",
    year, industry_code
  )
  cat(sprintf("  Fetching QCEW: year=%d, industry=%s ... ", year, industry_code))

  result <- tryCatch({
    resp <- httr::GET(url, httr::timeout(60))
    if (httr::status_code(resp) == 200) {
      txt <- httr::content(resp, as = "text", encoding = "UTF-8")
      df <- read.csv(textConnection(txt), stringsAsFactors = FALSE)
      cat(sprintf("OK (%d rows)\n", nrow(df)))
      return(df)
    } else {
      cat(sprintf("HTTP %d\n", httr::status_code(resp)))
      return(NULL)
    }
  }, error = function(e) {
    cat(sprintf("ERROR: %s\n", e$message))
    return(NULL)
  })
  return(result)
}

# Usage
years <- 2014:2023
industries <- list(healthcare = "62", ambulatory = "621", placebo = "72")

for (ind_name in names(industries)) {
  for (yr in years) {
    df <- fetch_qcew_industry(yr, industries[[ind_name]])
    Sys.sleep(0.5)  # Rate limiting
  }
}
```

### Filtering State-Level Data

QCEW returns all geographies. Filter for state totals:

```r
qcew_states <- raw_data %>%
  filter(
    nchar(area_fips) == 5,
    substr(area_fips, 3, 5) == "000",           # State-level (SS000)
    !substr(area_fips, 1, 1) %in% c("C", "U")  # Exclude combined/unknown
  ) %>%
  mutate(state_fips = substr(area_fips, 1, 2))

# Aggregate across ownership types (own_code: 1=Fed, 2=State, 3=Local, 5=Private)
qcew_panel <- qcew_states %>%
  group_by(state_fips, year, industry_label) %>%
  summarise(
    employment = sum(as.numeric(annual_avg_emplvl), na.rm = TRUE),
    establishments = sum(as.numeric(annual_avg_estabs), na.rm = TRUE),
    total_wages = sum(as.numeric(total_annual_wages), na.rm = TRUE),
    avg_pay = total_wages / employment,
    .groups = "drop"
  )
```

---

## FRED (Federal Reserve Economic Data)

Macro-level time series. Useful for controls and context.

### Key Facts
- **Granularity:** National/state, monthly/quarterly/annual
- **API key:** Required for API access (free registration)
- **R package:** `fredr`

### Common Series IDs

| Series | Description | Frequency |
|--------|-------------|-----------|
| `UNRATE` | National unemployment rate | Monthly |
| `GDPC1` | Real GDP | Quarterly |
| `CPIAUCSL` | CPI (urban consumers) | Monthly |
| `FEDFUNDS` | Federal funds rate | Monthly |
| `{ST}UR` | State unemployment (e.g., `CAUR`) | Monthly |
| `{ST}NGSP` | State GDP (e.g., `CANGSP`) | Annual |

### R Code Pattern

```r
# Using fredr package
library(fredr)
fredr_set_key(Sys.getenv("FRED_API_KEY"))

# Single series
data <- fredr(
  series_id = "UNRATE",
  observation_start = as.Date("2010-01-01"),
  observation_end = as.Date("2023-12-31"),
  frequency = "q"   # quarterly
)

# Multiple state series
state_abbrs <- c("CA", "NY", "TX", "FL")
state_unemp <- map_dfr(state_abbrs, function(st) {
  fredr(series_id = paste0(st, "UR"),
        observation_start = as.Date("2010-01-01")) %>%
    mutate(state = st)
})
```

### Direct API (without fredr)

```r
fetch_fred <- function(series_id, start = "2010-01-01") {
  api_key <- Sys.getenv("FRED_API_KEY")
  url <- sprintf(
    "https://api.stlouisfed.org/fred/series/observations?series_id=%s&api_key=%s&file_type=json&observation_start=%s",
    series_id, api_key, start
  )
  resp <- httr::GET(url, httr::timeout(30))
  json <- httr::content(resp, as = "text", encoding = "UTF-8")
  obs <- jsonlite::fromJSON(json)$observations
  tibble(
    date = as.Date(obs$date),
    value = as.numeric(obs$value)
  )
}
```

---

## Census ACS (American Community Survey)

Demographics, income, commuting, housing characteristics.

### Key Facts
- **Granularity:** State/county/tract, annual
- **API key:** Recommended (free, increases rate limits)
- **1-year estimates:** Available for areas with population ≥ 65,000
- **Note:** 2020 1-year ACS not available (COVID disruption)

### Common Tables

| Table | Variables | Description |
|-------|-----------|-------------|
| `B08301` | `_001E` (total), `_021E` (WFH) | Means of transportation to work |
| `B01001` | `_001E` | Total population |
| `B19013` | `_001E` | Median household income |
| `B23025` | `_001E` (pop 16+), `_005E` (unemployed) | Employment status |
| `S2401` | Various | Occupation by industry |

### R Code Pattern

```r
census_key <- Sys.getenv("CENSUS_API_KEY")

fetch_acs <- function(year, table_vars, geography = "state") {
  vars_str <- paste(table_vars, collapse = ",")
  url <- sprintf(
    "https://api.census.gov/data/%d/acs/acs1?get=NAME,%s&for=%s:*",
    year, vars_str, geography
  )
  if (census_key != "") url <- paste0(url, "&key=", census_key)

  resp <- httr::GET(url, httr::timeout(30))
  if (httr::status_code(resp) != 200) return(NULL)

  json <- httr::content(resp, as = "text", encoding = "UTF-8")
  mat <- jsonlite::fromJSON(json)
  df <- as.data.frame(mat[-1, ], stringsAsFactors = FALSE)
  names(df) <- mat[1, ]
  df$year <- year
  return(df)
}

# Work-from-home data
acs_years <- 2014:2023
acs_wfh <- map_dfr(setdiff(acs_years, 2020), function(yr) {
  Sys.sleep(2)  # Rate limiting
  fetch_acs(yr, c("B08301_001E", "B08301_021E"))
})

acs_panel <- acs_wfh %>%
  mutate(
    total_workers = as.numeric(B08301_001E),
    wfh_workers = as.numeric(B08301_021E),
    wfh_share = wfh_workers / total_workers
  )
```

---

## Census PUMS (Public Use Microdata Sample)

Individual-level census microdata. Useful for worker-level analysis.

### Key Facts
- **Granularity:** Individual records with PUMA-level geography
- **No API key needed** for basic queries
- **Large files:** Consider using `data.table::fread()` for speed

### API Endpoint

```
https://api.census.gov/data/{YEAR}/acs/acs1/pums?get={VARIABLES}&for=state:{FIPS}
```

### R Code Pattern

```r
fetch_pums <- function(year, variables, state_fips = "*") {
  vars_str <- paste(variables, collapse = ",")
  url <- sprintf(
    "https://api.census.gov/data/%d/acs/acs1/pums?get=%s&for=state:%s",
    year, vars_str, state_fips
  )
  resp <- httr::GET(url, httr::timeout(120))
  if (httr::status_code(resp) != 200) return(NULL)

  json <- httr::content(resp, as = "text", encoding = "UTF-8")
  mat <- jsonlite::fromJSON(json)
  df <- as.data.frame(mat[-1, ], stringsAsFactors = FALSE)
  names(df) <- mat[1, ]
  return(df)
}

# Example: workers by industry and WFH status
pums <- fetch_pums(2022, c("PWGTP", "NAICSP", "JWTRNS", "WAGP"))
```

---

## IPUMS (CPS, ACS Extracts)

Harmonized microdata across years. Best for consistent longitudinal analysis.

### Key Facts
- **Registration required:** Apply at ipums.org
- **API:** IPUMS API requires approval and token
- **Advantage:** Consistent variable definitions across decades

### R Code Pattern (with ipumsr)

```r
library(ipumsr)

# Read downloaded extract
ddi <- read_ipums_ddi("cps_extract.xml")
data <- read_ipums_micro(ddi)

# API-based extraction (requires token)
set_ipums_api_key(Sys.getenv("IPUMS_API_KEY"))
extract <- define_extract_cps(
  description = "Monthly CPS for labor analysis",
  samples = paste0("cps", 2014:2023, "_03s"),
  variables = c("AGE", "SEX", "RACE", "EDUC", "EMPSTAT", "OCC", "IND")
)
submitted <- submit_extract(extract)
```

---

## Data Source Selection Guide

| Research Topic | Primary Source | Secondary Source | Placebo Industry |
|---------------|---------------|------------------|------------------|
| Healthcare employment | QCEW (NAICS 62) | ACS (occupation) | Accommodation (72) |
| Labor market effects | QCEW | CPS (IPUMS) | Manufacturing (31-33) |
| Wages/earnings | QCEW | ACS (B19013) | Retail (44-45) |
| Remote work | ACS (B08301) | CPS (supplement) | — |
| Housing | ACS (B25001+) | Zillow ZTRAX | — |
| Criminal justice | FBI UCR | BJS | — |
| Education | NCES/IPEDS | ACS (S1501) | — |
| Macro controls | FRED | BEA | — |

### API Key Environment Variables

Set these in your shell or `.env` file:

```bash
export FRED_API_KEY="your_key_here"
export CENSUS_API_KEY="your_key_here"
export IPUMS_API_KEY="your_key_here"
export BLS_API_KEY="your_key_here"   # Optional, increases rate limits
```
