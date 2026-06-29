library(data.table)
library(dplyr)
library(purrr)

cgi_file <- "/home/xuyanbo/ref/hg38/cpg_island/cpgIslandExt.noBin.sorted.bed"

out_dir <- "/home/xuyanbo/project/MOF_TAPS/analysis/fig_factory/fig/Fig5/cgi"
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

out_bed <- file.path(out_dir, "hg38_cpgIslandExt.profile_bins.bed")

cgi <- fread(cgi_file, header = FALSE, sep = "\t") %>%
  as_tibble() %>%
  transmute(
    chrom = V1,
    start = as.integer(V2),
    end = as.integer(V3),
    cgi_id = paste0(V1, ":", V2, "-", V3)
  ) %>%
  filter(chrom %in% paste0("chr", c(1:22, "X", "Y"))) %>%
  filter(end > start) %>%
  arrange(chrom, start, end)

make_bins_one_chr <- function(x) {
  x <- x %>%
    arrange(start, end) %>%
    mutate(
      prev_end = lag(end),
      next_start = lead(start),

      upstream_start = if_else(
        is.na(prev_end),
        pmax(0L, start - 4000L),
        pmax(start - 4000L, start - floor((start - prev_end) / 2))
      ),

      downstream_end = if_else(
        is.na(next_start),
        end + 4000L,
        pmin(end + 4000L, end + floor((next_start - end) / 2))
      ),

      upstream_start = pmin(upstream_start, start),
      downstream_end = pmax(downstream_end, end)
    )

  map_dfr(seq_len(nrow(x)), function(i) {
    z <- x[i, ]

    n_up <- floor((z$start - z$upstream_start) / 80L)
    n_down <- floor((z$downstream_end - z$end) / 80L)

    upstream_bins <- if (n_up > 0) {
      tibble(
        chrom = z$chrom,
        start = z$start - 80L * rev(seq_len(n_up)),
        end = z$start - 80L * (rev(seq_len(n_up)) - 1L),
        region = "upstream",
        bin_index = seq_len(n_up),
        profile_bin = 50L - n_up + seq_len(n_up)
      )
    } else {
      tibble(
        chrom = character(),
        start = integer(),
        end = integer(),
        region = character(),
        bin_index = integer(),
        profile_bin = integer()
      )
    }

    body_breaks <- floor(seq(z$start, z$end, length.out = 21))

    body_bins <- tibble(
      chrom = z$chrom,
      start = body_breaks[-21],
      end = body_breaks[-1],
      region = "CGI",
      bin_index = seq_len(20),
      profile_bin = 51L:70L
    ) %>%
      filter(end > start)

    downstream_bins <- if (n_down > 0) {
      tibble(
        chrom = z$chrom,
        start = z$end + 80L * (seq_len(n_down) - 1L),
        end = z$end + 80L * seq_len(n_down),
        region = "downstream",
        bin_index = seq_len(n_down),
        profile_bin = 70L + seq_len(n_down)
      )
    } else {
      tibble(
        chrom = character(),
        start = integer(),
        end = integer(),
        region = character(),
        bin_index = integer(),
        profile_bin = integer()
      )
    }

    bind_rows(upstream_bins, body_bins, downstream_bins) %>%
      mutate(
        cgi_id = z$cgi_id
      ) %>%
      select(chrom, start, end, cgi_id, region, bin_index, profile_bin)
  })
}

cgi_bins <- cgi %>%
  group_by(chrom) %>%
  group_split() %>%
  map_dfr(make_bins_one_chr) %>%
  filter(end > start) %>%
  arrange(chrom, start, end, profile_bin)

data.table::fwrite(
  cgi_bins %>%
    mutate(
      start = as.integer(round(start)),
      end = as.integer(round(end)),
      bin_index = as.integer(bin_index),
      profile_bin = as.integer(profile_bin)
    ) %>%
    select(chrom, start, end, cgi_id, region, bin_index, profile_bin),
  out_bed,
  sep = "\t",
  quote = FALSE,
  col.names = FALSE
)

out_bed