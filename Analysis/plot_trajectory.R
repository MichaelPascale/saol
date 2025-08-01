# Michael Pascale 2025-08-01

library(dplyr)
library(tidyr)
library(ggplot2)
library(rgl)

# Behavioral trajectory to plot.
path <- read.csv('path.csv')
path <- path |> filter(time > 23, time < 64)

# 3D mesh which defines the floorplan.
mesh <- readOBJ("mesh.obj")

vertices <- as.data.frame(t(mesh$vb)[, 1:3])
names(vertices) <- c("x", "y", "z")
vertices <- vertices |>
  mutate(vertex=row_number(),.before=1)

faces <- as.data.frame(t(mesh$it))
faces <- faces |>
  mutate(face=row_number()) |>
  pivot_longer(c(V1, V2, V3), values_to='vertex', values_transform=as.integer)

# To plot the floorplan, include only those faces where all vertices are
# at the lowest y-coordinate.
tri <-
  left_join(faces, vertices) |>
  filter(all(y == -.5), .by=face)

# The origin is shifted, so find the most-connected vertex (18 edges) which
# should be at the center.
center <- count(tri, x, z) |> filter(n == 18)

tri <- tri |>
  mutate(
    #   translate
    x = x - center$x,
    z = z - center$z,
    #       flip  rotate                              scale
    x.rot = -1 * ( x*cos(4*pi/18) + z*sin(4*pi/18)) * 15,
    z.rot =      (-x*sin(4*pi/18) + z*cos(4*pi/18)) * 15
  )


ggplot() +

  # Plot the floorplan.
  geom_polygon(aes(x.rot, z.rot, group=face), data=tri,
               fill = "gray80", color = "black", size = 0.2) +

  # Plot the trajectory.
  geom_point(aes(x,z,color=time), data=path) +

  labs(
    title = 'Single Trial Trajectory',
    x = 'X-position', y='Z-position'
  ) +
  scale_color_viridis_c('Time (s)', limits=c(20, 70)) +
  coord_equal() +
  theme_minimal() +
  theme(
    text=element_text(size=12,  family="Ysabeau Office"),
    legend.position=c(.5,.9), legend.direction = 'horizontal'
  )
