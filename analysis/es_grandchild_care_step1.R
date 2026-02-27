# Stepwise checks for Option B (no IV):
# Grandchild care -> female labor supply, focusing on reverse causality diagnostics
# using panel FE + lead ("placebo") tests and a simple pretrend check for late starters.
#
# Data: only CHARLS extracts in this repo (2013/2015/2018).
#
# Usage:
#   Rscript analysis/es_grandchild_care_step1.R

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
      care_gc_bin = case_when(
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

panel <- demo %>%
  inner_join(care, by = c("ID", "wave")) %>%
  inner_join(work, by = c("ID", "wave")) %>%
  left_join(demo_fix, by = "ID") %>%
  mutate(age = wave - birth_year_fixed) %>%
  filter(
    !is.na(any_work),
    !is.na(care_gc_bin),
    !is.na(female_fixed),
    !is.na(age),
    age <= 70
  ) %>%
  arrange(ID, wave)

message("Panel: obs=", nrow(panel), ", ids=", dplyr::n_distinct(panel$ID))

# ---------------------------
# [1] Baseline FE replication
# ---------------------------
message("\n[1] Baseline FE: any_work ~ care + care*female | ID + wave (cluster ID)")
m_fe <- feols(any_work ~ care_gc_bin * female_fixed + i(wave) | ID, data = panel, vcov = ~ID)
print(coeftable(m_fe))

# Also report the female-only coefficient (more directly interpretable).
panel_w <- panel %>% filter(female_fixed == 1)
panel_w60 <- panel_w %>% filter(age <= 60)

message("\n[1b] Women-only FE: any_work ~ care | ID + wave (cluster ID), age<=70")
m_w <- feols(any_work ~ care_gc_bin + i(wave) | ID, data = panel_w, vcov = ~ID)
print(coeftable(m_w))

message("\n[1c] Women-only FE: any_work ~ care | ID + wave (cluster ID), age<=60")
m_w60 <- feols(any_work ~ care_gc_bin + i(wave) | ID, data = panel_w60, vcov = ~ID)
print(coeftable(m_w60))

# --------------------------------
# [2] Lead test for reverse causality
# --------------------------------
# If current labor supply predicts future care (reverse causality),
# then future care should (spuriously) predict current any_work.
panel_lead <- panel %>%
  group_by(ID) %>%
  mutate(care_lead = lead(care_gc_bin)) %>%
  ungroup() %>%
  filter(!is.na(care_lead)) # keeps 2013 and 2015 observations with a next wave

message("\n[2] Lead (placebo) test: any_work_t ~ care_t + care_{t+1} + interactions | ID + wave")
m_lead <- feols(
  any_work ~ care_gc_bin * female_fixed + care_lead + care_lead:female_fixed + i(wave) | ID,
  data = panel_lead,
  vcov = ~ID
)
print(coeftable(m_lead))

# Women-only lead model for the placebo coefficient (future care -> current work).
panel_w_lead <- panel_lead %>% filter(female_fixed == 1)
message("\n[2b] Women-only lead (placebo): any_work_t ~ care_t + care_{t+1} | ID + wave")
m_lead_w <- feols(any_work ~ care_gc_bin + care_lead + i(wave) | ID, data = panel_w_lead, vcov = ~ID)
print(coeftable(m_lead_w))

# ----------------------------------------
# [3] Pretrend check for late starters
# ----------------------------------------
# Late starters: care2015=0 & care2018=1
# Controls:      care2015=0 & care2018=0
# Pretrend outcome: delta any_work 2013->2015
# Main-change outcome: delta any_work 2015->2018
wide <- panel %>%
  select(ID, female_fixed, wave, any_work, care_gc_bin) %>%
  pivot_wider(names_from = wave, values_from = c(any_work, care_gc_bin), names_sep = "_")

needed <- c(
  "any_work_2013", "any_work_2015", "any_work_2018",
  "care_gc_bin_2013", "care_gc_bin_2015", "care_gc_bin_2018"
)
wide_bal <- wide %>%
  filter(if_all(all_of(needed), ~ !is.na(.x)))

late <- wide_bal %>%
  filter(care_gc_bin_2015 == 0) %>%
  mutate(
    treated_late = as.integer(care_gc_bin_2018 == 1),
    d_work_pre = any_work_2015 - any_work_2013,
    d_work_post = any_work_2018 - any_work_2015
  )

message("\n[3] Late starters pretrend check (2013->2015) vs controls (care2015==0)")
message("Late sample: n=", nrow(late), ", treated_late=", sum(late$treated_late))
m_pre <- feols(d_work_pre ~ treated_late + treated_late:female_fixed + female_fixed, data = late, vcov = "hetero")
print(coeftable(m_pre))

message("\n[3b] Late starters main change (2015->2018) vs controls (care2015==0)")
m_post <- feols(d_work_post ~ treated_late + treated_late:female_fixed + female_fixed, data = late, vcov = "hetero")
print(coeftable(m_post))
