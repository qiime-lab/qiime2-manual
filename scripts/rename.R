#!/usr/bin/env Rscript
# ファイル名の一括変更スクリプト
# Usage: Rscript rename.R <csv_file> <target_directory>
#
# CSV形式:
#   A列: 変更前のファイル名
#   B列: 変更後のファイル名

args <- commandArgs(trailingOnly = TRUE)

if (length(args) != 2) {
  cat("Usage: Rscript rename.R <csv_file> <target_directory>\n")
  cat("  csv_file: 変更前後のファイル名が記載されたCSV\n")
  cat("  target_directory: 変更したいファイルがあるフォルダ\n")
  quit(status = 1)
}

csv_file <- args[1]
target_dir <- args[2]

rename_table <- read.csv(csv_file, header = FALSE, stringsAsFactors = FALSE)

success_count <- 0
error_count <- 0

for (i in 1:nrow(rename_table)) {
  old_name <- file.path(target_dir, rename_table[i, 1])
  new_name <- file.path(target_dir, rename_table[i, 2])

  if (file.exists(old_name)) {
    result <- file.rename(old_name, new_name)
    if (result) {
      cat(sprintf("[OK] %s -> %s\n", rename_table[i, 1], rename_table[i, 2]))
      success_count <- success_count + 1
    } else {
      cat(sprintf("[ERROR] Failed to rename: %s\n", rename_table[i, 1]))
      error_count <- error_count + 1
    }
  } else {
    cat(sprintf("[ERROR] File not found: %s\n", old_name))
    error_count <- error_count + 1
  }
}

cat(sprintf("\nComplete: %d succeeded, %d failed\n", success_count, error_count))
