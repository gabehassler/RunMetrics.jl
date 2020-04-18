using RunMetrics

cd(@__DIR__)

path = joinpath("..", "sample_data", "sample.tcx")



df = parse_tcx(path)
diff_df = make_diff_df(df)
lap_df = parse_laps(path)
x = 1
