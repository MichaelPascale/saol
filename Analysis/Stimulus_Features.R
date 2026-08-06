library(stringr)
library(dplyr)
library(purrr)
library(brglm2)
library(exifr)
library(ggplot2)
library(imager)
library(rstatix)
#library(magick)

calc_image_metrics_combined <- function(filename){
  message(filename)
  my_pic <- load.image(filename)
  
  # Lab metrics
  lab <- RGBtoLab(my_pic)
  
  # HSV metrics
  hsv <- RGBtoHSV(my_pic)
  saturation <- hsv[,,2]
  saturation[is.nan(saturation)] <- 0
  
  hue <- hsv[,,1]
  color_section <- table(cut(hue, seq(0,360,2), include.lowest = T))/(500*500)
  vec <- as.data.frame(color_section)[,2]
  #drop 0 to avoid NaN resulting from log2
  vec <- vec[vec > 0]
  #compute entropy
  
  
  data.frame( 
    luminance = mean(lab[,,1]),
    contrast = sd(lab[,,1]),
    saturation = mean(saturation),
    entropy = -sum(vec * log2(vec)),
    file = filename
  )
}

#calc_image_metrics <- function(filename){
#  message(filename)
#  my_pic <- readImage(filename)
#  my_pic <- RGB_to_Lab(my_pic * 255)
#  data.frame( 
#    luminance = mean(my_pic[,,1]),
#    contrast = sd(my_pic[,,1]),
#    file = filename
#  )
#}

files <- dir("/Users/caglalev/Desktop/UROP 26/pcrmsp26_blurred_stimuli", full.names = TRUE)
image_metrics <- map(files, calc_image_metrics_combined) |> bind_rows() |>
  mutate(
    base_name = str_remove(basename(file), "\\.(jpe?g|png)$"),
    uniqueID = str_extract(base_name, "^.*?(?=\\_\\d)|.+"),
    blur = coalesce(as.numeric(str_extract(base_name, "(?<=_)\\d+$")), 0)
  ) |>
  select(-base_name, -file)

all_data <- readRDS("/Users/caglalev/Desktop/UROP 26/data_form_model_allsubjects.rds")
result <- left_join(all_data, image_metrics, by = c("uniqueID", "blur")) #|> mutate(
  #blur = scale(blur)[,1],
  #luminance = scale(luminance)[,1],
  #contrast = scale(contrast)[,1])
saliance_stats <- read.csv("/Users/caglalev/Desktop/PCRM/salience_stats2.csv")

result <- left_join(result, saliance_stats, by = c("uniqueID", "blur"))
#saveRDS(result, "/Users/caglalev/Desktop/UROP 26/result_allsubjects_with_metrics.rds")

#result <- readRDS("/Users/caglalev/Desktop/UROP 26/result_allsubjects_with_metrics.rds")

####Original_File_size####
#metadata <- read_exif(files)
#metadata %>% 
  #select(any_of(c("FileName", "FileSize", "FileType", "ImageWidth", "ImageHeight", 
                  #"Compression", "Megapixels", "ColorSpace", "ProfileName")))
#metadata <- metadata %>% 
  #select(matches("Name|Length|Size|Image|Profile|Thumb"))

#size_table <- metadata %>%
  #select(FileName, FileSize, ThumbnailLength) %>%
  #mutate(
    #content_size = coalesce(FileSize - ThumbnailLength, FileSize), 
    #uniqueID = str_remove(FileName, "\\.(jpe?g|png)$"),
    #blur = coalesce(as.numeric(str_extract(uniqueID, "(?<=_)\\d+$")), 0),
    #uniqueID = str_extract(uniqueID, "^.*?(?=\\_\\d)|.+"),
  #) %>%
  #select(-FileName)

#result_jpeg <- left_join(all_data, size_table, by = c("uniqueID", "blur")) |> mutate(
  #blur = scale(blur)[,1],
  #content_size = scale(content_size)[,1])

####Saturation####
#calc_image_metrics_saturation <- function(filename){
#  message(filename)
#  my_pic <- readImage(filename)
#  my_pic <- RGB_to_HSV(my_pic * 255)
#  saturation <- (my_pic[,,2])
#  saturation[is.nan(saturation)] <- 0
#  data.frame( 
#    saturation = mean(saturation),
#    file = filename
#  )
#}

#files <- dir("/Users/caglalev/Desktop/UROP 26/pcrmsp26_blurred_stimuli", full.names = TRUE)
#image_metrics <- map(files, calc_image_metrics_combined) |> bind_rows() |>
  #mutate(
    #base_name = str_remove(basename(file), "\\.(jpe?g|png)$"),
    #uniqueID = str_extract(base_name, "^.*?(?=\\_\\d)|.+"),
    #blur = coalesce(as.numeric(str_extract(base_name, "(?<=_)\\d+$")), 0)
  #) |>
  #select(-base_name, -file)

#all_data <- readRDS("/Users/caglalev/Desktop/UROP 26/data_form_model_allsubjects.rds")
#result <- left_join(result, image_metrics, by = c("uniqueID", "blur")) #|> mutate(
  #blur = scale(blur)[,1],
  #saturation = scale(saturation)[,1])

#files <- dir("/Users/caglalev/Desktop/UROP 26/pcrmsp26_blurred_stimuli", full.names = TRUE)
#for(file in files) {
#  image <- readImage(file) 
#  new_file <- str_replace(file, "blurred_stimuli", "compressed_stimuli")
#  new_file <- str_replace(new_file, "png", "jpg")
#  writeImage(image, new_file, quality = 0.75)
#}

####Compressed_File_Size####
new_files <- dir("/Users/caglalev/Desktop/UROP 26/pcrmsp26_compressed_stimuli", full.names = TRUE)
metadata <- read_exif(new_files)
metadata %>% 
  select(any_of(c("FileName", "FileSize", "FileType", "ImageWidth", "ImageHeight", 
                  "Compression", "Megapixels", "ColorSpace", "ProfileName")))
metadata <- metadata %>% 
  select(matches("Name|Length|Size|Image|Profile|Thumb"))

size_table <- metadata %>%
  select(FileName, FileSize) %>%
  mutate(
    uniqueID = str_remove(FileName, "\\.(jpe?g|png)$"),
    blur = coalesce(as.numeric(str_extract(uniqueID, "(?<=_)\\d+$")), 0),
    uniqueID = str_extract(uniqueID, "^.*?(?=\\_\\d)|.+"),
  ) %>%
  select(-FileName)

ggplot(size_table, aes(x = blur, y = FileSize, color = uniqueID)) +
  geom_line(alpha = 0.2) +
  guides(color = "none")

result <- left_join(result, size_table, by = c("uniqueID", "blur")) |> mutate(
  blur = scale(blur)[,1],
  FileSize = scale(FileSize)[,1],
  saturation = scale(saturation)[,1],
  luminance = scale(luminance)[,1],
  contrast = scale(contrast)[,1],
  gaze = scale(gaze_entropy_nats)[,1],
  saliance = scale(max_sal_rr_unif)[,1]
)

list_subject <- unique(result$subject)
models <- list()
model_coefficients <- list()
AIC <- list()
for (subject in list_subject) {
  fit_model <- glm(outcome ~ poly(blur,2) + position +contrast + luminance, data = result[result$subject == subject,], family = "binomial", method = brglmFit)
  models <- c(models, list(fit_model))
  model_coefficients <- c(model_coefficients, list(data.frame(t(coef(fit_model))))
  )
  AIC_luminance_contrast <- append(AIC,fit_model$aic)
}

coef_df_luminance_contrast <- bind_rows(model_coefficients) 

t.test( 
  coef_df_luminance_contrast$poly.blur..2.1,
  alternative = "two.sided",
  paired = FALSE,
  var.equal = TRUE,
  conf.level = 0.95
)

t.test( 
  coef_df_luminance_contrast$poly.blur..2.2,
  alternative = "two.sided",
  paired = FALSE,
  var.equal = TRUE,
  conf.level = 0.95
)

t.test( 
  coef_df_luminance_contrast$contrast,
  alternative = "two.sided",
  paired = FALSE,
  var.equal = TRUE,
  conf.level = 0.95
)

t.test( 
  coef_df_luminance_contrast$luminance,
  alternative = "two.sided",
  paired = FALSE,
  var.equal = TRUE,
  conf.level = 0.95
)

coef_df_luminance_contrast <- bind_rows(model_coefficients) |>
  mutate(subject = list_subject) |>
  tidyr::pivot_longer(-subject, names_to = "predictor", values_to = "estimate") |>
  filter(predictor != "X.Intercept.") |>
  mutate(model_name = "luminance_contrast")

#coef_df_poly.blur..2.1 <- bind_rows(model_coefficients) |>
  #mutate(subject = list_subject) |>
  #tidyr::pivot_longer(-subject, names_to = "predictor", values_to = "estimate") |>
  #filter(predictor != "X.Intercept.") |>
  #mutate(model_name = poly.blur..2.1)

ggplot(coef_df_luminance_contrast, aes(x = predictor, y = subject, fill = estimate)) +
  geom_tile() + scale_fill_gradient2(
    low = "yellow", mid = "lightblue", high = "purple",
    midpoint = 0,
    # limits = c(-1, 1)
  )
 
list_subject <- unique(result$subject)
models <- list()
model_coefficients <- list()
AIC_file_size <- list()
for (subject in list_subject) {
  fit_model <- glm(outcome ~ poly(blur,2) + position + poly(FileSize,2), data = result[result$subject == subject,], family = "binomial", method = brglmFit)
  models <- c(models, list(fit_model))
  model_coefficients <- c(model_coefficients, list(data.frame(t(coef(fit_model))))
  )
  AIC_file_size <- c(AIC_file_size,list(fit_model$aic))
}

coef_df_file_size <- bind_rows(model_coefficients) |>
  mutate(subject = list_subject) |>
  tidyr::pivot_longer(-subject, names_to = "predictor", values_to = "estimate") |>
  filter(predictor != "X.Intercept.")|>
  mutate(model_name = "file_size")

ggplot(coef_df_file_size, aes(x = predictor, y = subject, fill = estimate)) +
  geom_tile() + scale_fill_gradient2(
    low = "yellow", mid = "lightblue", high = "purple",
    midpoint = 0,
  )

t.test( 
  coef_df_file_size$estimate[coef_df_file_size$predictor == "poly.FileSize..2.1"],
  alternative = "two.sided",
  paired = FALSE,
  var.equal = TRUE,
  conf.level = 0.95
)

t.test( 
  coef_df_file_size$estimate[coef_df_file_size$predictor == "poly.FileSize..2.2"],
  alternative = "two.sided",
  paired = FALSE,
  var.equal = TRUE,
  conf.level = 0.95
)

t.test( 
  coef_df_file_size$estimate[coef_df_file_size$predictor == "poly.blur..2.1"],
  alternative = "two.sided",
  paired = FALSE,
  var.equal = TRUE,
  conf.level = 0.95
)

t.test( 
  coef_df_file_size$estimate[coef_df_file_size$predictor == "poly.blur..2.2"],
  alternative = "two.sided",
  paired = FALSE,
  var.equal = TRUE,
  conf.level = 0.95
)

list_subject <- unique(result$subject)
models <- list()
model_coefficients <- list()
AIC_saturation <- list()
for (subject in list_subject) {
  fit_model <- glm(outcome ~ poly(blur,2) + position + saturation, data = result[result$subject == subject,], family = "binomial", method = brglmFit)
  models <- c(models, list(fit_model))
  model_coefficients <- c(model_coefficients, list(data.frame(t(coef(fit_model))))
  )
  AIC_saturation <- c(AIC_saturation,list(fit_model$aic))
}

coef_df_saturation <- bind_rows(model_coefficients) |>
  mutate(subject = list_subject) |>
  tidyr::pivot_longer(-subject, names_to = "predictor", values_to = "estimate") |>
  filter(predictor != "X.Intercept.") |>
  mutate(model_name = "saturation")

ggplot(coef_df_saturation, aes(x = predictor, y = subject, fill = estimate)) +
  geom_tile() + scale_fill_gradient2(
    low = "yellow", mid = "lightblue", high = "purple",
    midpoint = 0,
  )

t.test( 
  coef_df_saturation$estimate[coef_df_saturation$predictor == "saturation"],
  alternative = "two.sided",
  paired = FALSE,
  var.equal = TRUE,
  conf.level = 0.95
)

#left_join(size_table, distinct(all_data, uniqueID, blur, sigma))

#ggplot(data = filter(size_table,blur >= 0), aes(x = blur, y = content_size, color = uniqueID)) +
  #geom_line(alpha = 0.2) +
  #guides(color = "none")

#list_subject <- unique(result_jpeg$subject)
#models <- list()
#model_coefficients <- list()
#for (subject in list_subject) {
  #fit_model <- glm(outcome ~ poly(blur,2) + position + content_size, data = result_jpeg[result_jpeg$subject == subject,], family = "binomial", method = brglmFit)
  #models <- c(models, list(fit_model))
  #model_coefficients <- c(model_coefficients, list(data.frame(t(coef(fit_model))))
  #)}

#coef_df <- bind_rows(model_coefficients) |>
  #mutate(subject = list_subject) |>
  #tidyr::pivot_longer(-subject, names_to = "predictor", values_to = "estimate") |>
  #filter(predictor != "X.Intercept.")

#ggplot(coef_df, aes(x = predictor, y = subject, fill = estimate)) +
  #geom_tile() + scale_fill_gradient2(
    #low = "yellow", mid = "lightblue", high = "purple",
    #midpoint = 0,
  #)

list_subject <- unique(result$subject)
models <- list()
model_coefficients <- list()
AIC <- list()
for (subject in list_subject) {
  fit_model <- glm(outcome ~ poly(blur,2) + position + gaze, data = result[result$subject == subject,], family = "binomial", method = brglmFit)
  models <- c(models, list(fit_model))
  model_coefficients <- c(model_coefficients, list(data.frame(t(coef(fit_model))))
  )
  AIC_gaze <- append(AIC,fit_model$aic)
}

coef_df_gaze <- bind_rows(model_coefficients) |>
  mutate(subject = list_subject) |>
  tidyr::pivot_longer(-subject, names_to = "predictor", values_to = "estimate") |>
  filter(predictor != "X.Intercept.") |>
  mutate(model_name = "gaze")

ggplot(coef_df_gaze, aes(x = predictor, y = subject, fill = estimate)) +
  geom_tile() + scale_fill_gradient2(
    low = "yellow", mid = "lightblue", high = "purple",
    midpoint = 0,
  )
t.test( 
  coef_df_gaze$estimate[coef_df_gaze$predictor == "gaze"],
  alternative = "two.sided",
  paired = FALSE,
  var.equal = TRUE,
  conf.level = 0.95
)

list_subject <- unique(result$subject)
models <- list()
model_coefficients <- list()
AIC <- list()
for (subject in list_subject) {
  fit_model <- glm(outcome ~ poly(blur,2) + position + saliance, data = result[result$subject == subject,], family = "binomial", method = brglmFit)
  models <- c(models, list(fit_model))
  model_coefficients <- c(model_coefficients, list(data.frame(t(coef(fit_model))))
  )
  AIC_saliance <- append(AIC,fit_model$aic)
}

coef_df_saliance <- bind_rows(model_coefficients) |>
  mutate(subject = list_subject) |>
  tidyr::pivot_longer(-subject, names_to = "predictor", values_to = "estimate") |>
  filter(predictor != "X.Intercept.") |>
  mutate(model_name = "saliance")

ggplot(coef_df_saliance, aes(x = predictor, y = subject, fill = estimate)) +
  geom_tile() + scale_fill_gradient2(
    low = "yellow", mid = "lightblue", high = "purple",
    midpoint = 0,
  )
t.test( 
  coef_df_saliance$estimate[coef_df_saliance$predictor == "saliance"],
  alternative = "two.sided",
  paired = FALSE,
  var.equal = TRUE,
  conf.level = 0.95
)

#hue <- load.image("/Users/caglalev/Desktop/UROP 26/pcrmsp26_blurred_stimuli/light_switch.png")
#HSV <- RGBtoHSV(hue)
#hue <- HSV[,,1]
#color_section <- table(cut(hue, seq(0,360,2), include.lowest=T))/(500*500)
  #vec <- as.data.frame(color_section)[,2]
  #drop 0 to avoid NaN resulting from log2
  #vec<-vec[vec>0]
  #compute entropy
  #-sum(vec * log2(vec))

  #ggplot(result, aes(x = entropy,)) + 
    #geom_histogram()
  
list_subject <- unique(result$subject)
models <- list()
model_coefficients <- list()
AIC <- list()
for (subject in list_subject) {
    fit_model <- glm(outcome ~ poly(blur,2) + position + entropy, data = result[result$subject == subject,], family = "binomial", method = brglmFit)
    models <- c(models, list(fit_model))
    model_coefficients <- c(model_coefficients, list(data.frame(t(coef(fit_model))))
    )
    AIC_color_entropy <- append(AIC,fit_model$aic)
  }
  coef_df_color_entropy <- bind_rows(model_coefficients) |>
    mutate(subject = list_subject) |>
    tidyr::pivot_longer(-subject, names_to = "predictor", values_to = "estimate") |>
    filter(predictor != "X.Intercept.") |>
    mutate(model_name = "color_entropy")
  
  ggplot(coef_df_color_entropy, aes(x = predictor, y = subject, fill = estimate)) +
    geom_tile() + scale_fill_gradient2(
      low = "yellow", mid = "lightblue", high = "purple",
      midpoint = 0,
    )
  t.test( 
    coef_df_color_entropy$estimate[coef_df_color_entropy$predictor == "entropy"],
    alternative = "two.sided",
    paired = FALSE,
    var.equal = TRUE,
    conf.level = 0.95
  )

AIC <- bind_rows(AIC_color_entropy, AIC_file_size, AIC_gaze, AIC_luminance_contrast, AIC_saliance, AIC_saturation)
coef_df <- bind_rows(coef_df_color_entropy, coef_df_file_size, coef_df_gaze, coef_df_luminance_contrast, coef_df_saliance, coef_df_saturation)

filter(coef_df,!str_detect(predictor,"position|blur")) |>
mutate(predictor = case_when(
  predictor == "gaze"  ~ "Gaze Entropy",
  predictor == "entropy"  ~ "Color Entropy",
  predictor == "poly.FileSize..2.2" ~ "File Size"
  .default = predictor
), predictor = factor(predictor, c("luminance", "contrast", "saturation", "Color Entropy", "Gaze Entropy", "saliance"))
) |>
  ggplot() +
  geom_hline(yintercept = 0, linetype = "dashed") +
  stat_summary(aes(x = predictor, y = estimate, color = predictor), fun.data = mean_cl_normal) + 
  theme_classic() +
  guides(color = "none") +
  scale_color_viridis_d(option="plasma")

filter(coef_df,str_detect(predictor,"position|blur")) |>
  ggplot() +
  geom_hline(yintercept = 0, linetype = "dashed") +
  stat_summary(aes(x = predictor, y = estimate, color = model_name), fun.data = mean_cl_normal) + 
  facet_wrap( ~ subject) +
  theme_classic() +
  scale_color_viridis_d(option="plasma") +
  theme(axis.text.x = element_text(angle = 90), legend.position = "top") 

select(ungroup(result), blur, luminance, contrast, saturation,entropy,gaze_entropy_nats,max_sal_rr_unif,FileSize) |> cor()


