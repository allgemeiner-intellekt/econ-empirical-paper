# Simple screening for CHARLS topic proposals
# - Only uses CHARLS data in this repo
# - Focus: gender equality + causal inference feasibility checks
#
# Usage:
#   Rscript analysis/topic_screening.R

suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(tidyr)
  library(fixest)
})

compute_cesd <- function(df, wave) {
  items <- paste0("dc", sprintf("%03d", 9:18))
  stopifnot(all(items %in% names(df)))

  out <- df %>%
    select(ID, all_of(items)) %>%
    mutate(across(all_of(items), as.numeric))

  # reverse-coded items (per existing notes in this repo)
  out <- out %>%
    mutate(
      dc013 = ifelse(is.na(dc013), NA_real_, 5 - dc013),
      dc016 = ifelse(is.na(dc016), NA_real_, 5 - dc016)
    )

  out %>%
    rowwise() %>%
    mutate(
      cesd_sum = if (all(is.na(c_across(all_of(items))))) NA_real_ else sum(c_across(all_of(items)), na.rm = TRUE)
    ) %>%
    ungroup() %>%
    mutate(wave = wave) %>%
    select(ID, wave, cesd_sum)
}

load_demo <- function(path, wave, birth_vars = character()) {
  df <- read_dta(path)

  birth_year <- NULL
  for (v in birth_vars) {
    if (v %in% names(df)) {
      if (is.null(birth_year)) {
        birth_year <- as.numeric(df[[v]])
      } else {
        birth_year <- dplyr::coalesce(birth_year, as.numeric(df[[v]]))
      }
    }
  }

  tibble(
    ID = df$ID,
    householdID = df$householdID,
    wave = wave,
    female = as.integer(df$ba000_w2_3 == 2),
    birth_year = birth_year
  )
}

load_grandchild_care <- function(path, wave) {
  read_dta(path) %>%
    transmute(
      ID,
      wave = wave,
      care_gc_bin = case_when(
        as.numeric(cf001) == 1 ~ 1L,
        as.numeric(cf001) == 2 ~ 0L,
        TRUE ~ NA_integer_
      )
    )
}

load_any_work <- function(path, wave) {
  df <- read_dta(path)

  if (wave %in% c(2013, 2015)) {
    out <- df %>%
      transmute(
        ID,
        wave = wave,
        fa001 = as.numeric(fa001),
        fa002 = as.numeric(fa002)
      ) %>%
      mutate(
        any_work = case_when(
          fa001 == 1 ~ 1L,
          fa001 == 2 & fa002 == 1 ~ 1L,
          fa001 == 2 & fa002 == 2 ~ 0L,
          TRUE ~ NA_integer_
        )
      ) %>%
      select(ID, wave, any_work)
    return(out)
  }

  if (wave == 2018) {
    out <- df %>%
      transmute(
        ID,
        wave = wave,
        fc001 = as.numeric(fc001),
        fa002_w4 = as.numeric(fa002_w4)
      ) %>%
      mutate(
        any_work = case_when(
          fc001 == 1 ~ 1L,
          fc001 == 2 & fa002_w4 == 1 ~ 1L,
          fc001 == 2 & fa002_w4 == 2 ~ 0L,
          TRUE ~ NA_integer_
        )
      ) %>%
      select(ID, wave, any_work)
    return(out)
  }

  stop("Unsupported wave for any_work: ", wave)
}

load_hip <- function(path, wave) {
  df <- read_dta(path)

  if (wave %in% c(2013, 2015)) {
    return(df %>% transmute(ID, wave = wave, hip = case_when(as.numeric(da025) == 1 ~ 1L, as.numeric(da025) == 2 ~ 0L, TRUE ~ NA_integer_)))
  }
  if (wave == 2018) {
    return(df %>% transmute(ID, wave = wave, hip = case_when(as.numeric(da025_w4) == 1 ~ 1L, as.numeric(da025_w4) == 2 ~ 0L, TRUE ~ NA_integer_)))
  }
  stop("Unsupported wave for hip: ", wave)
}

screen_spouse_hip_fracture_did <- function() {
  message("\n[01] Spouse hip fracture shock -> caregiver CESD (DiD + pretrend)")

  cesd <- bind_rows(
    compute_cesd(read_dta("data/temp_2013/Health_Status_and_Functioning.dta"), 2013),
    compute_cesd(read_dta("data/temp_2015/Health_Status_and_Functioning.dta"), 2015),
    compute_cesd(read_dta("data/temp_2018/Cognition.dta"), 2018)
  )

  hip <- bind_rows(
    load_hip("data/temp_2013/Health_Status_and_Functioning.dta", 2013),
    load_hip("data/temp_2015/Health_Status_and_Functioning.dta", 2015),
    load_hip("data/temp_2018/Health_Status_and_Functioning.dta", 2018)
  )

  demo <- bind_rows(
    load_demo("data/temp_2013/Demographic_Background.dta", 2013),
    load_demo("data/temp_2015/Demographic_Background.dta", 2015),
    load_demo("data/temp_2018/Demographic_Background.dta", 2018)
  )

  ind <- demo %>%
    inner_join(cesd, by = c("ID", "wave")) %>%
    inner_join(hip, by = c("ID", "wave")) %>%
    mutate(
      suffix2 = substr(ID, nchar(ID) - 1, nchar(ID)),
      spouseID = case_when(
        suffix2 == "01" ~ paste0(householdID, "02"),
        suffix2 == "02" ~ paste0(householdID, "01"),
        TRUE ~ NA_character_
      )
    ) %>%
    filter(suffix2 %in% c("01", "02"))

  sp_hip <- hip %>% rename(spouseID = ID, spouse_hip = hip)
  ind2 <- ind %>% left_join(sp_hip, by = c("spouseID", "wave")) %>% filter(!is.na(spouse_hip), !is.na(cesd_sum))

  wide <- ind2 %>%
    select(ID, female, wave, cesd_sum, spouse_hip) %>%
    pivot_wider(names_from = wave, values_from = c(cesd_sum, spouse_hip), names_sep = "_")

  wide_bal <- wide %>%
    filter(
      !is.na(cesd_sum_2013), !is.na(cesd_sum_2015), !is.na(cesd_sum_2018),
      !is.na(spouse_hip_2013), !is.na(spouse_hip_2015), !is.na(spouse_hip_2018)
    )

  wide2 <- wide_bal %>%
    filter(spouse_hip_2013 == 0, spouse_hip_2015 == 0) %>%
    mutate(
      treated = as.integer(spouse_hip_2018 == 1),
      delta_pre = cesd_sum_2015 - cesd_sum_2013,
      delta_post = cesd_sum_2018 - cesd_sum_2015
    )

  message("Eligible N: ", nrow(wide2), " | Treated: ", sum(wide2$treated))

  pre <- feols(delta_pre ~ treated + female, data = wide2, vcov = "hetero")
  post <- feols(delta_post ~ treated + female, data = wide2, vcov = "hetero")

  print(coeftable(pre))
  print(coeftable(post))
}

screen_grandchild_care_fe_any_work <- function(max_age = 70) {
  message("\n[02] Grandchild care -> any_work (Individual FE), max_age=", max_age)

  care <- bind_rows(
    load_grandchild_care("data/temp_2013/Family_Transfer.dta", 2013),
    load_grandchild_care("data/temp_2015/Family_Transfer.dta", 2015),
    load_grandchild_care("data/temp_2018/Family_Transfer.dta", 2018)
  )

  work <- bind_rows(
    load_any_work("data/temp_2013/Work_Retirement_and_Pension.dta", 2013),
    load_any_work("data/temp_2015/Work_Retirement_and_Pension.dta", 2015),
    load_any_work("data/temp_2018/Work_Retirement.dta", 2018)
  )

  demo <- bind_rows(
    load_demo("data/temp_2013/Demographic_Background.dta", 2013, birth_vars = c("ba002_1", "zba002_1")),
    load_demo("data/temp_2015/Demographic_Background.dta", 2015, birth_vars = c("ba002_1", "zba002_1")),
    load_demo("data/temp_2018/Demographic_Background.dta", 2018, birth_vars = c("ba004_w3_1", "ba002_1", "zba002_1"))
  )

  demo_fix <- demo %>%
    group_by(ID) %>%
    summarise(
      female_fixed = first(na.omit(female)),
      birth_year_fixed = first(na.omit(birth_year)),
      .groups = "drop"
    )

  panel <- care %>%
    inner_join(work, by = c("ID", "wave")) %>%
    left_join(demo_fix, by = "ID") %>%
    mutate(age = wave - birth_year_fixed) %>%
    filter(!is.na(care_gc_bin), !is.na(any_work), !is.na(female_fixed), !is.na(age), age <= max_age)

  message("Rows: ", nrow(panel), " | IDs: ", n_distinct(panel$ID))

  m <- feols(any_work ~ care_gc_bin * female_fixed + i(wave) | ID, data = panel, vcov = "hetero")
  print(coeftable(m))
}

screen_grandchild_care_fe_cesd <- function(max_age = 70) {
  message("\n[03] Grandchild care -> CESD (Individual FE), max_age=", max_age)

  cesd <- bind_rows(
    compute_cesd(read_dta("data/temp_2013/Health_Status_and_Functioning.dta"), 2013),
    compute_cesd(read_dta("data/temp_2015/Health_Status_and_Functioning.dta"), 2015),
    compute_cesd(read_dta("data/temp_2018/Cognition.dta"), 2018)
  )

  care <- bind_rows(
    load_grandchild_care("data/temp_2013/Family_Transfer.dta", 2013),
    load_grandchild_care("data/temp_2015/Family_Transfer.dta", 2015),
    load_grandchild_care("data/temp_2018/Family_Transfer.dta", 2018)
  )

  demo <- bind_rows(
    load_demo("data/temp_2013/Demographic_Background.dta", 2013, birth_vars = c("ba002_1", "zba002_1")),
    load_demo("data/temp_2015/Demographic_Background.dta", 2015, birth_vars = c("ba002_1", "zba002_1")),
    load_demo("data/temp_2018/Demographic_Background.dta", 2018, birth_vars = c("ba004_w3_1", "ba002_1", "zba002_1"))
  )

  demo_fix <- demo %>%
    group_by(ID) %>%
    summarise(
      female_fixed = first(na.omit(female)),
      birth_year_fixed = first(na.omit(birth_year)),
      .groups = "drop"
    )

  panel <- cesd %>%
    inner_join(care, by = c("ID", "wave")) %>%
    left_join(demo_fix, by = "ID") %>%
    mutate(age = wave - birth_year_fixed) %>%
    filter(!is.na(cesd_sum), !is.na(care_gc_bin), !is.na(female_fixed), !is.na(age), age <= max_age)

  message("Rows: ", nrow(panel), " | IDs: ", n_distinct(panel$ID))

  m <- feols(cesd_sum ~ care_gc_bin * female_fixed + i(wave) | ID, data = panel, vcov = "hetero")
  print(coeftable(m))
}

main <- function() {
  screen_spouse_hip_fracture_did()
  screen_grandchild_care_fe_any_work(max_age = 70)
  screen_grandchild_care_fe_cesd(max_age = 70)
}

if (sys.nframe() == 0) {
  main()
}

