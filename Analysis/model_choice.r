# model_choice.r
# Linear models fit to choice behavior.
#
# Copyright (c) 2026, Michael P. Pascale <mpascale@bu.edu>.
# SPDX-License-Identifier: MIT

# From 2.5 Testing Independence for Ordinal Variables
# In Chapter 2, Analyzing Contingency Tables
# Agresti, A. (2019). An introduction to categorical data analysis (Third edition). John Wiley & Sons.

first_entry_f <- all_entries |> filter(entry == 1) |> mutate(blur=factor(blur, 1:8)) |> count(subject, blur, .drop=F)


filter(first_entry_f, subject == 'PCRM005') |> pull(n) -> e


library(vcdExtra)
t <- CMHtest(matrix(c(e,40-e), ncol=2), rscores=1:8, details=T)


library(lme4)
m <- glmer(n ~ blur + (1|subject), data = first_entry_f, family = binomial)
summary(m, corr = FALSE)




ggplot(mutate(first_entry_f, p=n/40)) +
  geom_line(aes(blur,p, color=subject, group=subject)) + guides(color='none') +
  geom_smooth(aes(as.numeric(blur),p), method="gam", formula=y~s(x, bs="cs", k=8))



X <- t(as.matrix(expand.grid(0:3, 0:3))); X <- X[, colSums(X) <= 3]
X <- rbind(X, 3:3 - colSums(X)); dimnames(X) <- list(letters[1:3], NULL)
X
round(apply(X, 2, function(x) dmultinom(x, prob = c(1,2,5))), 3)



p <- (first_entry_f$n[9:16]/40)+0.1
p / sum(p)





tar_load(all_entries)
tar_load(stimtab_PCRM001)

entries_PCRM001 <-
  all_entries |>
  filter(entry == 1) |>
  mutate(blur=factor(blur, 1:8)) |>
  filter(subject=="PCRM001") |>
  select(trial, arm, blur) |>
  left_join(
    stimtab_PCRM001 |>
      select(trial, arm, blur) |>
      pivot_wider(names_from=blur, values_from=arm, names_prefix="lev", names_sort=T),
    relationship = "one-to-one"
  )


entries_PCRM001



# entries_mdl <-
  all_entries |>
  filter(entry == 1, subject == "PCRM001")


  tar_load(all_entries)
  tar_load(stimtab_PCRM014)


    # entries_PCRM001 <-
  dat <- all_entries |>
    filter(entry == 1) |>
    # filter(subject=="PCRM014") |>
    select(subject, trial, chose_arm=arm, chose_blur=blur) |>
    left_join(all_stimtab, relationship = "one-to-many") |>
    mutate(
      # The viewing order (left/right scan of options) alternates each trial.
      # The sequence is the same for all subjects: R, L, R, L, ...
      direction = (trial+1) %% 2,
      # The model will
      outcome = as.numeric(chose_arm == arm),
      # Mean center the blur assignments.
      blur=blur-mean(blur)
    ) |>

    # Add one-hot-coded arm position.
    left_join(data.frame(arm=1:8, diag(nrow=8))) |>
    rename_with(.cols=matches("^X\\d$"), partial(str_replace, pattern="X", replacement="Pos")) |>

    # Add one-hot-coded arm viewing order (for left/right scan of options).
    left_join(data.frame(arm=1:8, direction=rep(1:0, each=8), diag(nrow=8)[c(1:8,8:1),])) |>
    rename_with(.cols=matches("^X\\d$"), partial(str_replace, pattern="X", replacement="View")) |>
    # select(subject, outcome, blur, starts_with("Pos"), direction, arm)
#
    select(outcome, blur, starts_with("Pos"), starts_with(("View")), direction, arm)
#
    # mutate(.keep="unused", View1 = View1 - View8, View2 = View2 - View7, View3= View3-View6, View4 = View5-View4)


mdl <- glm(outcome ~ blur + . + 0, "binomial", dat)
summary(mdl)

plot(dat$blur, predict(mdl, type="response")     )
tibble(
  x=dat$blur,
  y=predict(mdl, type="response"),
  color=dat$Pos1
)  |> arrange(x) |>
  ggplot(aes(x,y, color=color)) + geom_point()




mdl2 <- glm(outcome ~ blur + . + 0, "binomial", dat2)
summary(mdl2)



mdl <- glm(outcome ~ blur + . + 0, "binomial", select(dat, -starts_with("V")))
summary(mdl)



mdl <- glm(outcome ~ blur + (Pos1 + Pos2 + Pos3 + Pos4 + Pos5 + Pos6 + Pos7 + Pos8)*(View1 + View2 + View3 + View4) + 0, "binomial", dat)
summary(mdl)




dat



mdl <- glm(outcome ~   (Pos2 + Pos3 + Pos4 + Pos5 + Pos6 + Pos7 + Pos8)*(direction), "binomial", dat)
summary(mdl)


library(brglm2)
# Firth's Method to handle zero-counts in some arms.
mdl <- glm(outcome ~ blur + I(blur^2) + (Pos2 + Pos3 + Pos4 + Pos5 + Pos6 + Pos7 + Pos8)*direction, family="binomial", data=dat, method="brglm_fit")
summary(mdl)

library(brms)
mdl <- brm(outcome ~ blur + (Pos2 + Pos3 + Pos4 + Pos5 + Pos6 + Pos7 + Pos8)*(direction), bernoulli(), dat)
summary(mdl)


mdl <- glmer(outcome ~ blur + (Pos2 + Pos3 + Pos4 + Pos5 + Pos6 + Pos7 + Pos8)*direction + (blur |subject),family= "binomial", dat)
summary(mdl)

plot(dat$blur, predict(mdl, type="response")     )
bind_cols(dat,y=predict(mdl, type="response")) |>
  ggplot(aes(blur,y, color=arm, group=arm)) + geom_point()


tibble(
  blur=seq(-3.5, 3.5, 0.1),
)

nd <- select(dat, -c(outcome))[1:16,]
# nd <- expand_grid(select(nd, -blur), blur=seq(-3.5, 3.5, .1), subject=unique(dat$subject))
nd <- expand_grid(select(nd, -blur), blur=seq(-3.5, 3.5, .1))
nd$outcome <- predict(mdl, newdata=nd, type="link")
nd$direction <- factor(nd$direction, 1:0, c("CW", "CCW"))

ggplot(nd, aes(blur,outcome)) +
  geom_point(data=pltdat, aes(size=nobs, color=direction), alpha=0.1) +
  geom_line(aes(color=direction)) +
  facet_grid( ~ arm) +
  # scale_y_continuous("Probability", limits=0:1) +
  scale_x_continuous("Blur Level") +
  scale_color_viridis_d(option="cividis") +
  # guides(color="none") +
  theme_classic() +
  ggtitle("Model Predictions") +labs(y="Log Odds")


# For bins by cut(x, 4)
midpoints <- dat$blur|>unique()|>sort() |>matrix(2)|>colMeans()

# plot observed logits vs. the model
pltdat <- dat |>
  mutate(blur = cut(blur,4)) |>
  summarize(
    .by=c(blur, arm, direction),
    pos=sum(outcome),
    neg=sum(!outcome), outcome = log(pos/neg), nobs=n()) |>
  mutate(blur=midpoints[as.numeric(blur)], direction=factor(direction, 1:0, c("CW", "CCW")))





dat |>
  summarize(
    .by=c(subject, arm, direction),
    pos=sum(outcome),
    neg=sum(!outcome), p = pos/n(), nobs=n()) |>
  mutate(direction=factor(direction, 1:0, c("CW", "CCW"))) |>
  bind_rows(
    dat |>
      summarize(
        .by=c(subject, arm),
        pos=sum(outcome),
        neg=sum(!outcome), p = pos/n(), nobs=n())
  ) |>
  # mutate(direction=factor(direction)) |>
  ggplot(aes(x=arm, y=p, color=direction)) + geom_line() +
  facet_wrap(~subject)
