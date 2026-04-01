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
    facet_wrap(vars(trial), ncol=8, labeller=as_labeller(\(x) paste("Trial", x))) +

    labs(
      title = "Single-Trial Trajectories",
      x = 'X-position', y='Z-position'
    ) +
    scale_color_viridis_c('Time (s)', limits=c(0, 45)) +
    scale_fill_viridis_c("Blur Level", option="magma") +
    # scale_fill_brewer("Blur Level", palette="Reds") +
    coord_equal() +
    theme(
      legend.position='bottom', legend.direction = 'horizontal',
      legend.key.height = unit(3, 'mm'),
      axis.ticks = element_blank(),
      axis.text = element_blank(),
      axis.line = element_blank(),
      panel.grid.major = element_line(color = "grey92", linewidth = 0.5),
      strip.background = element_blank(),
      panel.border = element_blank()
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
    ggplot() + stat_summary(aes(x=factor(trial), y=diff*1000)) +
    labs(
      title="Inter-Key-Intervals During Effortful Movement by Trial",
      x="Trial",
      y="RT (ms)"
    )

  p3 <- stimtab |> left_join(position, by='trial') |> mutate(dist=sqrt((x.x - x.y)^2 + (z.x - z.y)^2)) |>
    filter(dist < radius_to_detect) |>
    distinct(trial, arm) |>
    left_join(stimtab) |>
    # left_join(distinct(params, trial, arm, blur)) |>
    ggplot() +
    geom_bar(aes(x=arm), fill='orange') +
    labs(
      title="Total Arm Entries by Arm Position",
      x="Arm (Positions in Clockwise Order)",
      y="Frequency"
    )

  p4 <- stimtab |> left_join(position, by='trial') |> mutate(dist=sqrt((x.x - x.y)^2 + (z.x - z.y)^2)) |>
    filter(dist < radius_to_detect) |>
    distinct(trial, arm) |>
    left_join(stimtab) |>
    # left_join(distinct(params, trial, arm, blur)) |>
    ggplot() +
    geom_bar(aes(x=blur), fill='orange') +
    labs(
      title="Total Arm Entries by Blur Assignment",
      x="Blur Level",
      y="Frequency"
    )

  calc_arm <- function (x, y, narms=9, distance=7.5, extent=45, width=4, full.table=F) {
    stopifnot(length(x) == 1, length(y) == 1)

    # Just half a circle because each arm is separated by a wall.
    # Then, times two to get the angle between every other wall.
    th <- 2*(pi / narms) * seq(0,narms-1)

    # Calculate the point rotated counterclockwise to each arm position.
    xs = x*cos(th) - y*sin(th)
    ys = x*sin(th) + y*cos(th)
    res = (abs(xs) <= width) & ys <= extent & ys >= distance

    # Return the index of the arm meeting the criteria.
    if(!full.table)
      return(if(any(res)) which(res) else NA_integer_)

    data.frame(xs,ys,theta=th, result=res)
  }

  pathArmLabels <-
    rowwise(position) |>
    mutate(arm=calc_arm(x,z)) |>
    ungroup() |>
    mutate(
      arm = arm-1,
      distance=sqrt((0 - x)^2 + (0 - z)^2),
      approach = between(distance, 7.5, 7.5*5)
    )

  # Only the first entry per trial...
  p5 <- pathArmLabels |>
    drop_na(arm) |>
    left_join(select(stimtab, -c(x,z))) |>
    filter(.by=trial, arm == unique(arm)[1]) |>
    distinct(trial, arm) |>
    ggplot() +
    geom_bar(aes(x=arm), fill='orange') +
    labs(
      title="First Arm Entry by Arm Position",
      x="Arm (Positions in Clockwise Order)",
      y="Frequency"
    )

  p6 <- pathArmLabels |>
    drop_na(arm) |>
    left_join(select(stimtab, -c(x,z))) |>
    filter(.by=trial, arm == unique(arm)[1]) |>
    distinct(trial, blur) |>
    ggplot() +
    geom_bar(aes(x=blur), fill='orange') +
    labs(
      title="First Arm Entry by Blur Assignment",
      x="Blur Level",
      y="Frequency"
    )

  # Look at second entries relative to first
  p7 <- pathArmLabels |>
    drop_na(arm) |>
    left_join(select(stimtab, -c(x,z))) |>
    mutate(.by=trial, first = unique(arm)[1]) |>
    filter(.by=trial, arm == unique(arm)[2]) |>
    mutate(diff=pmin(abs(arm-first) %% 8, 8- (abs(arm-first) %% 8))) |>
    distinct(trial, diff) |>
    ggplot() +
    geom_bar(aes(x=diff), fill='orange') +
    scale_x_continuous(breaks=0:4, limits=c(0,8)) +
    labs(
      title="Second Entry by Position Relative to First",
      x="Relative Arm Position",
      y="Frequency"
    )

  p8 <-
    pathArmLabels |>
    drop_na(arm) |>
    filter(approach) |>
    filter(.by=trial, arm == unique(arm)[1]) |>
    mutate(.by=trial, timeInTrial=time-time[1]) |>
    ggplot(aes(timeInTrial,distance, group=trial)) +
    geom_path() +
    labs(
      title="Distance from Center on First Arm Entry",
      x="Time From Trial Start",
      y="Distance"
    )


  ((p1/p8 +plot_layout(heights=c(2,1))) | (((p3|p4)/(p5|p6)/(p7|plot_spacer())/p2))) + plot_annotation(title=ptpt)

  }

