import Documenter

@testset "Doctests" begin
    Documenter.DocMeta.setdocmeta!(QiskitRuntime, :DocTestSetup,
                                   :(using QiskitRuntime, QiskitRuntime.ExtraEnvs); recursive=true)
    Documenter.doctest(QiskitRuntime)
end
