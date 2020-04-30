using RunMetrics

tcx_dir = joinpath(@__DIR__, "..", "sample_data", "multi")

files = readdir(tcx_dir)
run_sums = Vector{RunSummary}(undef, 0)


for file in files
    if endswith(file, ".tcx")
        path = joinpath(tcx_dir, file)
        if isrun(path)
            rs = parse_run(path)
            push!(run_sums, rs)

        end
    end
end


β = RunMetrics.multi_regress(run_sums, 116.0)
# β_speed = β[1]
# β_alt = β[2]
# β_time = β[3:end]
# dates = [x.start_time for x in run_sums]
