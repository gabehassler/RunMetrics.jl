export RunSummary

struct RunSummary
    time::Vector{Float64} # seconds
    dist::Vector{Float64}
    alt::Vector{Float64}
    hr::Vector{Float64}

    function RunSummary(n::Int)
        return new(nan_vec(n), nan_vec(n), nan_vec(n), nan_vec(n))
    end
end

function nan_vec(n::Int)
    v = Vector{Float64}(undef, n)
    fill!(v, NaN)
    return v
end
