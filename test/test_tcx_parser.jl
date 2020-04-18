using RunMetrics, Test

cd(@__DIR__)

sample_data = joinpath("..", "sample_data", "sample.tcx")

df = parse_tcx(sample_data)
n = size(df, 1)

@test n == 946
@test df.distance[n] == 12940.9599609375


function test_ordered(x::AbstractArray)
    n = length(x)
    ordered = true
    for i = 2:n
        if x[i] < x[i- 1]
            ordered = false
            break
        end
    end

    if ordered
        if x[n] <= x[1] # at least some progress should be made
            ordered = false
        end
    end

    return ordered
end

@test test_ordered(df.time)
@test test_ordered(df.distance)

diff_df = make_diff_df(df)

@test size(diff_df, 1) == n - 1
@test diff_df.hr == df.hr[2:end]

lap_df = parse_laps(sample_data)
@test lap_df.seconds[end] == 21.0
@test lap_df.meters[end] == 66.24
