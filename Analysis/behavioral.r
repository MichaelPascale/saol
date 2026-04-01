# behavioral.r
# TLoad and preprocess behavioral data files.
#
# Copyright (c) 2026, Michael P. Pascale <mpascale@bu.edu>.
# SPDX-License-Identifier: MIT

# PoseData*.tsv.gz records the position and heading direction every frame.
load_position <- function (path, stimtab) {
  read_tsv(path, id="file") |>

    # The subject and task version are in the file path.
    extract(file, c("version", NA, "subject"), "/(v(\\d+\\.){1,3}\\d)/(PCRM\\d+)/") |>

    # Trials begin from 1. Entries of 0 belong to the wait to start phase.
    filter(trial > 0) |>

    # Time is originally realtimeSinceStartup. Create time-in-trial variable.
    mutate(realtime = time) |>
    mutate(.by=trial, time = time - time[1] - 22) |>

    # Assign each position to the appropriate arm of the maze.
    rowwise() |>
    mutate(arm=calc_maze_arm(x,z)) |>
    ungroup() |>
    mutate(
      arm = arm-1,
      distance=sqrt((0 - x)^2 + (0 - z)^2)
    ) |>
    # Join the stimulus presentation order table to add blurlevels.
    left_join(stimtab)
}

# effort*.tsv.gz records the time of every keypress (buttonSouth).
load_effort <- function (path, position) {

  # Extract the start and end times of each trial in realtime seconds.
  breaks <- filter(position, between(time, 0, 45)) |>
    reframe(.by=trial, start=min(realtime), end=max(realtime))

  # Time in effort file is realtimeSinceStartup. Join this with the breaks to
  # assign each keypress to the trial.
  efftrial <-
    read_tsv(path, id="file") |>
    extract(file, "subject", "/(PCRM\\d+)/") |>
    inner_join(breaks, join_by(time >= start, time <= end)) |>
    mutate(realtime=time, time = time - start) |>
    select(subject, trial, time, realtime) |>

    # Calculate the inter-key-interval. Ensure time matches position's time-in-trial.
    mutate(.by=trial, iki=c(NA, diff(realtime))) |>

    # Long IKIs excluded. The effortful controls used a moving average of the
    # rate over only the last second.
    filter(iki < 1)
}
