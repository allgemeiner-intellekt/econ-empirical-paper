# Stepwise IV checks for:
#   Grandchild care (cf001) -> female labor supply (any_work)
# Using only CHARLS data in this repo.
#
# This script is intentionally small and incremental (Step 1):
# - Construct a plausible IV: number of grandchildren under 16 (sum of cb066_*).
# - Diagnose first-stage strength under different sample/controls handling.
# - Show why "any grandchild under16" dummy is a weak instrument in FE.
#
# Usage:
#   Rscript analysis/iv_grandchild_care_step1.R

suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(fixest)
})

load_demo <- function(path, wave, birth_vars = character()) {
  df <- read_dta(path)

  birth_year <- NULL
  for (v in birth_vars) {
    if (v %in% names(df)) {
      birth_year <- if (is.null(birth_year)) as.numeric(df[[v]]) else dplyr::coalesce(birth_year, as.numeric(df[[v]]))
    }
  }

  tibble(
    ID = df$ID,
    wave = wave,
    female = as.integer(df$ba000_w2_3 == 2),
    birth_year = birth_year
  )
}

load_care <- function(path, wave) {
  read_dta(path) %>%
    transmute(
      ID,
      wave = wave,
      care = case_when(
        as.numeric(cf001) == 1 ~ 1,
        as.numeric(cf001) == 2 ~ 0,
        TRUE ~ NA_real_
      )
    )
}

load_any_work <- function(path, wave) {
  df <- read_dta(path)

  if (wave %in% c(2013, 2015)) {
    return(
      df %>%
        transmute(
          ID,
          wave = wave,
          fa001 = as.numeric(fa001),
          fa002 = as.numeric(fa002)
        ) %>%
        mutate(
          any_work = case_when(
            fa001 == 1 ~ 1,
            fa001 == 2 & fa002 == 1 ~ 1,
            fa001 == 2 & fa002 == 2 ~ 0,
            TRUE ~ NA_real_
          )
        ) %>%
        select(ID, wave, any_work)
    )
  }

  if (wave == 2018) {
    return(
      df %>%
        transmute(
          ID,
          wave = wave,
          fc001 = as.numeric(fc001),
          fa002_w4 = as.numeric(fa002_w4)
        ) %>%
        mutate(
          any_work = case_when(
            fc001 == 1 ~ 1,
            fc001 == 2 & fa002_w4 == 1 ~ 1,
            fc001 == 2 & fa002_w4 == 2 ~ 0,
            TRUE ~ NA_real_
          )
        ) %>%
        select(ID, wave, any_work)
    )
  }

  stop("Unsupported wave for any_work: ", wave)
}

load_gc_u16_total <- function(path, wave) {
  d <- read_dta(path)

  # cb066_*: "How many children aged under 16 does R's No.k living adult child have"
  # i.e., respondent's grandchildren under 16.
  vars <- names(d)[grepl("^cb066_", names(d))]
  stopifnot(length(vars) > 0)

  out <- d %>% select(ID, all_of(vars)) %>% mutate(across(all_of(vars), ~ as.numeric(.x)))
  m <- as.matrix(out[, vars, drop = FALSE])

  total <- rowSums(m, na.rm = TRUE)
  total[apply(m, 1, function(x) all(is.na(x)))] <- NA_real_

  tibble(ID = out$ID, wave = wave, gc_u16_total = total)
}

load_health_controls <- function(path, wave) {
  d <- read_dta(path)

  # SRH is unfortunately very missing in 2013/2015 in this extract.
  srh <- if (wave %in% c(2013, 2015)) as.numeric(d$da079) else as.numeric(d$da002)

  # Simple ADL difficulty count (binary per item: >1 means any difficulty)
  adl_vars <- c("db010", "db011", "db012", "db013", "db014", "db015")
  stopifnot(all(adl_vars %in% names(d)))
  adl <- d %>% select(ID, all_of(adl_vars)) %>% mutate(across(all_of(adl_vars), ~ as.numeric(.x)))
  m <- as.matrix(adl[, adl_vars, drop = FALSE])
  adl_n <- rowSums(m > 1, na.rm = TRUE)
  adl_n[apply(m, 1, function(x) all(is.na(x)))] <- NA_real_

  tibble(ID = d$ID, wave = wave, srh = srh, adl_n = adl_n)
}

demo <- bind_rows(
  load_demo("data/temp_2013/Demographic_Background.dta", 2013, birth_vars = c("ba002_1", "zba002_1")),
  load_demo("data/temp_2015/Demographic_Background.dta", 2015, birth_vars = c("ba002_1", "zba002_1")),
  load_demo("data/temp_2018/Demographic_Background.dta", 2018, birth_vars = c("ba004_w3_1", "ba002_1", "zba002_1"))
)

care <- bind_rows(
  load_care("data/temp_2013/Family_Transfer.dta", 2013),
  load_care("data/temp_2015/Family_Transfer.dta", 2015),
  load_care("data/temp_2018/Family_Transfer.dta", 2018)
)

work <- bind_rows(
  load_any_work("data/temp_2013/Work_Retirement_and_Pension.dta", 2013),
  load_any_work("data/temp_2015/Work_Retirement_and_Pension.dta", 2015),
  load_any_work("data/temp_2018/Work_Retirement.dta", 2018)
)

gc <- bind_rows(
  load_gc_u16_total("data/temp_2013/Family_Information.dta", 2013),
  load_gc_u16_total("data/temp_2015/Family_Information.dta", 2015),
  load_gc_u16_total("data/temp_2018/Family_Information.dta", 2018)
)

health <- bind_rows(
  load_health_controls("data/temp_2013/Health_Status_and_Functioning.dta", 2013),
  load_health_controls("data/temp_2015/Health_Status_and_Functioning.dta", 2015),
  load_health_controls("data/temp_2018/Health_Status_and_Functioning.dta", 2018)
)

base <- demo %>%
  inner_join(care, by = c("ID", "wave")) %>%
  inner_join(work, by = c("ID", "wave")) %>%
  inner_join(gc, by = c("ID", "wave")) %>%
  mutate(
    age = wave - birth_year,
    care_f = care * female,
    z_f = gc_u16_total * female,
    has_gc = as.integer(gc_u16_total > 0),
    has_gc_f = has_gc * female
  ) %>%
  filter(
    !is.na(any_work),
    !is.na(care),
    !is.na(gc_u16_total),
    !is.na(female),
    !is.na(age),
    age <= 70
  )

message("Base sample: obs=", nrow(base), ", ids=", dplyr::n_distinct(base$ID))

message("\n[1] Count-IV (exact-identified): care + care*female ~ gc_u16_total + gc_u16_total*female")
m_count <- feols(any_work ~ 1 | ID + wave | care + care_f ~ gc_u16_total + z_f, data = base, vcov = ~ID)
print(coeftable(m_count))
print(fitstat(m_count, "ivf"))

message("\n[2] Why the dummy instrument is weak in FE: care + care*female ~ has_gc + has_gc*female")
m_dummy <- feols(any_work ~ 1 | ID + wave | care + care_f ~ has_gc + has_gc_f, data = base, vcov = ~ID)
print(coeftable(m_dummy))
print(fitstat(m_dummy, "ivf"))

message("\n[3] Health controls: naive listwise deletion can make IV look weak (diagnostic only)")
base_health <- base %>%
  left_join(health, by = c("ID", "wave"))

miss_by_wave <- base_health %>%
  group_by(wave) %>%
  summarise(
    n = n(),
    srh_miss = mean(is.na(srh)),
    adl_miss = mean(is.na(adl_n)),
    both_nonmiss = mean(!is.na(srh) & !is.na(adl_n)),
    .groups = "drop"
  )
print(miss_by_wave)

with_health_listwise <- base_health %>% filter(!is.na(srh), !is.na(adl_n))
message("Listwise health sample: obs=", nrow(with_health_listwise), ", ids=", dplyr::n_distinct(with_health_listwise$ID))
m_listwise <- feols(any_work ~ srh + adl_n | ID + wave | care + care_f ~ gc_u16_total + z_f, data = with_health_listwise, vcov = ~ID)
print(coeftable(m_listwise))
print(fitstat(m_listwise, "ivf"))

message("\n[4] Health controls with missing indicators (keeps sample, avoids weak-IV-from-missingness artifact)")
with_health_miss <- base_health %>%
  mutate(
    srh_miss = as.integer(is.na(srh)),
    srh_imp = ifelse(is.na(srh), 3, srh),
    adl_miss = as.integer(is.na(adl_n)),
    adl_imp = ifelse(is.na(adl_n), 0, adl_n)
  )
m_miss <- feols(any_work ~ srh_imp + srh_miss + adl_imp + adl_miss | ID + wave | care + care_f ~ gc_u16_total + z_f, data = with_health_miss, vcov = ~ID)
print(coeftable(m_miss))
print(fitstat(m_miss, "ivf"))

