using RunMetrics, Test

cd(@__DIR__)

tol = 1e-10

sample_data = joinpath("..", "sample_data", "sample.tcx")

rs = parse_run(sample_data)
urs = RunMetrics.unit_run_sum(rs)

rt = sum(rs.time)
urt = sum(urs.time)

@test sum(rs.time) ≈ sum(urs.time) atol = tol
@test sum(rs.dist) ≈ sum(urs.dist) atol = tol
@test sum(rs.alt) ≈ sum(urs.alt) atol = tol
@test rs.hr[end] ≈ urs.hr[end] atol = tol
