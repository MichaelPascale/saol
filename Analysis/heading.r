# facing the painting?


all_data |> filter(subject=="PCRM010", trial==36, time>5) |>
  mutate(
    cheading = (((heading - 2*(180/9)*(arm-1)) %% 360) - 90) > 0
  ) |>
  ggplot(aes(x,z,color=cheading, group=arm))+geom_path()+scale_color_viridis_d(option="cividis")



stimloc <-
  tibble(
    arm=1:8,
    x_stim=sin(4 * pi * arm / 18) / 2 * 15 * 5.5 + (cos(4 * pi * arm / 18) * 1.45 * sin(pi / 18) * 15),
    z_stim=cos(4 * pi * arm / 18) / 2 * 15 * 5.5 - (sin(4 * pi * arm / 18) * 1.45 * sin(pi / 18) * 15),
    th_stim = atan2(x_stim, z_stim) * 180/pi
  )



stationary <- filter(all_data, time>0, x==lag(x), z==lag(z), !is.na(arm)) |>
  left_join(stimloc) |>
  mutate(
    theta_pos_rel_stim = heading - (((atan2(x_stim-x, z_stim-z) * 180/pi) + 180) %% 360)
  )

stationary


filter(all_data, subject=="PCRM001", time>0, x!=lag(x), z!=lag(z))

filter(all_data, distance > .01, (distance < 40 & ((row_number() %% 500) == 0)) | (distance > 40 & ((row_number() %% 50) == 0)))

filter(all_data, distance > 35, (row_number() %% 30) == 0)

all_data |>
  mutate(
      # Determine whether the subject is approaching the arm end.
      # Relative heading tells us whether they are facing the end.
      relative_heading = ((heading - 2*(180/9)*(arm-1)) %% 360),
      # Their velocity tells us whether they are actually leaving or not.
      velocity_rel_center=c(0, diff(distance)),
      # FIXME: This approach uses heading, which does not account for the
      # participant moving backwards.
      approach=(!between(relative_heading, 90, 270)) & (velocity_rel_center > 0)
    ) |>
  left_join(stimloc) |>
  mutate(
    theta_pos_rel_stim  = ((((atan2(x_stim-x, z_stim-z) * 180/pi))+180) %%360),
    theta_head_rel_stim = abs(pmin(heading - theta_pos_rel_stim, theta_pos_rel_stim - heading)),
    theta_head_rel_stim = 180 - abs(((theta_head_rel_stim + 180) %% 360) - 180),
#
#     x = x-x_stim,
#     z = z-z_stim
  ) |>
  filter(distance > 32, theta_head_rel_stim < 30) |>
  # ggplot() +
  #   geom_point(aes(x,z, color=theta_head_rel_stim), size=.1) +
  #   scale_color_viridis_c(option="cividis", limits=c(0,180), breaks=seq(0,360, 90)) +
  #   geom_spoke(aes(x,z, angle=-(heading-90) * pi/180, color=theta_head_rel_stim), radius=1) +
  #   annotate("point",x=0,y=0, color="red") +
  #   facet_grid(arm~cut(theta_head_rel_stim, 12)) +
  #   coord_cartesian(c(-5,5),c(-5,5)) +
  #   theme_classic() +
  #   guides(color="none")
  ggplot() +
    geom_point(aes(x,z, color=theta_head_rel_stim), size=.1) +
    scale_color_viridis_c(option="cividis", limits=c(0,180), breaks=seq(0,360, 90)) +
    geom_spoke(aes(x,z, angle=-(heading-90) * pi/180, color=theta_head_rel_stim), radius=1) +
    geom_point(aes(x_stim, z_stim), color="red", data=stimloc) +
    coord_cartesian() +
    theme_classic() +
    guides(color="none")


stimloc |>
  group_by(arm) |>
  reframe(
      x=x_stim+seq(-7.5,7.5, .5), x_stim,
      z=z_stim+seq(-7.5,7.5, .5), z_stim, th_stim
  ) |>
  group_by(arm) |>
  tidyr::expand(x,z,x_stim,z_stim, th_stim) |>
  mutate(
    theta_pos_rel_stim = (((atan2(x_stim-x, z_stim-z) * 180/pi)+180)%%360)
  ) |>
  ggplot() +
  geom_point(aes(x,z, color=theta_pos_rel_stim)) + scale_color_viridis_c(option="cividis") +
  geom_point(aes(x_stim, z_stim), color="red", data=stimloc)



filter(all_data, time < 0 , (row_number() %% 10) ==0, lag(heading) < heading) |>
  left_join(stimloc) |>
  mutate(
    theta_pos_rel_stim = ((heading - ((((atan2(x_stim-x, z_stim-z) * 180/pi))+180) %%360)))
  )|>
  ggplot() + geom_point(aes(time,heading, color=heading, group=trial), size=.1)


all_data|>mutate(heading=round(heading))|>distinct(heading)|>mutate(x=0,y=0,xend=x+sin(heading*pi/180), yend=y+cos(heading*pi/180)) |> ggplot() +
  # geom_spoke(aes(x,y,angle=-(heading-90)*pi/180, color=heading), radius=1) +
  geom_segment(aes(x,y,xend=xend,yend=yend, color=heading)) +
  scale_color_viridis_c()



b <- read_delim("boundary2.obj", " ", comment="#", col_names = c("type", "x", "z", "y"), col_types=c("c", "d", "d", "d"), skip=3)

l <- filter(b, type == 'l') |> mutate(edge=row_number()) |> select(edge, i=x, j=z)
v <- filter(b, type == 'v') |> mutate(i = row_number())


left_join(
  l,
  data.frame(
    arm=rep(1:8, each=7),
    edge=c(

      6, 7, 16, 17, 48, 49, 50,
      1, 13, 18, 31, 51, 52, 53,
      14, 15, 19, 20, 54, 55, 56,
      12, 21, 22, 23, 45, 57, 58,
      10, 24, 25, 44, 59, 60, 61,
      9, 26, 27, 28, 42, 62, 63,
      8, 29, 30, 40, 64, 65, 66,
      2, 3, 4, 5, 32, 33, 34
    ))
) |>
  left_join(v) |>
  left_join(select(v, x2=x,z2=z, j=i)) |>
  select(-type,-y,edge,arm,x1=x,z1=z,x2,z2, v1=i,v2=j) |>
  ggplot() + geom_segment(aes(x1,z1,xend=x2,yend=z2,color=factor(arm))) +
  geom_text(aes(x=(x1+x2)/2, y=(z1+z2)/2, label=edge), size=3) +
  coord_equal() + theme_classic() + guides(color="none")


boundary |> pivot_longer(c(v1,v2,x1:z2),names_to=c(".value", "p"), names_pattern="(x|z|v)(\\d)") |>
  filter(arm==1) |> nest(mat=c(x,z),.by=edge) |> mutate(mat=map(mat, as.matrix)) |> pull(mat) |> st_multilinestring() |> plot()

sfbounds <- boundary |>
  pivot_longer(c(v1,v2,x1:z2),names_to=c(".value", "p"), names_pattern="(x|z|v)(\\d)") |>
  nest(mat=c(x,z),.by=c(arm, edge)) |>
  summarize(.by=arm, bounding_mls=st_sfc(st_multilinestring(map(mat, as.matrix))))

ggplot(sfbounds) + geom_sf(aes(geometry=bounding_mls, color=arm))



all_data |>
  left_join(stimloc) |>
  mutate(
    theta_pos_rel_stim  = ((((atan2(x_stim-x, z_stim-z) * 180/pi))+180) %%360),
    theta_head_rel_stim = abs(pmin(heading - theta_pos_rel_stim, theta_pos_rel_stim - heading)),
    theta_head_rel_stim = 180 - abs(((theta_head_rel_stim + 180) %% 360) - 180),
    #
    #     x = x-x_stim,
    #     z = z-z_stim
  ) |>
  filter(distance > 20, theta_head_rel_stim < 30, row_number() %% 1000 == 0) |>
  left_join(sfbounds) |>
  rowwise() |>
  mutate(
    line=st_sfc(st_linestring(matrix(c_across(c(x,z,x_stim,z_stim)), byrow=T, ncol=2))),
    obstructed=st_intersects(line, bounding_mls, sparse=F)[,1], .before=x
  ) |>

  ggplot() +
  geom_sf(data=sfbounds, aes(geometry=bounding_mls)) +
  geom_point(aes(x,z, color=obstructed), size=.1) +
  geom_segment(aes(x,z,xend=x_stim,yend=z_stim, color=obstructed)) +
  geom_point(aes(x_stim, z_stim), color="red", data=stimloc) +
  # scale_color_viridis_d(option="cividis") +
  scale_color_distiller(palette="PiYG") +
  theme_classic() +
  guides(color="none")



all_data |>
  left_join(stimloc) |>
  mutate(
    theta_pos_rel_stim  = ((((atan2(x_stim-x, z_stim-z) * 180/pi))+180) %%360),
    theta_head_rel_stim = abs(pmin(heading - theta_pos_rel_stim, theta_pos_rel_stim - heading)),
    theta_head_rel_stim = 180 - abs(((theta_head_rel_stim + 180) %% 360) - 180),
    #
    #     x = x-x_stim,
    #     z = z-z_stim
  ) |>
  filter(distance > 8, row_number() %% 500 == 0) |>
  left_join(sfbounds) |>
  rowwise() |>
  mutate(
    line=st_sfc(st_linestring(matrix(c_across(c(x,z,x_stim,z_stim)), byrow=T, ncol=2))),
    obstructed=st_intersects(line, bounding_mls, sparse=F)[,1], .before=x
  ) |>
  ggplot() +
  geom_sf(data=sfbounds, aes(geometry=bounding_mls)) +
  geom_point(aes(x,z, color=theta_head_rel_stim, alpha=if_else(obstructed, .4, .9)), size=.1) +
  scale_color_viridis_c(option="cividis", limits=c(0,180), breaks=seq(0,360, 90)) +
  geom_spoke(aes(x,z, angle=-(heading-90) * pi/180, color=theta_head_rel_stim, alpha=if_else(obstructed, .4, .9)), radius=1) +
  geom_point(aes(x_stim, z_stim), color="red", data=stimloc) +
  theme_classic() +
  guides(color="none", alpha="none")



all_data |>
  filter(distance > 8, row_number() %%10==0) |>
  left_join(stimloc) |>
  mutate(
    theta_pos_rel_stim  = ((((atan2(x_stim-x, z_stim-z) * 180/pi))+180) %%360),
    theta_head_rel_stim = abs(pmin(heading - theta_pos_rel_stim, theta_pos_rel_stim - heading)),
    theta_head_rel_stim = 180 - abs(((theta_head_rel_stim + 180) %% 360) - 180),
  ) |>
  left_join(sfbounds) |>
  rowwise() |>
  mutate(
    line=st_sfc(st_linestring(matrix(c_across(c(x,z,x_stim,z_stim)), byrow=T, ncol=2))),
    obstructed=st_intersects(line, bounding_mls, sparse=F)[,1],
    obstructed=obstructed | (theta_head_rel_stim > 70)
  ) |>
  ggplot() +
  geom_sf(data=sfbounds, aes(geometry=bounding_mls)) +
  geom_point(aes(x,z, color=theta_head_rel_stim, alpha=if_else(obstructed, .2, .8)), size=.1) +
  scale_color_viridis_c(option="cividis", limits=c(0,180), breaks=seq(0,360, 90)) +
  geom_spoke(aes(x,z, angle=-(heading-90) * pi/180, color=theta_head_rel_stim, alpha=if_else(obstructed, .2, .8)), radius=1) +
  geom_point(aes(x_stim, z_stim), color="red", data=stimloc) +
  theme_classic() +
  guides(color="none", alpha="none")
