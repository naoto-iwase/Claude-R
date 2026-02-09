#!/usr/bin/env Rscript
# ClaudeR Setup Script

cat("=== ClaudeR Setup ===\n\n")

# Step 1: Install renv
cat("Step 1: Installing renv...\n")
if (!require("renv", quietly = TRUE)) {
  install.packages("renv")
}

# Step 2: Initialize renv
cat("\nStep 2: Initializing renv...\n")
renv::init()

# Step 3: Install devtools
cat("\nStep 3: Installing devtools...\n")
if (!require("devtools", quietly = TRUE)) {
  install.packages("devtools")
}
renv::snapshot()

# Step 4: Install ClaudeR from GitHub
cat("\nStep 4: Installing ClaudeR from GitHub...\n")
devtools::install_github("IMNMV/ClaudeR")
renv::snapshot()

cat("\n=== Setup Complete! ===\n")
cat("\nNext steps:\n")
cat("1. Open RStudio\n")
cat("2. File -> New Project -> Existing Directory -> select the project folder -> Create Project\n")
cat("   (If .Rproj already exists, instead: File -> Open Project -> select your .Rproj file -> Open)\n")
cat("3. Run: library(ClaudeR)\n")
cat("4. Run: claudeAddin()\n")
cat("5. Click 'Start Server' in the Viewer pane\n")
