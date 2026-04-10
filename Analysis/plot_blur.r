

all_entries |>
  filter(entry==1)|>
  ggplot() +
  geom_histogram(aes(x=sigma), data=blurlevels, fill='red') +
  geom_histogram(aes(x=sigma))


all_entries |>
  filter(entry==1)|>
  ggplot() +
  geom_density(aes(x=sigma), data=blurlevels, color='red') +
  geom_density(aes(x=sigma)) +
  xlim(4,50)




stimtab_PCRM009 |>
  left_join(select(filter(all_entries, entry==1), subject, trial, blur, entry, time)) |>
  mutate(.by=trial, sigma_trial_normed = (sigma - min(sigma))/(max(sigma)-min(sigma))) |>
  drop_na(entry) |>
  ggplot() +
  geom_histogram(aes(x=sigma_trial_normed))



plot_sigma_trialwise <- function (stimtab) {

  p1 <-
    stimtab |>
    ggplot() +
    geom_point(aes(x=trial, y=sigma, color=blur)) +
    scale_color_viridis_c("Stimulus Blur Level", option="rocket") +
    scale_x_continuous("Trial", minor_breaks = seq(2,40,2), breaks=seq(8,40,8)) +
    scale_y_continuous("Gaussian Blur Sigma (px)") +
    theme_classic() +
    theme(panel.grid.minor.x = element_line(linewidth = .1, color="grey75"),
          panel.grid.major.x = element_line(linewidth = .1, color="grey75"),
          legend.position = "inside", legend.position.inside = c(.95,.95),
          legend.justification = "right",
          legend.background = element_rect(fill=fill_alpha("white", 0)),
          legend.direction = "horizontal", legend.title = element_text(size=10)
    ) +
    labs(
      title="Single-Subject Trial-Wise Blur Level Ordering"
    )

  # Same plot but normalized sigma per-trial
  p2 <-
    stimtab |>
    mutate(.by=trial, sigma_trial_normed = (sigma - min(sigma))/(max(sigma)-min(sigma))) |>
    ggplot() +
    geom_point(aes(x=trial, y=sigma_trial_normed, color=blur)) +
    scale_color_viridis_c("Stimulus Blur Level", option="rocket", guide="none") +
    scale_x_continuous("Trial", minor_breaks = seq(2,40,2), breaks=seq(8,40,8)) +
    scale_y_continuous("Gaussian Blur Sigma (Absolute Linear Units, Normalized Per-Trial)", breaks=seq(0,1,.25), limits=c(0,1)) +
    theme_classic() +
    theme(panel.grid.minor.x = element_line(linewidth = .1, color="grey75"),
          panel.grid.major.x = element_line(linewidth = .1, color="grey75")
    ) +
    labs(
      title="Single-Subject Trial-Wise Blur Level Ordering"
    )

  p1 | p2
}

plot_sigma_trialwise(stimtab_PCRM001)
