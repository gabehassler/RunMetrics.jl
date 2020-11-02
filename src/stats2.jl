using DataFrames, TimeZones, Statistics

const DESIGN_COLS = Dict("speed" => 2,
                         "climb" => 3)



struct PreDesign
    hr::Vector{Float64}
    time::Vector{Float64}
    date::Float64
    X::Matrix{Float64} # [speed climb]

    function PreDesign(rs::RunSummary)
        return new(rs.hr, rs.time, decimaldate(rs.start_time),
                   [rs.dist ./ rs.time, rs.alt ./ rs.time])
    end
end

function covariate_dimension()
    return 2
end


# function speed_col()
#     return
function exponential_decay(rs::RunSummary, raw::AbstractArray{Float64, 1},
                           α::Float64;
                           initial_value::Float64 = 0.0,
                           x::AbstractArray{Float64, 1} = zeros(length(rs)))
    n = length(rs)
    @assert length(x) == n

    val = initial_value

    for i = 1:n
        val = exp(-α * rs.time[i]) * val + raw[i]
        x[i] = val
    end

    return x
end

function sliding_scale(rs::RunSummary, raw::AbstractArray{Float64, 1},
                        window::Float64;
                        initial_value::Float64 = 0.0,
                        x::AbstractArray{Float64, 1} = zeros(length(rs)))

    # @assert rs.unit_time

    # t_unit = rs.time[1]
    # m = Int(round(window / t_unit))
    # new_window = m * t_unit

    n = length(rs)
    @assert length(x) == n

    val = initial_value

    previous_raw = 0.0
    to_last = window
    last_value = 0.0
    last_ind = 0

    for i = 1:n
        if rs.time[i] > window
            val = window * raw[i]
            x[i] = val
        else
            t_pre = rs.time[i]
            t_post = rs.time[i]
            while to_last < t_pre
                val -= to_last * last_value

                last_ind += 1
                last_value = raw[last_ind]
                t_pre -= to_last
                to_last = rs.time[last_ind]
            end

            to_last -= t_pre
            val -= t_pre * last_value
            val += rs.time[i] * raw[i]
        end
        x[i] = val
    end

    x ./= window

    return x
end




function design_mat(run_sums::Array{RunSummary}, α::Float64;
                    standardize::Bool = false,
                    decay_function::Function = exponential_decay)
    n_runs = length(run_sums)
    ns = [length(rs) for rs in run_sums]
    n = sum(ns)

    n_covars = covariate_dimension()

    X = zeros(n, n_covars + n_runs)
    y = zeros(n)

    offset = 0
    for i = 1:n_runs
        rs = run_sums[i]
        speed = rs.dist ./ rs.time # TODO: buffer
        climb = rs.alt ./ rs.time # TODO: buffer
        x = findall(isnan, speed)
        # @show rs.dist[x]
        # @show rs.time[x]
        speed[x] .= 0
        climb[x] .= 0
        # @show findall(isnan, speed)
        # @show findall(isnan, climb)

        run_rng = (offset + 1):(offset + ns[i])

        speed_decay = @view X[run_rng, 1]
        climb_decay = @view X[run_rng, 2]



        decay_function(rs, speed, α, x = speed_decay)
        decay_function(rs, climb, α, x = climb_decay)

        date_ind = i + n_covars
        X[run_rng, date_ind] .= 1.0
        y[run_rng] .= rs.hr

        offset += ns[i]
    end

    if standardize
        for j = 2:3
            μ = 0.0
            σ2 = 0.0
            for i = 1:n
                μ += X[i, j]
                σ2 += X[i, j] * X[i, j]
            end
            μ = μ / n
            σ2 = σ2 / n - μ * μ

            X[:, j] .-= μ
            X[:, j] ./= sqrt(σ2)
        end
    end
    return y, X
end



