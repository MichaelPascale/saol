# _targets.R
# Targets pipeline for PCRM analyses.
#
# Copyright (c) 2026, Michael P. Pascale <mpascale@bu.edu>.
# SPDX-License-Identifier: MIT

library(targets)
library(tarchetypes)

library(crew)
tar_option_set(
  controller = crew_controller_local(workers = 4),
  memory="transient",
  garbage_collection = 5,
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
source("plot_stimulus.r")
source("model_choice.r")

load_tsv <- \(file) extract(read_tsv(file, id="file"), file, "subject", "/(PCRM\\d+)/")

# Files to load per-participant.
sbj_targets <-
  tar_map(
    values=list(ptpt=sprintf("PCRM%03d", c(1:2, 4:16, 18:19))),

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

# Run models
mdl_targets <- tar_map(
  values=choice_models,
  names=name,
  tar_target(glm, run_model_subject(fn, first_entries(all_entries, all_stimtab)), packages=c("brglm2", "broom")),
  tar_target(plots_choice_glm, plot_models_summary(glm)),
  tar_target(plots_choice_glm_pdf,
             ggsave(file.path("output", paste0("glm_", name, ".pdf")), plots_choice_glm, cairo_pdf, width=8, height=4), format="file")
)

targets <- list(
  # The maze environment's 3D mesh for visualization.
  tar_file(envir_model_file, "models/maze/RadialMaze8Arm_v1.obj"),
  tar_target(envir_layout, load_layout_maze(envir_model_file)),

  # Load the per-image Gaussian blur assignments.
  tar_file(blurlevels_file, "stimuli/imaglevels320.rds"),
  tar_target(blurlevels, readRDS(blurlevels_file)),

  # Survey data from Qualtrics export.
  tar_file(survey_file, "data/v0.1/survey/PCRMSP26+Pilot_April+1,+2026_17.31.csv"),
  tar_target(survey, {
    # NOTE: Qualtrics insists on several rows of header information.
    # Export as values in CSV format with default options.
    col_names <- names(read_csv(survey_file, n_max=0))
    read_csv(survey_file, skip=3, col_names=col_names)
  }),

  # Subject-level targets.
  sbj_targets,

  # Aggregated targets.
  tar_combine(all_data, sbj_targets[["position"]]),
  tar_combine(all_stimtab, sbj_targets[["stimtab"]]),

  # Arm entry timepoints.
  tar_target(all_entries, {
    drop_na(all_data, arm) |>
      # Keep the first entry and subsequent changes.
      filter(.by=c(subject, trial), row_number() == 1 | arm != lag(arm)) |>
      mutate(.by=c(subject, trial), entry=row_number(), .before=time)
  }),

  mdl_targets,

  # Create group-level summary plots.
  tar_target(plots_stim, plot_stimulus(all_data, all_entries, blurlevels, envir_layout)),
  tar_target(plots_stim_pdf,
             ggsave(file.path("output", "stimlevel.pdf"), plots_stim, cairo_pdf, width=11, height=8.5),
             format = "file")
)

# Set the ggplot theme for figure targets.
tar_hook_outer(
  targets,
  .x & (theme_classic() + theme(
    text = element_text(size=9, family="Crimson Pro Light"),
    plot.title = element_text(family="Ysabeau Semibold"),
    title = element_text(family="Ysabeau"),
    strip.text = element_text(family="Ysabeau Medium"),
    plot.subtitle =element_text(family="Ysabeau")
  )),
  names=starts_with("plots") & !contains("pdf")
)
