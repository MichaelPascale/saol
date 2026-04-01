# layouts.r
# Load 3D mesh from Wavefront OBJ file and extract a map for plotting.
#
# Copyright (c) 2025-2026, Michael P. Pascale <mpascale@bu.edu>.
# SPDX-License-Identifier: MIT

load_layout_maze <- function(file) {
  # 3D mesh which defines the floorplan.
  mesh <- rgl::readOBJ(file)

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

  # The triangles that make up the floor should be moved and
  # rotated to the center position, facing north.
  tri <- tri |>
    mutate(
      #   translate
      x = x - center$x,
      z = z - center$z,
      #       flip  rotate                              scale
      x.rot = -1 * ( x*cos(4*pi/18) + z*sin(4*pi/18)) * 15,
      z.rot =      (-x*sin(4*pi/18) + z*cos(4*pi/18)) * 15
    )

  list(mesh=mesh, vertices=vertices, faces=faces, center=center, tri=tri)
}

geom_layout_maze <- function (envir_layout, fill="gray80", color="gray40", linewidth=0.1) {
  geom_polygon(
    aes(x.rot, z.rot, group=face),
    data=envir_layout$tri,
    fill = fill, color = color, linewidth = linewidth
  )
}
