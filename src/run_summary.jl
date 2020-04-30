export RunSummary

using TimeZones

struct RunSummary
    time::Vector{Float64} # seconds
    dist::Vector{Float64}
    alt::Vector{Float64}
    hr::Vector{Float64}
    unit_time::Bool
    start_time::ZonedDateTime

    function RunSummary(n::Int, time::ZonedDateTime; unit_time::Bool = false)
        return new(nan_vec(n), nan_vec(n), nan_vec(n), nan_vec(n), unit_time, time)
    end

end

function nan_vec(n::Int)
    v = Vector{Float64}(undef, n)
    fill!(v, NaN)
    return v
end


import Base.length
function length(rs::RunSummary)
    return length(rs.time)
end

# function copyrow!(dest::RunSummary, src::RunSummary, ind::Int)
#     dest.time[i] = src.time[i]
#     dest.dist[i] = src.dist[i]
#     dest.hr[i] = src.hr[i]
#     dest.alt[i] = src.alt[i]
# end

function unit_run_sum(rs::RunSummary; unit_time = 1.0)
    n = Int(round(sum(rs.time)))

    unit_rs = RunSummary(n, rs.start_time, unit_time = true)

    m = length(rs)

    leftover = 0.0
    ind = 1
    res_time = 0.0
    res_dist = 0.0
    old_unit_dist = 0.0
    old_hr = rs.hr[1]
    old_alt = rs.alt[1]
    old_unit_Δhr = 0.0

    for i = 1:m
        t = rs.time[i] + res_time

        if t < unit_time
            res_time = t
            res_dist += rs.dist[i]
            continue
        end

        unit_dist = rs.dist[i] / rs.time[i]
        unit_alt = rs.alt[i] / rs.time[i]
        unit_Δhr = (rs.hr[i] - old_hr) / rs.time[i]

        α = res_time / unit_time
        β = unit_time - α

        unit_rs.time[ind] = unit_time
        unit_rs.dist[ind] = α * old_unit_dist + β * unit_dist
        unit_rs.hr[ind] = old_hr + α * old_unit_Δhr + β * unit_Δhr
        unit_rs.alt[ind] = α * old_alt + β * unit_alt

        ind += 1

        t -= unit_time

        while t >= 1.0
            unit_rs.time[ind] = unit_time
            unit_rs.dist[ind] = unit_dist
            unit_rs.hr[ind] = unit_rs.hr[ind - 1] + unit_Δhr
            unit_rs.alt[ind] = unit_alt

            ind += 1
            t -= unit_time
        end

        res_time = t
        old_unit_dist = unit_dist
        old_hr = unit_rs.hr[ind - 1]
        unit_rs.hr[ind - 1]
        old_alt = unit_alt

    end

    return unit_rs
end
