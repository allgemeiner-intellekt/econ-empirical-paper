# Stepwise IV diagnostics (Step 3):
# - Decompose within-person changes in grandchildren-under-16 counts into:
#     (i) births proxy: increase in total # grandchildren
#     (ii) aging-out proxy: under-16 count falls holding total fixed (or implied)
# - Run first-difference (FD) regressions to see which component drives:
#     (a) care changes (first stage intuition)
#     (b) any_work changes (reduced form intuition)
#
# Motivation:
# - If the reduced form is mainly driven by "births", exclusion is more suspect
#   (fertility may respond to grandparents' labor availability).
# - If it is mainly driven by "aging out", exclusion is more plausible.
#
# Usage:
#   Rscript analysis/iv_grandchild_care_step3.R

suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(tidyr)
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

sum_or_na <- function(df, vars) {
  m <- as.matrix(df[, vars, drop = FALSE])
  all_na <- apply(m, 1, function(x) all(is.na(x)))
  s <- rowSums(m, na.rm = TRUE)
  s[all_na] <- NA_real_
  s
}

load_gc_counts <- function(path, wave) {
  d <- read_dta(path)
  cb065 <- names(d)[grepl("^cb065_", names(d))] # total # children each adult child has => total grandchildren
  cb066 <- names(d)[grepl("^cb066_", names(d))] # # under-16 children each adult child has => under-16 grandchildren
  stopifnot(length(cb065) > 0, length(cb066) > 0)

  out <- d %>%
    select(ID, all_of(unique(c(cb065, cb066)))) %>%
    mutate(across(-ID, ~ as.numeric(.x)))

  tibble(
    ID = out$ID,
    wave = wave,
    gc_total = sum_or_na(out, cb065),
    gc_u16_total = sum_or_na(out, cb066)
  )
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
  load_gc_counts("data/temp_2013/Family_Information.dta", 2013),
  load_gc_counts("data/temp_2015/Family_Information.dta", 2015),
  load_gc_counts("data/temp_2018/Family_Information.dta", 2018)
)

panel <- demo %>%
  inner_join(care, by = c("ID", "wave")) %>%
  inner_join(work, by = c("ID", "wave")) %>%
  inner_join(gc, by = c("ID", "wave")) %>%
  mutate(age = wave - birth_year) %>%
  filter(
    !is.na(any_work),
    !is.na(care),
    !is.na(gc_u16_total),
    !is.na(gc_total),
    !is.na(female),
    !is.na(age),
    age <= 70
  ) %>%
  select(ID, wave, female, age, any_work, care, gc_total, gc_u16_total)

message("Panel: obs=", nrow(panel), ", ids=", dplyr::n_distinct(panel$ID))

# Wide -> FD between adjacent waves (2013->2015 and 2015->2018)
wide <- panel %>%
  pivot_wider(
    names_from = wave,
    values_from = c(any_work, care, gc_total, gc_u16_total, age),
    names_sep = "_"
  )

make_fd <- function(df, t0, t1) {
  df %>%
    transmute(
      ID,
      female,
      interval = paste0(t0, "_", t1),
      age0 = .data[[paste0("age_", t0)]],
      age1 = .data[[paste0("age_", t1)]],
      d_any_work = .data[[paste0("any_work_", t1)]] - .data[[paste0("any_work_", t0)]],
      d_care = .data[[paste0("care_", t1)]] - .data[[paste0("care_", t0)]],
      d_gc_total = .data[[paste0("gc_total_", t1)]] - .data[[paste0("gc_total_", t0)]],
      d_gc_u16 = .data[[paste0("gc_u16_total_", t1)]] - .data[[paste0("gc_u16_total_", t0)]]
    ) %>%
    filter(!is.na(d_any_work), !is.na(d_care), !is.na(d_gc_total), !is.na(d_gc_u16))
}

fd <- bind_rows(
  make_fd(wide, 2013, 2015),
  make_fd(wide, 2015, 2018)
) %>%
  mutate(
    # births proxy: positive changes in total grandchildren
    births_hat = pmax(d_gc_total, 0),
    # implied aging-out: births - delta_u16 (capped at >=0)
    aging_out_hat = pmax(births_hat - d_gc_u16, 0),
    pure_aging_out = as.integer(d_gc_total == 0 & d_gc_u16 < 0),
    pure_birth = as.integer(d_gc_total > 0)
  )

message("FD: obs=", nrow(fd), ", ids=", dplyr::n_distinct(fd$ID))

summary_by_interval <- fd %>%
  group_by(interval) %>%
  summarise(
    n = n(),
    births_share = mean(pure_birth),
    aging_out_share = mean(pure_aging_out),
    mean_d_u16 = mean(d_gc_u16),
    mean_births_hat = mean(births_hat),
    mean_aging_out_hat = mean(aging_out_hat),
    .groups = "drop"
  )
print(summary_by_interval)

# FD regressions (cluster by ID, include interval FE)
fd <- fd %>% mutate(female_i = female) # explicit name

message("\n[FD first stage intuition] d_care on births_hat and aging_out_hat (+female interactions)")
fs_fd <- feols(
  d_care ~ births_hat + aging_out_hat + births_hat:female_i + aging_out_hat:female_i | interval,
  data = fd,
  vcov = ~ID
)
print(coeftable(fs_fd))

message("\n[FD reduced form intuition] d_any_work on births_hat and aging_out_hat (+female interactions)")
rf_fd <- feols(
  d_any_work ~ births_hat + aging_out_hat + births_hat:female_i + aging_out_hat:female_i | interval,
  data = fd,
  vcov = ~ID
)
print(coeftable(rf_fd))

# Level reduced form (within FE) as a benchmark: any_work on gc_u16_total (+female interaction)
message("\n[Within FE reduced form benchmark] any_work on gc_u16_total (+female interaction)")
rf_level <- feols(any_work ~ gc_u16_total + gc_u16_total:female | ID + wave, data = panel, vcov = ~ID)
print(coeftable(rf_level))

# Important diagnostic: does the reduced form live among care switchers?
# If the reduced form is present mainly among care *non*-switchers, it suggests
# either (i) exclusion is violated (gc_u16_total affects work via other channels)
# or (ii) the binary care measure is too coarse (intensity changes not captured).
care_stats <- panel %>%
  group_by(ID) %>%
  summarise(
    n = n(),
    care_min = min(care, na.rm = TRUE),
    care_max = max(care, na.rm = TRUE),
    .groups = "drop"
  )
ids_non_switch <- care_stats %>% filter(n >= 2, care_min == care_max) %>% pull(ID)
ids_switch <- care_stats %>% filter(n >= 2, care_min < care_max) %>% pull(ID)

message("\n[Reduced form by care switching status] (within FE)")
message("IDs non-switch=", length(ids_non_switch), ", switch=", length(ids_switch))
rf_non <- feols(any_work ~ gc_u16_total + gc_u16_total:female | ID + wave, data = panel %>% filter(ID %in% ids_non_switch), vcov = ~ID)
rf_swi <- feols(any_work ~ gc_u16_total + gc_u16_total:female | ID + wave, data = panel %>% filter(ID %in% ids_switch), vcov = ~ID)
message("\nRF among care non-switchers:")
print(coeftable(rf_non))
message("\nRF among care switchers:")
print(coeftable(rf_swi))
