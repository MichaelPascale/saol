# CSV Data.R (03.20).R Alev Egilmez 
library(tidyverse)
qualtrics <- read_csv("/Users/caglalev/Desktop/CD Lab/PCRM Survey Data/PCRMSP26+Pilot_March+19,+2026_18.50.csv")
qualtrics <- qualtrics [c(-1,-2),]
dcr_scale <- qualtrics |>
  select(id = subject_id...11, "5DCR_1":"5DCR_24") |>
  mutate(
       .before = "5DCR_1",
       joy = rowMeans(across("5DCR_1":"5DCR_4", as.numeric)), 
       ds = rowMeans(across("5DCR_5":"5DCR_8", as.numeric)), 
       st = rowMeans(across("5DCR_9":"5DCR_12", ~ 8 - as.numeric(.x))),  
       ts = rowMeans(across("5DCR_13":"5DCR_16", as.numeric)),
       osc = rowMeans(across("5DCR_17":"5DCR_20", as.numeric)),
       csc = rowMeans(across("5DCR_21":"5DCR_24", as.numeric)))
aeq_scale <- qualtrics |>
  select(subject_id...11, "AEQ_1":"AEQ_22") |>
mutate(
      .before = "AEQ_1",
      total = rowMeans(across("AEQ_1":"AEQ_22", as.numeric)),
      emotional = rowMeans(across("AEQ_1":"AEQ_4", as.numeric)),
      cultural = rowMeans(across("AEQ_5":"AEQ_8", as.numeric)),
      perceptual = rowMeans(across("AEQ_9":"AEQ_11", as.numeric)),
      understanding = rowMeans(across("AEQ_12":"AEQ_15", as.numeric)),
      proximal = rowMeans(across("AEQ_16":"AEQ_18", as.numeric)),
      experience = rowMeans(across("AEQ_19":"AEQ_22", as.numeric)))
AReA_scale <- qualtrics |>
  select(subject_id...11, "AReA_1":"AReA_14") |>
mutate(
      .before = "AReA_1",
      aa = rowMeans(across(c("AReA_1","AReA_2","AReA_3","AReA_4","AReA_6","AReA_9","AReA_13","AReA_14"), as.numeric)),
      iae = rowMeans(across(c("AReA_8","AReA_11","AReA_12",AReA_13),as.numeric)),
      cb = rowMeans(across(c("AReA_5","AReA_7","AReA_10"), as.numeric))
        )
