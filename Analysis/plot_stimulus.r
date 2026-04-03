# plot_stimulus.r
# Plots related to stimulus-level analyses.
#
# Copyright (c) 2026, Michael P. Pascale <mpascale@bu.edu>.
# SPDX-License-Identifier: MIT

plot_stimulus <- function (all_data, blurlevels, envir_layout) {

  theme_set(theme_classic() + theme(text=element_text(size=9,  family="Ysabeau Office")))

  # Position density plot.
  p1 <- filter(all_data, between(time, 0, 45), distance > 7.5, trial > 20) |>
    ggplot() +
    geom_layout_maze(envir_layout) +
    geom_density_2d_filled(aes(x,z), alpha=0.75) +
    guides(fill='none') +
    labs(
      title="Position Probability",
      subtitle="All subjects and all trials, excluding maze center",
      x="X-Position",
      y="Z-Position"
    )

  # Just those rows where the arm changes. Time reflects arm entry time.
  armchange <-
    filter(drop_na(all_data, arm), .by=c(subject, trial), row_number() == 1 | arm != lag(arm)) |>
    mutate(.by=c(subject,trial), entry=row_number(), .before=time)


  p2 <- ggplot(armchange, aes(y=entry, x=time)) +
    geom_point(
      position=position_jitterdodge(jitter.height = .4, jitter.width = 0, dodge.width = 0),
      alpha=0.5
    ) +
    stat_summary(color="red", orientation="y") +
    labs(
      title="Time of Arm Entry",
      subtitle="Entry order (first, second, third...)",
      x="Time (s)",
      y="Arm Entry"
    )

  # By Stimulus
  # ggplot(filter(armchange, entry==1)) + facet_wrap(vars(uniqueID)) + geom_bar(aes(x=blur)) +
  #   theme(strip.background = element_blank(),
  #         strip.text = element_text(size = 8, margin = margin(t = 2, b = 2)),
  #         panel.spacing = unit(0.1, "lines")
  #   )

  p3 <- ggplot(filter(armchange, entry==1)) +
    geom_bar(aes(x=blur)) +
    facet_wrap(vars(subject)) +
    labs(title="Per-Subject First Arm Entry by Blur Assignment")

  p4 <- ggplot(filter(armchange, entry==1)) +
    geom_bar(aes(x=blur)) +
    labs(title="Overall First Arm Entry by Blur Assignment")

  # Find the stimuli which had the most first-entries.
  stimfe <- armchange |> filter(entry == 1) |> filter(.by=uniqueID, n() > 4)

  stimfe_imageset <- left_join(distinct(stimfe, uniqueID), blurlevels) |>
    mutate(img = str_glue("{uniqueID}_{blur}.jpg"))

  imgfiles <- dir("stimuli/generated_20260203", "\\.jpg$", full.names=T)

  p5 <- stimfe_imageset |>
    ggplot() +
    geom_tile_pattern(
      aes(
        pattern_filename = img,
        x = blur,
        y = uniqueID
      ),
      pattern_type = "fit",
      pattern = "image") +
    # ggpattern seems to require that the values are ordered as in the dataframe.
    scale_pattern_filename_discrete(choices=set_names(imgfiles, basename)[stimfe_imageset$img]) +
    guides(pattern_filename='none') +
    coord_fixed() +
    labs(
      title="\"High-Curiosity\" Stimuli",
      subtitle="Chosen by 5 or More Participants as First-Entry",
      x="Blur Assignment",
      y="THINGSplus Image ID"
    )


  p6 <- ggplot(stimfe_imageset) +
    geom_line(aes(blur, sigma, color=uniqueID)) +
    labs(
      title="Per-Image Calibrated Gaussian Blur Sigma",
      subtitle="\"High-Curiosity\" Stimuli Only"
    ) +
    theme(legend.position="bottom")

  p7 <- ggplot(stimfe) +
    geom_bar(aes(x=blur)) +
    facet_wrap(vars(uniqueID)) +
    labs(
      title="Per-Image Response Frequencies",
      subtitle="\"High-Curiosity\" Stimuli Only, All Subjects"
    )

  p8 <- ggplot(stimfe) +
    geom_density(aes(x=blur, color=uniqueID)) +
    guides(color="none") +
    labs(
      title="Per-Image Response Probability Estimates",
      subtitle="\"High-Curiosity\" Stimuli Only, All Subjects"
    )

  ((p1 | p2) / (p3 | p4)) | ((p5 | p6) / (p7| p8))
}
