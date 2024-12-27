using QiskitRuntime
using Aqua: Aqua

@testset "aqua test ambiguities QiskitRuntime Core Base" begin
    Aqua.test_ambiguities([QiskitRuntime, Core, Base])
end

@testset "aqua unbound_args" begin
    Aqua.test_unbound_args(QiskitRuntime)
end

@testset "aqua undefined exports" begin
    Aqua.test_undefined_exports(QiskitRuntime)
end

@testset "aqua piracies" begin
    Aqua.test_piracies(QiskitRuntime)
end

@testset "aqua project extras" begin
    Aqua.test_project_extras(QiskitRuntime)
end

@testset "aqua state deps" begin
    Aqua.test_stale_deps(QiskitRuntime)
end

@testset "aqua deps compat" begin
    Aqua.test_deps_compat(QiskitRuntime)
end
