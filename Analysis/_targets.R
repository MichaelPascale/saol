# _targets.R
# Targets pipeline for PCRM analyses.
#
# Copyright (c) 2026, Michael P. Pascale <mpascale@bu.edu>.
# SPDX-License-Identifier: MIT

library(targets)
library(tarchetypes)

library(crew)
tar_option_set(
  controller = crew_controller_local(workers = 8),
  packages=c(
    "dplyr",
    "tidyr",
    "ggplot2",
    "readr",
    "stringr",
    "purrr",
    "ggforce",    # for plotting circles
    "ggpattern",  # for plotting images
    "patchwork"
  )
)


source("layouts.r")
source("behavioral.r")
source("plot_subject.r")

load_tsv <- \(file) extract(read_tsv(file, id="file"), file, "subject", "/(PCRM\\d+)/")

# Files to load per-participant.
sbj_targets <-
  tar_map(
    values=list(ptpt=sprintf("PCRM%03d", c(1:2, 4:14))),

    # Trajectory and effort data files. Stimulus presentation order table.
    tar_file(position_file, dir(file.path("data", "v0.1", ptpt), "^PoseData.*\\.tsv", full.names = T)),
    tar_file(effort_file,   dir(file.path("data", "v0.1", ptpt), "^effort.*\\.tsv",   full.names = T)),
    tar_file(stimtab_file,  dir(file.path("data", "v0.1", ptpt), "^\\d+\\.tsv",       full.names = T)),

    tar_target(position, load_position(position_file, stimtab)),
    tar_target(effort,   load_effort(effort_file, position)),
    tar_target(stimtab,  load_tsv(stimtab_file)),

    # Create subject-level plots and save out PDFs for each.
    tar_target(plots, plot_subject(ptpt, position, effort, stimtab, envir_layout)),
    tar_target(plots_pdf,
               ggsave(file.path("output", paste0(ptpt, ".pdf")), plots, cairo_pdf, width=11, height=8.5),
               format = "file")
  )

list(
  # The maze environment's 3D mesh for visualization.
  tar_file(envir_model_file, "models/maze/RadialMaze8Arm_v1.obj"),
  tar_target(envir_layout, load_layout_maze(envir_model_file)),

  # Subject-level targets.
  sbj_targets,

  # Aggregated targets.
  tar_combine(all_data, sbj_targets[["position"]])
)
