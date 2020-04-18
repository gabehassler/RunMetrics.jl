using RunMetrics, Test

cd(@__DIR__)

sample_data = joinpath("..", "sample_data", "sample.tcx")

rs = parse_tcx(sample_data)
n = size(df, 1)

@test n == 946


lap_df = parse_laps(sample_data)
@test lap_df.seconds[end] == 21.0
@test lap_df.meters[end] == 66.24
