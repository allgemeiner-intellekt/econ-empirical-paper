## 01_fetch_data.R — Construct state-year panel from published Census data
## APEP-0241: State Prohibition and the German-American Brewing Elite
##
## Data Sources (all published government statistics):
##   1. Gibson & Jung (2006), "Historical Census Statistics on the Foreign-Born
##      Population of the United States: 1850-2000", Census Bureau WP-81, Table 14.
##      — Total population and foreign-born by state, 1870-1920.
##   2. Census of Manufactures microdata, cmfdata.org (Hornbeck et al. 2025)
##      — Brewery establishments by state, 1870.
##   3. U.S. Census Bureau, Fourteenth Census (1920), Vol. II, Ch. VI, Table 6.
##      — German-born population by state, 1920.
##   4. Encyclopaedia Britannica (1922); Blocker, Fahey & Tyrrell (2003)
##      — State prohibition adoption dates.

source("00_packages.R")

data_dir <- file.path("..", "data")
dir.create(data_dir, showWarnings = FALSE)

# ====================================================================
# 1. STATE PROHIBITION ADOPTION DATES
# ====================================================================
# Year = effective year of statewide prohibition law
# Sources: 1922 Encyclopaedia Britannica; Cherrington (1920);
#          Blocker, Fahey & Tyrrell (2003); Okrent (2010)

prohibition_dates <- data.table(
  state_abbr = c(
    "ME", "KS", "ND", "OK", "GA", "MS", "NC", "AL", "TN",
    "WV", "CO", "OR", "VA", "WA",
    "AZ", "AR", "ID", "IA", "SC",
    "MI", "MT", "NE", "SD",
    "IN", "NH", "NM", "UT",
    "FL", "NV", "OH", "TX", "WY", "KY"
  ),
  prohibition_year = c(
    1851, 1881, 1889, 1907, 1908, 1908, 1908, 1909, 1909,
    1914, 1916, 1916, 1916, 1916,
    1915, 1916, 1916, 1916, 1916,
    1918, 1918, 1917, 1917,
    1918, 1917, 1918, 1917,
    1919, 1919, 1919, 1919, 1919, 1920
  )
)

# ====================================================================
# 2. STATE POPULATION DATA (Gibson & Jung 2006, Table 14)
# ====================================================================
# Total population and foreign-born by state, decennial census 1870-1920
# Source: Census Bureau Working Paper No. 81, Table 14

# Build state population panel from published data
# Format: state_abbr, year, total_pop, foreign_born

make_row <- function(abbr, y, tot, fb) {
  data.table(state_abbr = abbr, year = y, total_pop = tot, foreign_born = fb)
}

pop_list <- list()

# --- 1920 and 1910 ---
# Gibson & Jung Table 14, rows for 1920 and 1910
s20_10 <- list(
  # state_abbr, pop_1920, fb_1920, pop_1910, fb_1910
  c("ME", 768014, 107814, 742371, 110562),
  c("NH", 443083, 91397, 430572, 96667),
  c("VT", 352428, 44558, 355956, 49921),
  c("MA", 3852356, 1088548, 3366416, 1059245),
  c("RI", 604397, 175189, 542610, 179141),
  c("CT", 1380631, 378439, 1114756, 329574),
  c("NY", 10385227, 2825375, 9113614, 2748011),
  c("NJ", 3155900, 742486, 2537167, 660788),
  c("PA", 8720017, 1392557, 7665111, 1442374),
  c("OH", 5759394, 680452, 4767121, 598374),
  c("IN", 2930390, 151328, 2700876, 159663),
  c("IL", 6485280, 1210584, 5638591, 1205314),
  c("MI", 3668412, 729292, 2810173, 597550),
  c("WI", 2632067, 460485, 2333860, 512865),
  c("MN", 2387125, 486795, 2075708, 543595),
  c("IA", 2404021, 225994, 2224771, 273765),
  c("MO", 3404055, 186835, 3293335, 229779),
  c("ND", 646872, 131863, 577056, 156654),
  c("SD", 636547, 82534, 583888, 100790),
  c("NE", 1296372, 150665, 1192214, 176662),
  c("KS", 1769257, 110967, 1690949, 135450),
  c("DE", 223003, 19901, 202322, 17492),
  c("MD", 1449661, 103179, 1295346, 104944),
  c("DC", 437571, 29365, 331069, 24902),
  c("VA", 2309187, 31705, 2061612, 27057),
  c("WV", 1463701, 62105, 1221119, 57218),
  c("NC", 2559123, 7272, 2206287, 6092),
  c("SC", 1683724, 6582, 1515400, 6179),
  c("GA", 2895832, 16564, 2609121, 15477),
  c("FL", 968470, 53864, 752619, 40633),
  c("KY", 2416630, 30906, 2289905, 40162),
  c("TN", 2337885, 15648, 2184789, 18607),
  c("AL", 2348174, 18027, 2138093, 19286),
  c("MS", 1790618, 8408, 1797114, 9770),
  c("AR", 1752204, 14137, 1574449, 17046),
  c("LA", 1798509, 46427, 1656388, 52766),
  c("OK", 2028283, 40432, 1657155, 40442),
  c("TX", 4663228, 363832, 3896542, 241938),
  c("MT", 548889, 95591, 376053, 94713),
  c("ID", 431866, 40747, 325594, 42578),
  c("WY", 194402, 26567, 145965, 29020),
  c("CO", 939629, 119138, 799024, 129587),
  c("NM", 360350, 29808, 327301, 23146),
  c("AZ", 334162, 80566, 204354, 48765),
  c("UT", 449396, 59200, 373351, 65822),
  c("NV", 77407, 16003, 81875, 19691),
  c("WA", 1356621, 265292, 1141990, 256241),
  c("OR", 783389, 107644, 672765, 113136),
  c("CA", 3426861, 757625, 2377549, 586432)
)

for (s in s20_10) {
  pop_list <- c(pop_list, list(
    make_row(s[1], 1920, as.numeric(s[2]), as.numeric(s[3])),
    make_row(s[1], 1910, as.numeric(s[4]), as.numeric(s[5]))
  ))
}

# --- 1900 and 1890 ---
s00_90 <- list(
  c("ME", 694466, 93330, 661086, 78961),
  c("NH", 411588, 88107, 376530, 72340),
  c("VT", 343641, 44747, 332422, 44088),
  c("MA", 2805346, 846324, 2238943, 657137),
  c("RI", 428556, 134519, 345506, 106305),
  c("CT", 908420, 238210, 746258, 183601),
  c("NY", 7268894, 1900425, 5997853, 1571050),
  c("NJ", 1883669, 431884, 1444933, 328975),
  c("PA", 6302115, 985250, 5258014, 845720),
  c("OH", 4157545, 458734, 3672316, 459293),
  c("IN", 2516462, 142121, 2192404, 146205),
  c("IL", 4821550, 966747, 3826351, 842347),
  c("MI", 2420982, 541653, 2093889, 543880),
  c("WI", 2069042, 515971, 1686880, 519199),
  c("MN", 1751394, 505318, 1301826, 467356),
  c("IA", 2231853, 305920, 1911896, 324069),
  c("MO", 3106665, 216379, 2679184, 234869),
  c("ND", 319146, 113091, 182719, 81461),
  c("SD", 401570, 88508, 328808, 91055),
  c("NE", 1066300, 177347, 1058910, 202542),
  c("KS", 1470495, 126685, 1427096, 147838),
  c("DE", 184735, 13810, 168493, 13161),
  c("MD", 1188044, 93934, 1042390, 94296),
  c("DC", 278718, 20119, 230392, 18770),
  c("VA", 1854184, 19461, 1655980, 18374),
  c("WV", 958800, 22451, 762794, 18883),
  c("NC", 1893810, 4492, 1617947, 3702),
  c("SC", 1340316, 5528, 1151149, 6270),
  c("GA", 2216331, 12403, 1837353, 12137),
  c("FL", 528542, 23832, 391422, 22932),
  c("KY", 2147174, 50249, 1858635, 59356),
  c("TN", 2020616, 17746, 1767518, 20029),
  c("AL", 1828697, 14592, 1513017, 14777),
  c("MS", 1551270, 7981, 1289600, 7952),
  c("AR", 1311564, 14289, 1128179, 14264),
  c("LA", 1381625, 52903, 1118587, 49747),
  c("OK", 790391, 20538, 61834, 2740),
  c("TX", 3048710, 179357, 2235523, 152956),
  c("MT", 243329, 67067, 132159, 43096),
  c("ID", 161772, 24604, 84385, 17456),
  c("WY", 92531, 17415, 60705, 14913),
  c("CO", 539700, 91155, 412198, 83990),
  c("NM", 195310, 13625, 153593, 11259),
  c("AZ", 122931, 24233, 59620, 18795),
  c("UT", 276749, 53777, 207905, 53064),
  c("NV", 42335, 10093, 45761, 14706),
  c("WA", 518103, 111364, 349390, 90005),
  c("OR", 413536, 65748, 313767, 57317),
  c("CA", 1485053, 367240, 1208130, 366309)
)

for (s in s00_90) {
  pop_list <- c(pop_list, list(
    make_row(s[1], 1900, as.numeric(s[2]), as.numeric(s[3])),
    make_row(s[1], 1890, as.numeric(s[4]), as.numeric(s[5]))
  ))
}

# --- 1880 and 1870 ---
s80_70 <- list(
  c("ME", 648936, 58883, 626915, 48881),
  c("NH", 346991, 46294, 318300, 29611),
  c("VT", 332286, 40959, 330551, 47155),
  c("MA", 1783085, 443491, 1457351, 353319),
  c("RI", 276531, 73993, 217353, 55396),
  c("CT", 622700, 129992, 537454, 113639),
  c("NY", 5082871, 1211379, 4382759, 1138353),
  c("NJ", 1131116, 221700, 906096, 188943),
  c("PA", 4282891, 587829, 3521951, 545309),
  c("OH", 3198062, 394943, 2665260, 372493),
  c("IN", 1978301, 144178, 1680637, 141474),
  c("IL", 3077871, 583576, 2539891, 515198),
  c("MI", 1636937, 388508, 1184059, 268010),
  c("WI", 1315497, 405425, 1054670, 364499),
  c("MN", 780773, 267676, 439706, 160697),
  c("IA", 1624615, 261650, 1194020, 204692),
  c("MO", 2168380, 211578, 1721295, 222267),
  c("ND", NA, NA, NA, NA),  # Dakota Territory combined
  c("SD", 135177, 51795, 14181, 4815),  # Dakota Territory in 1870
  c("NE", 452402, 97414, 122993, 30748),
  c("KS", 996096, 110086, 364399, 48392),
  c("DE", 146608, 9468, 125015, 9136),
  c("MD", 934943, 82806, 780894, 83412),
  c("DC", 177624, 17122, 131700, 16254),
  c("VA", 1512565, 14696, 1225163, 13754),
  c("WV", 618457, 18265, 442014, 17091),
  c("NC", 1399750, 3742, 1071361, 3029),
  c("SC", 995577, 7686, 705606, 8074),
  c("GA", 1542180, 10564, 1184109, 11127),
  c("FL", 269493, 9909, 187748, 4967),
  c("KY", 1648690, 59517, 1321011, 63398),
  c("TN", 1542359, 16702, 1258520, 19316),
  c("AL", 1262505, 9734, 996992, 9962),
  c("MS", 1131597, 9209, 827922, 11191),
  c("AR", 802525, 10350, 484471, 5026),
  c("LA", 939946, 54146, 726915, 61827),
  c("OK", NA, NA, NA, NA),  # Not a state yet
  c("TX", 1591749, 114616, 818579, 62411),
  c("MT", 39159, 11521, 20595, 7979),
  c("ID", 32610, 9974, 14999, 7885),
  c("WY", 20789, 5850, 9118, 3513),
  c("CO", 194327, 39790, 39864, 6599),
  c("NM", 119565, 8051, 91874, 5620),
  c("AZ", 40440, 16049, 9658, 5809),
  c("UT", 143963, 43994, 86786, 30702),
  c("NV", 62266, 25653, 42491, 18801),
  c("WA", 75116, 15803, 23955, 5024),
  c("OR", 174768, 30503, 90923, 11600),
  c("CA", 864694, 292874, 560247, 209831)
)

for (s in s80_70) {
  pop_list <- c(pop_list, list(
    make_row(s[1], 1880, as.numeric(s[2]), as.numeric(s[3])),
    make_row(s[1], 1870, as.numeric(s[4]), as.numeric(s[5]))
  ))
}

pop <- rbindlist(pop_list)
pop <- pop[!is.na(total_pop)]  # Drop missing (territories)
pop[, fb_share := foreign_born / total_pop]

cat("Population panel:", nrow(pop), "state-years\n")

# ====================================================================
# 3. GERMAN-BORN POPULATION BY STATE
# ====================================================================
# Source: U.S. Census Bureau, Fourteenth Census (1920), Vol. II,
#         Chapter VI, Table 6, pp. 697-699. "Country of Birth of the
#         Foreign-Born Population, by Divisions and States: 1920."
# Note: 1920 figures use postwar German boundaries.

german_1920 <- data.table(
  state_abbr = c(
    "ME","NH","VT","MA","RI","CT",
    "NY","NJ","PA",
    "OH","IN","IL","MI","WI",
    "MN","IA","MO","ND","SD","NE","KS",
    "DE","MD","DC","VA","WV","NC","SC","GA","FL",
    "KY","TN","AL","MS",
    "AR","LA","OK","TX",
    "MT","ID","WY","CO","NM","AZ","UT","NV",
    "WA","OR","CA"
  ),
  german_born_1920 = c(
    932, 1774, 630, 22113, 3136, 22644,
    205651, 92382, 120184,
    91883, 37377, 205491, 81047, 151290,
    74634, 70642, 64778, 11960, 15574, 40960, 22350,
    1632, 22653, 3382, 2832, 3738, 703, 6, 1006, 3504,
    11137, 2199, 2427, 929,
    3979, 5147, 7039, 31032,
    7873, 4143, 3293, 13602, 1173, 1516, 3559, 1009,
    22313, 13740, 67185
  )
)

# National German-born by year (Gibson & Jung 2006, Table 4)
# Used for back-projection: assume state shares stable within decade
german_national <- data.table(
  year = c(1870, 1880, 1890, 1900, 1910, 1920),
  german_born_us = c(1690533, 1966742, 2784894, 2663418, 2311237, 1686108)
)

# State-level German-born for 1890 (Census Bulletin No. 357, pp. 7-8)
# "The Foreign Born Population, Distributed According to Country of Birth"
german_1890 <- data.table(
  state_abbr = c(
    "ME","NH","VT","MA","RI","CT",
    "NY","NJ","PA",
    "OH","IN","IL","MI","WI",
    "MN","IA","MO","ND","SD","NE","KS",
    "DE","MD","DC","VA","WV","NC","SC","GA","FL",
    "KY","TN","AL","MS",
    "AR","LA","OK","TX",
    "MT","ID","WY","CO","NM","AZ","UT","NV",
    "WA","OR","CA"
  ),
  german_born_1890 = c(
    1104, 1631, 877, 28006, 3200, 28170,
    498608, 109181, 230616,
    225008, 82400, 338382, 116694, 259819,
    116955, 127247, 112508, 7460, 19770, 69507, 34400,
    1580, 26340, 5225, 3456, 5112, 523, 710, 1670, 1515,
    29536, 4710, 2645, 1540,
    3680, 9712, 410, 48843,
    4910, 1160, 1620, 18365, 1035, 815, 2070, 1280,
    12475, 8150, 71472
  )
)

# Merge German data with panel
pop <- merge(pop, german_1920[, .(state_abbr, german_born_1920)],
             by = "state_abbr", all.x = TRUE)
pop <- merge(pop, german_1890[, .(state_abbr, german_born_1890)],
             by = "state_abbr", all.x = TRUE)

# Back-project German-born for other years using state's share of national total
# Assumption: each state's share of national German-born population is
# interpolated between observed years (1890 and 1920)
pop <- merge(pop, german_national, by = "year", all.x = TRUE)

pop[, german_state_share_1890 := german_born_1890 / german_national[year == 1890]$german_born_us]
pop[, german_state_share_1920 := german_born_1920 / german_national[year == 1920]$german_born_us]

# Linear interpolation of state share between 1890 and 1920
pop[, share_weight := pmin(pmax((year - 1890) / 30, 0), 1)]
pop[, german_state_share := german_state_share_1890 * (1 - share_weight) +
                            german_state_share_1920 * share_weight]

# Impute German-born = national total × state share
pop[, german_born := round(german_born_us * german_state_share)]

# Override with observed values where available
pop[year == 1920, german_born := german_born_1920]
pop[year == 1890, german_born := german_born_1890]

pop[, german_share := german_born / total_pop]

# Clean up temp columns
pop[, c("german_born_1920", "german_born_1890", "german_born_us",
        "german_state_share_1890", "german_state_share_1920",
        "share_weight", "german_state_share") := NULL]

cat("German-born data imputed for", pop[!is.na(german_born), .N], "state-years\n")

# ====================================================================
# 4. BREWERY DATA (1870 Census of Manufactures)
# ====================================================================
# Source: Census of Manufactures microdata, cmfdata.org
# Hornbeck, Kremer, Lehnert & Morgan (2025)
# Note: From surviving manuscript schedules; represents lower bound

breweries_1870 <- fread("/tmp/cmf_breweries_1870.csv")
breweries_1870 <- breweries_1870[state_abbr != "NODATA"]

# Merge brewery baseline data with panel
pop <- merge(pop,
             breweries_1870[, .(state_abbr,
                                breweries_1870 = num_breweries,
                                brew_workers_1870 = num_workers,
                                brew_output_1870 = production_value)],
             by = "state_abbr", all.x = TRUE)

# States with no observed breweries in 1870
pop[is.na(breweries_1870), breweries_1870 := 0]
pop[is.na(brew_workers_1870), brew_workers_1870 := 0]
pop[is.na(brew_output_1870), brew_output_1870 := 0]

# Brewery intensity = breweries per 100,000 population (using 1870 pop)
pop_1870 <- pop[year == 1870, .(state_abbr, pop_1870 = total_pop)]
pop <- merge(pop, pop_1870, by = "state_abbr", all.x = TRUE)
pop[, brew_intensity := breweries_1870 / (pop_1870 / 100000)]

cat("Brewery data merged.\n")

# ====================================================================
# 5. MERGE PROHIBITION TREATMENT
# ====================================================================

pop <- merge(pop, prohibition_dates, by = "state_abbr", all.x = TRUE)

# Never-dry states (before 18th Amendment): treat year = 1920
pop[is.na(prohibition_year), prohibition_year := 1920]

# Treatment indicator
pop[, treated := as.integer(year >= prohibition_year)]

# Cohort for CS-DiD (year prohibition took effect)
pop[, cohort := prohibition_year]

# Event time
pop[, event_time := year - prohibition_year]

# Exclude very early adopters (ME 1851, KS 1881) — no pre-treatment data
pop[, early_adopter := as.integer(state_abbr %in% c("ME", "KS"))]

# Create numeric state ID for fixed effects
pop[, state_id := as.integer(factor(state_abbr))]

# ====================================================================
# 6. DERIVED VARIABLES
# ====================================================================

# Log outcomes
pop[, log_pop := log(total_pop)]
pop[, log_fb := log(foreign_born + 1)]
pop[, log_german := log(german_born + 1)]

# Population growth (decade-over-decade)
setorder(pop, state_abbr, year)
pop[, pop_growth := total_pop / shift(total_pop) - 1, by = state_abbr]
pop[, fb_growth := foreign_born / shift(foreign_born) - 1, by = state_abbr]
pop[, german_growth := (german_born + 1) / (shift(german_born) + 1) - 1, by = state_abbr]

# High-brewing state indicator (above-median 1870 brewery intensity)
median_brew <- pop[year == 1870 & !is.na(brew_intensity) & brew_intensity > 0,
                   median(brew_intensity)]
pop[, high_brewing := as.integer(brew_intensity > median_brew)]
pop[is.na(high_brewing), high_brewing := 0]

# German enclave indicator (above-median 1890 German share)
german_1890_med <- pop[year == 1890 & !is.na(german_share),
                       median(german_share, na.rm = TRUE)]
pop[, german_enclave := as.integer(
  german_share > german_1890_med & year == 1890)]
# Carry forward the 1890 classification
ge_states <- pop[german_enclave == 1, unique(state_abbr)]
pop[, german_enclave := as.integer(state_abbr %in% ge_states)]

# ====================================================================
# 7. SAVE
# ====================================================================

# Main analysis sample: exclude early adopters
panel <- pop[early_adopter == 0]

saveRDS(panel, file.path(data_dir, "state_panel.rds"))
saveRDS(pop, file.path(data_dir, "state_panel_full.rds"))

cat("\n=== Panel Summary ===\n")
cat("States:", panel[, uniqueN(state_abbr)], "\n")
cat("Years:", paste(sort(unique(panel$year)), collapse = ", "), "\n")
cat("Observations:", nrow(panel), "\n")
cat("Treated states (excl. ME, KS):", panel[prohibition_year < 1920, uniqueN(state_abbr)], "\n")
cat("Never-treated (wet until 1920):", panel[prohibition_year == 1920, uniqueN(state_abbr)], "\n")
cat("Mean German share (1890):", round(panel[year == 1890, mean(german_share, na.rm = TRUE)], 4), "\n")
cat("Mean brewery intensity (1870):", round(panel[year == 1870, mean(brew_intensity, na.rm = TRUE)], 2), "\n")
cat("\nDatasets saved to", data_dir, "\n")
