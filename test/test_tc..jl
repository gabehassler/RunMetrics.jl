using RunMetrics

cd(@__DIR__)

path = joinpath("..", "sample_data", "sample.tcx")



rs = parse_tcx(path)
urs = RunMetrics.unit_run_sum(rs)
# X = RunMetrics.make_design(urs, 100.0)

lags = 1.0:1.0:600.0
n = length(lags)
B = zeros(3, n)
ssrs = zeros(n)
for i = 1:n
    X = RunMetrics.make_design(urs, lags[i])

    β, ssr = RunMetrics.regress(urs.hr, X)
    B[:, i] .= β
    ssrs[i] = ssr
end
min_ind = findmin(ssrs)[2]
min_lag = lags[min_ind]
β = B[:, min_ind]
