# plot_subject.r
# Creates per-subject plots of the radial maze and the
# participants trajectory on each trial.
#
# Copyright (c) 2025-2026, Michael P. Pascale <mpascale@bu.edu>.
# SPDX-License-Identifier: MIT

plot_subject <- function (ptpt, position, effort, stimtab, envir_layout) {

  # Define the radius of the circle around each arm end that determines whether
  # or not the participant was counted as present in the arm end.
  radius_to_detect = 22

  # For each trial, reset time such that 0 is at 22s, the point from which behavior is free.
  position <- position |> filter(trial > 0) |> mutate(.by=trial, realtime=time, time = time - time[1] - 22)

  # Add to the order table the positions of the stimuli for plotting.
  stimtab <-
    mutate(
      stimtab,
      x=sin(4 * pi * arm / 18) / 2 * 15 * 5.5 + (cos(4 * pi * arm / 18) * 1.45 * sin(pi / 18) * 15),
      z=cos(4 * pi * arm / 18) / 2 * 15 * 5.5 - (sin(4 * pi * arm / 18) * 1.45 * sin(pi / 18) * 15)
    )

  # Create the plot.
  p1 <-
    ggplot() +

    # Plot the floorplan.
    geom_layout_maze(envir_layout) +

    # Plot the trajectory.    Downsample to 250ms
    # geom_point(aes(x,z,color=time), size=1, data=filter(path, row_number() %% 60 == 0, .by=trial)) +
    geom_path(aes(x,z,color=time), size=.4, data=filter(position, row_number() %% 60 == 0, .by=trial)) +


    # Plot the positions of stimuli and their blur assignments.
    # geom_circle(aes(x0=x, y0=z, r=radius_to_detect), linetype='dashed', color='coral', data=stimtab) +
    geom_point(aes(x,z,fill=blur), shape=22, size=2, data=stimtab) +

    # Display subplots per trial
    facet_wrap(vars(trial), labeller=as_labeller(\(x) paste("Trial", x))) +

    labs(
      title = ptpt,
      x = 'X-position', y='Z-position'
    ) +
    scale_color_viridis_c('Time (s)', limits=c(0, 45)) +
    scale_fill_viridis_c("Blur Level", option="magma") +
    # scale_fill_brewer("Blur Level", palette="Reds") +
    coord_equal() +
    theme_minimal() +
    theme(
      text=element_text(size=12,  family="Ysabeau Office"),
      legend.position='bottom', legend.direction = 'horizontal',
      legend.key.height = unit(3, 'mm')
    )

  brks <- position |> filter(between(time, 0, 45)) |> reframe(.by=trial, start=min(realtime), end=max(realtime))

  efftrial <-
    inner_join(
      effort, brks, join_by(time >=start, time <= end)
    ) |>
    select(trial, time) |>
    mutate(.by=trial, time=time - time[1], diff=c(NA, diff(time))) |>
    filter(diff < 1)

  p2 <-
    efftrial |>
    ggplot() + stat_summary(aes(x=factor(trial), y=diff*1000)) + labs(x="Trial", y="RT (ms)") + theme_classic()


  p3 <- stimtab |> left_join(position, by='trial') |> mutate(dist=sqrt((x.x - x.y)^2 + (z.x - z.y)^2)) |>
    filter(dist < radius_to_detect) |>
    distinct(trial, arm) |>
    left_join(stimtab) |>
    # left_join(distinct(params, trial, arm, blur)) |>
    ggplot() +
    geom_bar(aes(x=arm), fill='orange')

  p4 <- stimtab |> left_join(position, by='trial') |> mutate(dist=sqrt((x.x - x.y)^2 + (z.x - z.y)^2)) |>
    filter(dist < radius_to_detect) |>
    distinct(trial, arm) |>
    left_join(stimtab) |>
    # left_join(distinct(params, trial, arm, blur)) |>
    ggplot() +
    geom_bar(aes(x=blur), fill='orange')

  p1 | (p2/p3/p4)
}
