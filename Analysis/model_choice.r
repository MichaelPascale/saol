# model_choice.r
# Linear models fit to choice behavior.
#
# Copyright (c) 2026, Michael P. Pascale <mpascale@bu.edu>.
# SPDX-License-Identifier: MIT

library(brglm2)
library(lme4)

tar_load(all_entries)
tar_load(stimtab_PCRM014)

# entries_PCRM001 <-
dat <- all_entries |>
  filter(entry == 1) |>
  filter(trial > 4) |>
  # filter(subject=="PCRM013") |>
  select(subject, trial, chose_arm=arm, chose_blur=blur) |>
  left_join(all_stimtab, relationship = "one-to-many") |>
  mutate(
    # The viewing order (left/right scan of options) alternates each trial.
    # The sequence is the same for all subjects: R, L, R, L, ...
    direction = (trial+1) %% 2, #0,1,0
    # The model will
    outcome = as.numeric(chose_arm == arm),
    # Mean center the blur assignments.
    blur=blur-mean(blur),

    # saw = factor(if_else(direction == 0, arm, 9-arm)),
    # arm = factor(arm)

    # separate coding
    # fwd = factor(if_else(direction == 0, arm, NA)),
    # rev = factor(if_else(direction == 1, arm, NA)),
    dir = factor(if_else(direction == 0, arm, arm+8))
  )


# Single Subject
mdl <- glm(outcome ~  blur+dir, "binomial", dat, method="brglm_fit")
summary(mdl)

mdl <- glm(outcome ~  blur+arm + saw, "binomial", dat, method="brglm_fit")




nd <- select(dat, -c(outcome))[1:16,]
# nd <- expand_grid(select(nd, -blur), blur=seq(-3.5, 3.5, .1), subject=unique(dat$subject))
nd <- expand_grid(select(nd, -blur), blur=seq(-3.5, 3.5, .1))
nd$outcome <- predict(mdl, newdata=nd, type="link")
nd$direction <- factor(nd$direction, 0:1, c("CW", "CCW"))

# For bins by cut(x, 4)
midpoints <- dat$blur|>unique()|>sort() |>matrix(2)|>colMeans()

# plot observed logits vs. the model
pltdat <- dat |>
  mutate(blur = cut(blur,4)) |>
  summarize(
    .by=c(blur, arm, direction),
    pos=sum(outcome),
    neg=sum(!outcome),
    outcome = log(pos/neg),
    nobs=n()
  ) |>
  mutate(
    blur=midpoints[as.numeric(blur)],
    direction=factor(direction, 0:1, c("CW", "CCW"))
  )


ggplot(nd, aes(blur,outcome)) +
  geom_point(data=pltdat, aes(size=nobs, color=direction), alpha=0.3) +
  geom_line(aes(color=direction)) +
  facet_grid( ~ arm) +
  # scale_y_continuous("Probability", limits=0:1) +
  scale_x_continuous("Blur Level") +
  scale_color_viridis_d(option="cividis") +
  # guides(color="none") +
  theme_classic() +
  labs(
    title="Model Predictions vs. Empirical Means by Position",
    # subtitle=deparse(mdl$formula),
    y="Log Odds"
  )






# Plot subject-level probabilities by arm and direction
dat |>
  summarize(
    .by=c(subject, arm, direction),
    pos=sum(outcome),
    neg=sum(!outcome), p = pos/n(), nobs=n()) |>
  # bind_rows(
  #   dat |>
  #     summarize(
  #       .by=c(subject, arm),
  #       pos=sum(outcome),
  #       neg=sum(!outcome), p = pos/n(), nobs=n(),
  #       direction=2
  #     )
  # ) |>
  mutate(
    direction=factor(direction, c(0,2,1), c("CW","Avg", "CCW")),
    subject=factor(subject, sprintf("PCRM%03d", 1:18))
  ) |>
  ggplot(aes(x=arm, y=p, color=direction)) +
  geom_line() +
  scale_color_viridis_d(option="cividis") +
  facet_wrap(~subject, drop=F)






# Mixed effects modeling
mdl <- glmer(outcome ~ blur + arm + (blur + arm | subject),family= "binomial", dat)
summary(mdl)



# no success wit bobyqa, exceeds iterations
summary(glmer(outcome ~ -1 +blur + dir + (1|subject) + (dir | subject), data=dat, family="binomial"), control = glmerControl(optimizer = "bobyqa", optCtrl = list(maxfun = 100000)))

# https://stats.stackexchange.com/questions/365334/multilevel-nested-glmer-model-logistic-regression-with-4-groups
glmer(outcome ~ -1 +blur + dir + (1|subject) + (dir | subject), data=dat, family="binomial", nAGQ=4) # Error: AGQ only defined for a single scalar random-effects term

# try glmmAdaptive



# https://rpubs.com/bbolker/glmerlgcat
library(glmmTMB)

mdl_tmb <- glmmTMB(outcome ~ -1 +blur + dir + (1|subject) + (dir | subject), data=dat, family="binomial")
summary(mdl_tmb) # Model convergence problem; non-positive-definite Hessian matrix.




# Multinomial
library(nnet)


dat <- all_entries |>
  filter(entry == 1) |>
  filter(trial > 4) |>
  mutate(chose_arm=factor(arm, 1:8, letters[1:8])) |>
  select(subject, trial, chose_arm) |>
  # left_join(all_stimtab, relationship = "one-to-many") |>

  left_join(
    all_stimtab |>
      select(subject,trial, arm, blur) |>
      pivot_wider(
        names_from=arm,
        values_from=c(arm,blur),
        # names_prefix="pos",
        names_sort=T
      ) |>
      mutate(
        across(starts_with("arm"), ~ factor(if_else(trial%%2 == 1, ., 9-.), 1:8, LETTERS[1:8])),
        across(starts_with("blur"), ~ . - mean(.))
      ) |>
      rename_with(~paste0(str_replace(., "arm_", "arm"), "_pos"), starts_with("arm")) |>
      rename_with(~paste0(str_replace(., "blur_", "arm"), "_blur"), starts_with("blur")),
    relationship = "one-to-one"
  )

mutate(
  # The viewing order (left/right scan of options) alternates each trial.
  # The sequence is the same for all subjects: R, L, R, L, ...
  direction = (trial+1) %% 2, #0,1,0
  # The model will
  outcome = as.numeric(chose_arm == arm),
  # Mean center the blur assignments.
  blur=blur-mean(blur),

  # saw = factor(if_else(direction == 0, arm, 9-arm)),
  # arm = factor(arm)

  # separate coding
  # fwd = factor(if_else(direction == 0, arm, NA)),
  # rev = factor(if_else(direction == 1, arm, NA)),
  dir = factor(if_else(direction == 0, arm, arm+8))
)



mdl_mlt <- multinom(chose_arm ~ ., select(dat, -subject, -trial))
summary(mdl_mlt)

bind_cols(predict(mdl_mlt, type="probs"), dat)

