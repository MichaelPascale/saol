library(OpenImageR)
library(stringr)
library(dplyr)
library(purrr)


calc_image_metrics <- function(filename){
  message(filename)
  my_pic <- readImage(filename)
  my_pic <- RGB_to_Lab(my_pic * 255)
  data.frame( 
    luminance = mean(my_pic[,,1]),
    contrast = sd(my_pic[,,1]),
    file = filename
  )
}

files <- dir("/Users/caglalev/Desktop/UROP 26/pcrmsp26_blurred_stimuli", full.names = TRUE)
image_metrics <- map(files, calc_image_metrics) |> bind_rows() |>
  mutate(
    base_name = str_remove(basename(file), "\\.(jpe?g|png)$"),
    uniqueID = str_extract(base_name, "^.*?(?=\\_\\d)|.+"),
    blur = coalesce(as.numeric(str_extract(base_name, "(?<=_)\\d+$")), 0)
  ) |>
  select(-base_name, -file)

all_data <- readRDS("/Users/caglalev/Desktop/UROP 26/data_form_model_allsubjects.rds")
result <- left_join(all_data, image_metrics, by = c("uniqueID", "blur")) |> mutate(blur=blur-mean(blur))
saveRDS(result, "/Users/caglalev/Desktop/UROP 26/result_allsubjects_with_metrics.rds")

list_subject <- unique(result$subject)
models <- list()
model_coefficients <- list()
for (subject in list_subject) {
  fit_model <- glm(outcome ~ poly(blur,2) + position +contrast + luminance, data = result[result$subject == subject,], family = "binomial")
  models <- c(models, list(fit_model))
  model_coefficients <- c(model_coefficients, list(data.frame(t(coef(fit_model))))
  )
}

coef_df <- bind_rows(model_coefficients) 

t.test( 
  coef_df$poly.blur..2.1,
  alternative = "two.sided",
  paired = FALSE,
  var.equal = TRUE,
  conf.level = 0.95
)

t.test( 
  coef_df$poly.blur..2.2,
  alternative = "two.sided",
  paired = FALSE,
  var.equal = TRUE,
  conf.level = 0.95
)

t.test( 
  coef_df$contrast,
  alternative = "two.sided",
  paired = FALSE,
  var.equal = TRUE,
  conf.level = 0.95
)

t.test( 
  coef_df$luminance,
  alternative = "two.sided",
  paired = FALSE,
  var.equal = TRUE,
  conf.level = 0.95
)

coef_df <- bind_rows(model_coefficients) |>
  mutate(subject = list_subject) |>
  tidyr::pivot_longer(-subject, names_to = "predictor", values_to = "estimate") |>
  filter(predictor != "X.Intercept.")

ggplot(coef_df, aes(x = predictor, y = subject, fill = estimate)) +
  geom_tile() + scale_fill_gradient2(
    low = "yellow", mid = "lightblue", high = "purple",
    midpoint = 0,
    # limits = c(-1, 1)
  )

