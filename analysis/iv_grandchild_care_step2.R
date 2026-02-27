# Stepwise IV checks (Step 2):
# - Re-estimate 2SLS under (a) age<=60 and (b) care switchers only.
# - Keep the IV specification small: instrument care and care*female by
#   gc_u16_total and gc_u16_total*female, with individual FE + wave FE.
# - Use missing-indicator approach for health controls to avoid listwise deletion.
#
# Usage:
#   Rscript analysis/iv_grandchild_care_step2.R

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

  srh <- if (wave %in% c(2013, 2015)) as.numeric(d$da079) else as.numeric(d$da002)

  adl_vars <- c("db010", "db011", "db012", "db013", "db014", "db015")
  stopifnot(all(adl_vars %in% names(d)))
  adl <- d %>% select(ID, all_of(adl_vars)) %>% mutate(across(all_of(adl_vars), ~ as.numeric(.x)))
  m <- as.matrix(adl[, adl_vars, drop = FALSE])
  adl_n <- rowSums(m > 1, na.rm = TRUE)
  adl_n[apply(m, 1, function(x) all(is.na(x)))] <- NA_real_

  tibble(ID = d$ID, wave = wave, srh = srh, adl_n = adl_n)
}

build_panel <- function(max_age = 70) {
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

  demo %>%
    inner_join(care, by = c("ID", "wave")) %>%
    inner_join(work, by = c("ID", "wave")) %>%
    inner_join(gc, by = c("ID", "wave")) %>%
    left_join(health, by = c("ID", "wave")) %>%
    mutate(
      age = wave - birth_year,
      care_f = care * female,
      z_f = gc_u16_total * female
    ) %>%
    filter(
      !is.na(any_work),
      !is.na(care),
      !is.na(gc_u16_total),
      !is.na(female),
      !is.na(age),
      age <= max_age
    )
}

add_health_miss <- function(df) {
  df %>%
    mutate(
      srh_miss = as.integer(is.na(srh)),
      srh_imp = ifelse(is.na(srh), 3, srh),
      adl_miss = as.integer(is.na(adl_n)),
      adl_imp = ifelse(is.na(adl_n), 0, adl_n)
    )
}

run_iv <- function(df, label) {
  message("\n==== ", label, " ====")
  message("obs=", nrow(df), ", ids=", dplyr::n_distinct(df$ID), ", female_share=", round(mean(df$female), 3))
  message("care_mean=", round(mean(df$care), 3), ", any_work_mean=", round(mean(df$any_work), 3))

  m0 <- feols(any_work ~ 1 | ID + wave | care + care_f ~ gc_u16_total + z_f, data = df, vcov = ~ID)
  message("\n[IV baseline]")
  print(coeftable(m0))
  print(fitstat(m0, "ivf"))

  df2 <- add_health_miss(df)
  m1 <- feols(
    any_work ~ srh_imp + srh_miss + adl_imp + adl_miss | ID + wave | care + care_f ~ gc_u16_total + z_f,
    data = df2,
    vcov = ~ID
  )
  message("\n[IV + health missing-indicators]")
  print(coeftable(m1))
  print(fitstat(m1, "ivf"))
}

panel70 <- build_panel(max_age = 70)

# (A) age<=60 restriction
panel60 <- panel70 %>% filter(age <= 60)
run_iv(panel60, "Sample restriction: age<=60")

# (B) switchers only: individuals with within-ID change in care across observed waves
care_switch_ids <- panel70 %>%
  group_by(ID) %>%
  summarise(
    n_obs = sum(!is.na(care)),
    care_min = min(care, na.rm = TRUE),
    care_max = max(care, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  filter(n_obs >= 2, care_min < care_max) %>%
  pull(ID)

panel_switch <- panel70 %>% filter(ID %in% care_switch_ids)
run_iv(panel_switch, "Sample restriction: care switchers only")

