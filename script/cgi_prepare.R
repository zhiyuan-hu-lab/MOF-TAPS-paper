library(readr)
library(dplyr)

project_dir <- "/home/xuyanbo/project/MOF_TAPS"

count_tsv <- file.path(
  project_dir,
  "analysis", "fig_factory", "fig", "Fig5", "cgi",
  "bam_counts", "HeLa_BAM_read_count_summary.tsv"
)

out_plan <- file.path(
  project_dir,
  "analysis", "fig_factory", "fig", "Fig5", "cgi",
  "bam_counts", "HeLa_BAM_downsample_plan.tsv"
)

input_order <- c("10 pg", "100 pg", "1 ng")
method_order <- c("TAPS", "TAPS+", "MOF-TAPS")

meta <- tibble::tibble(
  sample = c(
    "fym260106_S01", "fym260106_S02", "fym260106_S03",
    "fym260106_S04", "fym260106_S05", "fym260106_S06",
    "fym260124_S04", "fym260124_S05", "fym260124_S06"
  ),
  input_amount = factor(
    c("10 pg", "100 pg", "1 ng",
      "10 pg", "100 pg", "1 ng",
      "10 pg", "100 pg", "1 ng"),
    levels = input_order
  ),
  method = factor(
    c("TAPS", "TAPS", "TAPS",
      "TAPS+", "TAPS+", "TAPS+",
      "MOF-TAPS", "MOF-TAPS", "MOF-TAPS"),
    levels = method_order
  )
)

count_df <- read_tsv(count_tsv, show_col_types = FALSE)

plan_df <- count_df %>%
  left_join(meta, by = "sample") %>%
  group_by(input_amount) %>%
  mutate(
    target_depth_eligible_chr1_22 = min(depth_eligible_chr1_22, na.rm = TRUE),
    downsample_fraction = target_depth_eligible_chr1_22 / depth_eligible_chr1_22,
    downsample_fraction = pmin(downsample_fraction, 1)
  ) %>%
  ungroup() %>%
  arrange(input_amount, method) %>%
  select(
    sample,
    input_amount,
    method,
    depth_eligible_chr1_22,
    target_depth_eligible_chr1_22,
    downsample_fraction
  )

write_tsv(plan_df, out_plan)

plan_df