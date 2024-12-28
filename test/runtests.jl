using QiskitRuntime
import Dates
using Test
import JSON3

using QiskitRuntime.PrimitiveResults: PrimitiveResult, SamplerPubResult, DataBin

import QiskitRuntime.BitArraysX: BitArrayAlt

import Documenter

include("test_qiskit_runtime.jl")

Documenter.DocMeta.setdocmeta!(QiskitRuntime, :DocTestSetup, :(using QiskitRuntime); recursive=true)
Documenter.doctest(QiskitRuntime)

include("test_aqua.jl")
