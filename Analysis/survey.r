# survey.r
# Process and summarize surveys
#
# Copyright (c) 2026, Michael P. Pascale <mpascale@bu.edu>.
# Copyright (c) 2026, Alev Egilmez <caglalev@bu.edu>.
# SPDX-License-Identifier: MIT

survey <- survey |>
  mutate(subject = str_remove_all(subject_id...11, "_|\\s"), .before=1) |>
  rename_with(str_remove_all, pattern="\\s") |>
  # Name the questions that were derived from Jepma et al. (2012).
  rename_with(\(x) paste0("Jepma_",str_extract(x, "\\d+$")), starts_with("ArtMuseumGame")) |>
  # Remove the leading "5" from the 5DCR variable names, just to avoid having to quote all the time.
  rename_with(str_remove, starts_with("5DCR"), "^5") |>
  select(
    subject,
    gameExpYears=GamingExperience,
    gameSkill=GamingSkill,
    starts_with("Jepma"),
    starts_with("DCR"),
    starts_with("AEQ"),
    starts_with("AReA")
  )

# Questions from Jepma et al. (2012).
labels <- c(
  Jepma_1 = "curious about blurred",
  Jepma_2 = "tried to guess",
  Jepma_3 = "disappointed on no clear*", # NOTE: This one doesn't really make sense in this task"
  Jepma_4 = "recognized blurred objects",
  Jepma_5 = "tried to remember"
)

survey |>
  pivot_longer(starts_with("Jepma"), names_transform=\(x) factor(x, names(labels))) |>
  ggplot() +
  geom_histogram(aes(value)) +
  facet_wrap(vars(name), labeller=as_labeller(labels))

  survey |> #names_transform=\(x) factor(name, names(labels), labels)
    pivot_longer(starts_with("Jepma")) |>
    mutate(name = factor(name, names(labels), labels)) |>
    ggplot() +
    stat_summary(aes(value, name), orientation="y", fun.data=partial(mean_sdl, mult=1)) +
    scale_x_continuous("Scale from 1 (Not at All) to 5 (Very Much)", limits=c(0,6), breaks=1:5) +
    scale_y_discrete(limits=rev) +
    labs(
      title = "Average response on five questions from Jepma et al. (2012), Table 1",
      caption = "* The question was asked but does not apply in this experiment"
    )


# Questions from Kashdan
survey |>
  select(subject, DCR_1:DCR_24) |>
  mutate(
    .after = 1,
    JE  = rowMeans(across(DCR_1:DCR_4)),
    DS  = rowMeans(across(DCR_5:DCR_8)),
    ST  = rowMeans(across(DCR_9:DCR_12, ~ 8 - .x)),
    TS  = rowMeans(across(DCR_13:DCR_16)),
    OSC = rowMeans(across(DCR_17:DCR_20)),
    CSC = rowMeans(across(DCR_21:DCR_24))
  )

# Questions from aesthetics questionnaires
survey |>
  select(subject, AEQ_1:AEQ_22) |>
  mutate(
    .after = 1,
    total         = rowMeans(across(AEQ_1:AEQ_22)),
    emotional     = rowMeans(across(AEQ_1:AEQ_4)),
    cultural      = rowMeans(across(AEQ_5:AEQ_8)),
    perceptual    = rowMeans(across(AEQ_9:AEQ_11)),
    understanding = rowMeans(across(AEQ_12:AEQ_15)),
    proximal      = rowMeans(across(AEQ_16:AEQ_18)),
    experience    = rowMeans(across(AEQ_19:AEQ_22))
  )

survey |>
  select(subject, AReA_1:AReA_14) |>
  mutate(
    .after = 1,
    aa  = rowMeans(across(c(AReA_1, AReA_2, AReA_3,  AReA_4, AReA_6, AReA_9, AReA_13, AReA_14))),
    iae = rowMeans(across(c(AReA_8, AReA_11,AReA_12, AReA_13))),
    cb  = rowMeans(across(c(AReA_5, AReA_7, AReA_10)))
  )
pivot_longer(dcr_scale, c("joy","ds","ts","st","osc","csc")) |>
  select(-c("5DCR_1":"5DCR_24")) |>

  ggplot() +
  stat_summary(aes(x = name, y = value))

pivot_longer(AReA_scale, c("aa","iae","cb")) |>
  select(-c("AReA_1":"AReA_14")) |>

  ggplot() +
  stat_summary(aes(x = name, y = value))
