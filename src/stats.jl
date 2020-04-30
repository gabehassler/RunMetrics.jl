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

    X = zeros(n, count_covs()) # intercept, distance, altitude
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

function count_covs()
    return 3 #TODO: need a better way to specify covariates in the model
                # currently uses only speed and altitude
end

function multi_regress(summaries::Vector{RunSummary}, lag::Float64)
    p_base = count_covs()
    p_total = p_base + length(summaries)

    XtX = zeros(p_total, p_total)
    Xty = zeros(p_total)

    n = length(summaries)

    t_unit = 0.0

    for i = 1:n
        rs = summaries[i]
        if !rs.unit_time
            rs = unit_run_sum(rs)
        end

        if i == 1
            t_unit = rs.time[1]
        else
            @assert rs.time[1] == unit
        end

        X = make_design(rs, lag)

        act_start = p_base * i + 1
        act_end = act_start + p_base - 1
        act_rng = act_start:act_end
        design_ind = p_base + i

        #TODO: make below memory efficient
        XtX[1:p_base, 1:p_total] .+= X' * X
        sum_X = sum(X, dims=1)
        XtX[act_rng, design_ind] .= sum_X
        XtX[design_ind, act_rng] .= sum_X

        Xty[1:p_base] .+= X' * rs.hr
        Xty[design_ind] = sum(rs.hr) #TODO: can get this from intercept of Xty?

    end

    return XtX \ Xty
    
end
