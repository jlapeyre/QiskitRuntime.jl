import Documenter

@testset "Doctests" begin
    Documenter.DocMeta.setdocmeta!(QiskitRuntime, :DocTestSetup, :(using QiskitRuntime); recursive=true)
    Documenter.doctest(QiskitRuntime)
end
