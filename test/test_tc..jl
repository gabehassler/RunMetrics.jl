using RunMetrics

cd(@__DIR__)

path = joinpath("..", "sample_data", "sample.tcx")



rs = parse_tcx(path)
