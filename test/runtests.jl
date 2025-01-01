using QiskitRuntime
import Dates
using Test
import JSON3

using QiskitRuntime.PrimitiveResults: PrimitiveResult, SamplerPubResult, DataBin

import QiskitRuntime.BitArraysX: BitArrayAlt

import Documenter

old_user_dir = get_env(:QISKIT_USER_DIR)
set_env!(:QISKIT_USER_DIR, joinpath(pkgdir(QiskitRuntime), "test", ".qiskit"))

try
    Documenter.DocMeta.setdocmeta!(QiskitRuntime, :DocTestSetup, :(using QiskitRuntime); recursive=true)
    Documenter.doctest(QiskitRuntime)
    include("test_qiskit_runtime.jl")
catch
    set_env!(:QISKIT_USER_DIR, old_user_dir)
    throw(ErrorException("tests failed"))
end

set_env!(:QISKIT_USER_DIR, old_user_dir)

include("test_aqua.jl")
