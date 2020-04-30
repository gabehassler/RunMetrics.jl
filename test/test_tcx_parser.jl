using RunMetrics, Test

cd(@__DIR__)

sample_data = joinpath("..", "sample_data", "sample.tcx")

rs = parse_run(sample_data)
n = length(rs)

@test n == 946


lap_df = parse_laps(sample_data)
@test lap_df.seconds[end] == 21.0
@test lap_df.meters[end] == 66.24
