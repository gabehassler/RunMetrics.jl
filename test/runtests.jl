using RunMetrics
using Test, SafeTestsets

@time @safetestset "TCX Parser Tests" begin include("test_tcx_parser.jl") end
@time @safetestset "RunSummary Tests" begin include("test_runsummary.jl") end
