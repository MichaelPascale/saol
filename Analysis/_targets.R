# _targets.R
# Targets pipeline for PCRM analyses.
#
# Copyright (c) 2026, Michael P. Pascale <mpascale@bu.edu>.
# SPDX-License-Identifier: MIT
#
library(targets)
library(tarchetypes)

library(dplyr)
library(tidyr)
library(ggplot2)
library(readr)
library(stringr)
library(purrr)
library(ggforce) # for geom_circles
library(patchwork)

theme_set(theme_classic() + theme(text=element_text(size=9,  family="Ysabeau Office")))

source("layouts.r")
source("plot_subject.r")

list(
  # The maze environment's 3D mesh for visualization.
  tar_file(envir_model_file, "models/maze/RadialMaze8Arm_v1.obj"),
  tar_target(envir_layout, load_layout_maze(envir_model_file)),

  # Files to load per-participant.
  tar_map(
    values=list(ptpt=sprintf("PCRM%03d", c(1:2, 4:14))),

    # Trajectory and effort data files. Stimulus presentation order table.
    tar_file(position_file, dir(file.path("data", "v0.1", ptpt), "^PoseData.*\\.tsv", full.names = T)),
    tar_file(effort_file,   dir(file.path("data", "v0.1", ptpt), "^effort.*\\.tsv",   full.names = T)),
    tar_file(stimtab_file,  dir(file.path("data", "v0.1", ptpt), "^\\d+\\.tsv",       full.names = T)),

    tar_target(position, read_tsv(position_file, id="file")),
    tar_target(effort,   read_tsv(effort_file,   id="file")),
    tar_target(stimtab,  read_tsv(stimtab_file,  id="file")),

    # Create subject-level plots and save out PDFs for each.
    tar_target(plots, plot_subject(ptpt, position, effort, stimtab, envir_layout)),
    tar_target(plots_pdf,
               ggsave(file.path("output", paste0(ptpt, ".pdf")), plots, cairo_pdf, width=11, height=8.5),
               format = "file")
  )
)
