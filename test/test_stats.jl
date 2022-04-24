using RunMetrics, Statistics, Plots, LinearAlgebra, GLM
old_dir = pwd()
example_dir = joinpath(@__DIR__, "..", "sample_data", "multi")

files = readdir(example_dir)

cd(example_dir)

tcx_files = files[findall(x -> endswith(x, ".tcx") && isrun(x), files)]
deleteat!(tcx_files, 6)
deleteat!(tcx_files, 9)


run_sums = [parse_run(tcx) for tcx in tcx_files]

rs = run_sums[1]
# window = 90s seems best (mse = 29.6)
# α = 0.006 seems best (mse = 37.0)
y, X = RunMetrics.design_mat(run_sums, 90.0,
                             decay_function = RunMetrics.sliding_scale,
                             standardize = true)


keep_inds = findall(x -> x > 60.0, X[:, 1])

# X[:, 1] .= log.(X[:, 1])


y = y[keep_inds]
X = X[keep_inds, :]

X = [log.(X[:, 1]) X]

first_run = 5
n, p = size(X)

function logitize(x::Float64, bounds::Tuple{Float64, Float64})
    return (x - bounds[1]) / (bounds[2] - bounds[1])
end

y = logitize.(y, Ref((50.0, 200.0)))

df = DataFrame([y X], [["hr", "log time", "time", "h_speed", "v_speed"]; ["run$i" for i = first_run:p]])
nms = Symbol.(names(df))
form = FormulaTerm(Term(nms[1]), Tuple(Term(nms[i]) for i = 2:p))

ft = glm(form, df, Binomial(), LogitLink())
y_hat = predict(ft)

# X_cont = @view X[:, 1:(first_run - 1)]
# X_cont .= (X_cont - ones(size(X, 1)) * mean(X_cont, dims=1)) * inv(Diagonal(vec(std(X_cont, dims=1))))

# β = inv(X' * X) * X' * y

# y_hat = X * β
mse = var(y_hat - y)
r2 = 1.0 - mse / var(y)
@show mse
@show r2
cd(@__DIR__)



cd(old_dir)

scatter(y_hat, y)

run_inds = [findall(isequal(1.0), @view(X[:, i])) for i = first_run:size(X, 2)]
errs = y - y_hat
p = plot()
for i = 1:length(run_inds)
    p = plot!(run_inds[i], errs[run_inds[i]], legend=false)
end
p = plot!(x -> 0)