using RunMetrics

cd(@__DIR__)

path = joinpath("..", "sample_data", "sample.tcx")



df = parse_tcx(path)
diff_df = make_diff_df(df)
# avg_speed = running_sum(df, delay = 20)
#
# burnin = 0.1
# start_ind = Int(round(burnin * length(avg_speed)))

# using Plots
#
# scatter(avg_speed[start_ind:end], df.hr[start_ind:end], legend = false,
#         xlab = "speed", ylabel="hr")

# diffs = df.time[2:end] - df.time[1:(end - 1)]
# sort(diffs)

# @show geo_dist(df.pos[1], df.pos[2])

# n = size(df, 1)
# distance = 0.0
# for i = 2:n
#     global distance += geo_dist(df.pos[i], df.pos[i - 1])
# end

lap_df = parse_laps(path)
