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

function

# function speed_col()
#     return


function design_mat(run_sums::Array{RunSummary}, α::Float64;
                    standardize::Bool = false)
    n_runs = length(run_sums)
    ns = [length(rs) for rs in run_sums]
    n = sum(ns)

    n_covars = covariate_dimension()

    X = zeros(n, n_covars + n_runs + 1)
    y = zeros(n)
    X[:, 1] .= 1.0

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

        current_speed_sum = 0.0
        current_climb_sum = 0.0
        current_t = 0.0

        date_ind = i + n_covars + 1

        for j = 1:ns[i]
            row_ind = j + offset
            t_diff = rs.time[j] - current_t
            decay = exp(-α * t_diff)
            X[row_ind, 1] = 1.0 # intercept
            current_speed_sum = speed[j] + current_speed_sum * decay
            current_climb_sum = climb[j] + current_climb_sum * decay
            X[row_ind, 2] = current_speed_sum
            X[row_ind, 3] = current_climb_sum

            X[row_ind, date_ind] = 1.0

            y[row_ind] = rs.hr[j]
        end

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



