library(OpenImageR)
library(stringr)
library(dplyr)

calc_lum <- function(filename){

  my_pic <- readImage(filename)
  my_pic <- RGB_to_Lab(my_pic * 255)
  mean(my_pic[,,1])

}

calc_contrast <- function(filename){

  my_pic <- readImage(filename)
  my_pic <- RGB_to_Lab(my_pic * 255)
  sd(my_pic[,,1])
# Do these things once, have one function
}

files <- dir("/Users/caglalev/Desktop/UROP 26/pcrmsp26_blurred_stimuli", full.names = TRUE)

contrast <- numeric(length(files))
loom <- numeric(length(files))

for (i in seq_along(files)) {
  message(files[i])
  loom[i] <- calc_lum(files[i])
  contrast[i] <- calc_contrast(files[i])
}


image_metrics <- data.frame(
  contrast = contrast,
  luminance = loom,
  base_name = str_remove(basename(files), "\\.jpe?g$")
) |>
  mutate(
    uniqueID = str_extract(base_name, "^.*?(?=\\_\\d)|.+"),
    blur = coalesce(as.numeric(str_remove(str_extract(base_name, "_\\d+$"),"_")),0)
  )


file_path <- "/Users/caglalev/Desktop/UROP 26/data_for_model_pcrm004.rds"

RDS_data <- readRDS(file_path)
RDS_data <- mutate(RDS_data, blur = blur + 4.5)


result <- left_join(
  RDS_data,
  image_metrics |> select(-"base_name"),
  by = c("uniqueID", "blur")
)

saveRDS(result, "/Users/caglalev/Desktop/UROP 26/data_for_model_pcrm004_with_metrics.rds")
result <- readRDS("/Users/caglalev/Desktop/UROP 26/data_for_model_pcrm004_with_metrics.rds")
summary(glm(outcome ~ blur + luminance + position + contrast, data = result, family = "binomial"))
reg_simple <- lm(outcome ~ luminance, data = result)



