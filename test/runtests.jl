using QiskitRuntime
import Dates
using Test
import JSON3

using QiskitRuntime.PrimitiveResults: PrimitiveResult, SamplerPubResult, DataBin

import QiskitRuntime.BitArraysX: BitArrayAlt

import Documenter


ENV["QISKIT_CONFIG_DIR"] = joinpath(pkgdir(QiskitRuntime), "test", ".qiskit")

try
    Documenter.DocMeta.setdocmeta!(QiskitRuntime, :DocTestSetup, :(using QiskitRuntime); recursive=true)
    Documenter.doctest(QiskitRuntime)
    include("test_qiskit_runtime.jl")
catch
    delete!(ENV, "QISKIT_CONFIG_DIR")
    throw(ErrorException("tests failed"))
end

isnothing(get(ENV, "QISKIT_CONFIG_DIR", nothing)) || delete!(ENV, "QISKIT_CONFIG_DIR")

include("test_aqua.jl")
