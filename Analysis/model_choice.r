# model_choice.r
# Linear models fit to choice behavior.
#
# Copyright (c) 2026, Michael P. Pascale <mpascale@bu.edu>.
# SPDX-License-Identifier: MIT

choice_models <- tibble::tribble(
  ~name,           ~fn,
  "linear",        quote(purrr::partial(glm, outcome ~ -1 + blur + position,             "binomial", method=brglm2::brglm_fit)),
  "quadratic",     quote(purrr::partial(glm, outcome ~ -1 + blur * I(blur^2) + position, "binomial", method=brglm2::brglm_fit)),
  "lin_sigma",     quote(purrr::partial(glm, outcome ~ -1 + sigma + position,            "binomial", method=brglm2::brglm_fit)),
  "lin_combined",  quote(purrr::partial(glm, outcome ~ -1 + sigma + blur + position,     "binomial", method=brglm2::brglm_fit))
)

first_entries <- function (all_entries, all_stimtab) {
  filter(all_entries, entry == 1) |>
  select(subject, trial, chose_arm=arm, chose_blur=blur) |>
  left_join(all_stimtab, relationship = "one-to-many") |>
  mutate(
    # The viewing order (left/right scan of options) alternates each trial.
    # The sequence is the same for all subjects: R, L, R, L, ...
    direction = (trial+1) %% 2, #0,1,0
    # Model a binary outcome for each alternative.
    outcome = as.numeric(chose_arm == arm),
    # Mean center the blur assignments.
    blur=blur-mean(blur),
    # A combined factor accounts for physical position and serial order of arms.
    position = factor(if_else(direction == 0, arm, arm+8)),
    sigma = scale(log(sigma))[,1]
  )
}

run_model_subject <- function (model, data) {
  group_by(data, subject) |>
  nest() |>
  mutate(
    model = map(data, model),
    results = map(.data$model, tidy),
    map_dfr(.data$model, glance)
  )
}

plot_models_summary <- function (models_df) {
  unnest(models_df, results) |>
  mutate(
    facet=case_when(
        str_detect(term, "blur|sigma") ~ 1,
        str_detect(term, "n[1-8]$") ~ 2,
        str_detect(term, "n(9|1\\d)$") ~ 3
      ) |>
      factor(1:3, c(
        "Effect of Blur",
        "Mean Offsets - Arm Position (CW)",
        "Mean Offsets - Arm Position (CCW)"
      )
    ),
    term = factor(
      term,
      c("blur",
        "I(blur^2)",
        "blur:I(blur^2)",
        "sigma",
        paste0("position", 1:16)
      ),
      c("L", "Q", "LxQ", "Abs. Sigma (px)", paste0("P",1:16))
    )
  ) |>
  ggplot(aes(term, estimate, color=subject)) +
  geom_line(aes(group=subject),  linewidth=0.33, alpha=0.15) +
  stat_summary(geom="pointrange", color="darkred", position=position_nudge(x=.2), size=.3) +
  geom_point() +
  scale_color_viridis_d(option="cividis", guide="none") +
  facet_wrap(~facet, scales="free", space="free_x") +
  theme_classic() +
  labs(
    subtitle=deparse(models_df$model[[1]]$formula),
    y="Estimate",
    x="Model Term"
  )
}

