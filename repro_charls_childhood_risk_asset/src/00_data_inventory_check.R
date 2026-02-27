#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(haven)
})

root_dir <- "repro_charls_childhood_risk_asset"
data_dir <- "data"
output_dir <- file.path(root_dir, "output")
logs_dir <- file.path(root_dir, "logs")

dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(logs_dir, recursive = TRUE, showWarnings = FALSE)

wave2018_dir <- file.path(data_dir, "temp_2018")
lh_file <- file.path(data_dir, "H_CHARLS_LH_a.dta")

stopifnot(dir.exists(wave2018_dir))
stopifnot(file.exists(lh_file))

wave_files <- list.files(wave2018_dir, pattern = "dta$", full.names = TRUE)
wave_files <- sort(wave_files)

scan_file <- function(path) {
  out <- list(
    file = basename(path),
    path = path,
    readable = FALSE,
    nrow = NA_integer_,
    ncol = NA_integer_,
    has_ID = FALSE,
    has_householdID = FALSE,
    has_communityID = FALSE,
    id_missing = NA_integer_,
    id_unique = NA_integer_,
    id_duplicated = NA_integer_
  )

  dat <- tryCatch(read_dta(path), error = function(e) e)
  if (inherits(dat, "error")) {
    return(as.data.frame(out, stringsAsFactors = FALSE))
  }

  out$readable <- TRUE
  out$nrow <- nrow(dat)
  out$ncol <- ncol(dat)
  nm <- names(dat)

  out$has_ID <- "ID" %in% nm
  out$has_householdID <- "householdID" %in% nm
  out$has_communityID <- "communityID" %in% nm

  if (out$has_ID) {
    ids <- dat$ID
    out$id_missing <- sum(is.na(ids))
    out$id_unique <- length(unique(ids))
    out$id_duplicated <- out$nrow - out$id_unique
  }

  as.data.frame(out, stringsAsFactors = FALSE)
}

wave_inventory <- do.call(
  rbind,
  lapply(wave_files, scan_file)
)

lh <- read_dta(lh_file)
lh_names <- names(lh)

required_vars <- c(
  "ID", "householdID", "communityID",
  "rachchlt", "ramischlth", "rachbedhlth", "rachhospital", "rachhospital3", "rachvaccine",
  "ramomoccup_c", "radadoccup_c",
  "familystarved", "nofood"
)

lh_var_inventory <- data.frame(
  variable = required_vars,
  exists = required_vars %in% lh_names,
  stringsAsFactors = FALSE
)

sample_info_file <- file.path(wave2018_dir, "Sample_Infor.dta")
stopifnot(file.exists(sample_info_file))
sample_info <- read_dta(sample_info_file)

household_files <- wave_inventory$file[!wave_inventory$has_ID & wave_inventory$readable]
household_key_inventory <- data.frame(
  file = character(),
  nrow = integer(),
  householdID_missing = integer(),
  householdID_unique = integer(),
  householdID_duplicated = integer(),
  stringsAsFactors = FALSE
)

if (length(household_files) > 0) {
  for (f in household_files) {
    dat <- read_dta(file.path(wave2018_dir, f))
    hh <- dat$householdID
    household_key_inventory <- rbind(
      household_key_inventory,
      data.frame(
        file = f,
        nrow = nrow(dat),
        householdID_missing = sum(is.na(hh)),
        householdID_unique = length(unique(hh)),
        householdID_duplicated = nrow(dat) - length(unique(hh)),
        stringsAsFactors = FALSE
      )
    )
  }
}

id_2018 <- unique(sample_info$ID)
id_lh <- unique(lh$ID)
id_overlap <- intersect(id_2018, id_lh)

summary_lines <- c(
  sprintf("Generated at: %s", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
  "",
  "[1] 2018 wave module readability",
  sprintf("Total 2018 .dta files: %d", nrow(wave_inventory)),
  sprintf("Readable files: %d", sum(wave_inventory$readable)),
  sprintf("Unreadable files: %d", sum(!wave_inventory$readable)),
  sprintf("Files with ID key: %d", sum(wave_inventory$has_ID, na.rm = TRUE)),
  sprintf("Files without ID key: %d", sum(!wave_inventory$has_ID, na.rm = TRUE)),
  "",
  "[1.1] Household-level files (without ID) key quality",
  if (nrow(household_key_inventory) > 0) {
    paste(
      apply(
        household_key_inventory,
        1,
        function(x) {
          sprintf(
            "%s: nrow=%s, householdID_missing=%s, householdID_duplicated=%s",
            x[["file"]], x[["nrow"]], x[["householdID_missing"]], x[["householdID_duplicated"]]
          )
        }
      ),
      collapse = " | "
    )
  } else {
    "No household-level files found."
  },
  "",
  "[2] Life History file quality",
  sprintf("Life History file: %s", lh_file),
  sprintf("Rows: %d", nrow(lh)),
  sprintf("Columns: %d", ncol(lh)),
  sprintf("ID missing: %d", sum(is.na(lh$ID))),
  sprintf("ID unique: %d", length(unique(lh$ID))),
  "",
  "[3] 2018-LH ID linkage",
  sprintf("2018 Sample_Infor unique ID: %d", length(id_2018)),
  sprintf("Life History unique ID: %d", length(id_lh)),
  sprintf("Overlap ID count: %d", length(id_overlap)),
  sprintf("LH covered by 2018 Sample_Infor: %.2f%%", 100 * length(id_overlap) / length(id_lh)),
  sprintf("2018 Sample_Infor covered by LH: %.2f%%", 100 * length(id_overlap) / length(id_2018)),
  "",
  "[4] Key variable availability in Life History",
  sprintf("Available vars: %s", paste(lh_var_inventory$variable[lh_var_inventory$exists], collapse = ", ")),
  sprintf("Missing vars: %s", paste(lh_var_inventory$variable[!lh_var_inventory$exists], collapse = ", "))
)

writeLines(summary_lines, con = file.path(logs_dir, "data_inventory_summary.log"))

write.csv(
  wave_inventory,
  file.path(output_dir, "data_inventory_2018_modules.csv"),
  row.names = FALSE,
  na = ""
)

write.csv(
  lh_var_inventory,
  file.path(output_dir, "data_inventory_lh_keyvars.csv"),
  row.names = FALSE
)

if (nrow(household_key_inventory) > 0) {
  write.csv(
    household_key_inventory,
    file.path(output_dir, "data_inventory_2018_household_keys.csv"),
    row.names = FALSE
  )
}

cat(paste(summary_lines, collapse = "\n"), "\n")
