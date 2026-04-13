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

