library(stringr)
library(dplyr)
library(purrr)
library(brglm2)
library(exifr)
library(ggplot2)
library(imager)
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
luminance_contrast <- for (subject in list_subject) {
  fit_model <- glm(outcome ~ poly(blur,2) + position +contrast + luminance, data = result[result$subject == subject,], family = "binomial", method = brglmFit)
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
 
list_subject <- unique(result$subject)
models <- list()
model_coefficients <- list()
file_size <- for (subject in list_subject) {
  fit_model <- glm(outcome ~ poly(blur,2) + position + FileSize, data = result[result$subject == subject,], family = "binomial", method = brglmFit)
  models <- c(models, list(fit_model))
  model_coefficients <- c(model_coefficients, list(data.frame(t(coef(fit_model))))
  )
}

coef_df <- bind_rows(model_coefficients) |>
  mutate(subject = list_subject) |>
  tidyr::pivot_longer(-subject, names_to = "predictor", values_to = "estimate") |>
  filter(predictor != "X.Intercept.")

ggplot(coef_df, aes(x = predictor, y = subject, fill = estimate)) +
  geom_tile() + scale_fill_gradient2(
    low = "yellow", mid = "lightblue", high = "purple",
    midpoint = 0,
  )

list_subject <- unique(result$subject)
models <- list()
model_coefficients <- list()
saturation <- for (subject in list_subject) {
  fit_model <- glm(outcome ~ poly(blur,2) + position + saturation, data = result[result$subject == subject,], family = "binomial", method = brglmFit)
  models <- c(models, list(fit_model))
  model_coefficients <- c(model_coefficients, list(data.frame(t(coef(fit_model))))
  )
}

coef_df <- bind_rows(model_coefficients) |>
  mutate(subject = list_subject) |>
  tidyr::pivot_longer(-subject, names_to = "predictor", values_to = "estimate") |>
  filter(predictor != "X.Intercept.")

ggplot(coef_df, aes(x = predictor, y = subject, fill = estimate)) +
  geom_tile() + scale_fill_gradient2(
    low = "yellow", mid = "lightblue", high = "purple",
    midpoint = 0,
  )

t.test( 
  coef_df$estimate[coef_df$predictor == "saturation"],
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
gaze <- for (subject in list_subject) {
  fit_model <- glm(outcome ~ poly(blur,2) + position + gaze, data = result[result$subject == subject,], family = "binomial", method = brglmFit)
  models <- c(models, list(fit_model))
  model_coefficients <- c(model_coefficients, list(data.frame(t(coef(fit_model))))
  )
}

coef_df <- bind_rows(model_coefficients) |>
  mutate(subject = list_subject) |>
  tidyr::pivot_longer(-subject, names_to = "predictor", values_to = "estimate") |>
  filter(predictor != "X.Intercept.")

ggplot(coef_df, aes(x = predictor, y = subject, fill = estimate)) +
  geom_tile() + scale_fill_gradient2(
    low = "yellow", mid = "lightblue", high = "purple",
    midpoint = 0,
  )
t.test( 
  coef_df$estimate[coef_df$predictor == "gaze"],
  alternative = "two.sided",
  paired = FALSE,
  var.equal = TRUE,
  conf.level = 0.95
)

list_subject <- unique(result$subject)
models <- list()
model_coefficients <- list()
saliance <- for (subject in list_subject) {
  fit_model <- glm(outcome ~ poly(blur,2) + position + saliance, data = result[result$subject == subject,], family = "binomial", method = brglmFit)
  models <- c(models, list(fit_model))
  model_coefficients <- c(model_coefficients, list(data.frame(t(coef(fit_model))))
  )
}

coef_df <- bind_rows(model_coefficients) |>
  mutate(subject = list_subject) |>
  tidyr::pivot_longer(-subject, names_to = "predictor", values_to = "estimate") |>
  filter(predictor != "X.Intercept.")

ggplot(coef_df, aes(x = predictor, y = subject, fill = estimate)) +
  geom_tile() + scale_fill_gradient2(
    low = "yellow", mid = "lightblue", high = "purple",
    midpoint = 0,
  )
t.test( 
  coef_df$estimate[coef_df$predictor == "saliance"],
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
color_entropy <- for (subject in list_subject) {
    fit_model <- glm(outcome ~ poly(blur,2) + position + entropy, data = result[result$subject == subject,], family = "binomial", method = brglmFit)
    models <- c(models, list(fit_model))
    model_coefficients <- c(model_coefficients, list(data.frame(t(coef(fit_model))))
    )
  }
  coef_df <- bind_rows(model_coefficients) |>
    mutate(subject = list_subject) |>
    tidyr::pivot_longer(-subject, names_to = "predictor", values_to = "estimate") |>
    filter(predictor != "X.Intercept.")
  
  ggplot(coef_df, aes(x = predictor, y = subject, fill = estimate)) +
    geom_tile() + scale_fill_gradient2(
      low = "yellow", mid = "lightblue", high = "purple",
      midpoint = 0,
    )
  t.test( 
    coef_df$estimate[coef_df$predictor == "entropy"],
    alternative = "two.sided",
    paired = FALSE,
    var.equal = TRUE,
    conf.level = 0.95
  )


#ggplot(result,)
#stat_summary()
