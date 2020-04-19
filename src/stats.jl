function make_design(rs::RunSummary, lag::Float64)
    if !rs.unit_time
        rs = unit_run_sum(rs)
    end

    unit_time = rs.time[1]

    if lag < unit_time
        error("The 'lag' must be greater than the unit_time (set to 1.0 by default).")
    end

    n_lag = Int(floor(lag / unit_time))

    inv_lag = 1.0 / lag

    n = length(rs)

    X = zeros(n, 3) # intercept, distance, altitude
    X[:, 1] .= 1.0

    current_dist = 0.0
    current_alt = 0.0

    for i = 1:n_lag
        current_dist += rs.dist[i]
        current_alt += rs.alt[i]
        X[i, 2] = current_dist * inv_lag
        X[i, 3] = current_alt * inv_lag
    end

    for i = (n_lag + 1):n
        current_dist += rs.dist[i] - rs.dist[i - n_lag]
        current_alt += rs.alt[i] - rs.alt[i - n_lag]

        X[i, 2] = current_dist * inv_lag
        X[i, 3] = current_alt * inv_lag
    end

    return X

end

function regress(y::Vector{Float64}, X::Matrix{Float64})
    n, p = size(X)
    @assert length(y) == n

    # TODO make more memory efficient if necessary

    xty = X' * y
    xtx = X' * X
    β = xtx \ xty

    res = X * β - y

    ssr = res' * res

    return β, ssr
end
