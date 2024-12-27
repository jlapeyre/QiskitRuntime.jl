using QiskitRuntime
import Dates
using Test
import JSON3

using QiskitRuntime.PrimitiveResults: PrimitiveResult, SamplerPubResult, DataBin

import QiskitRuntime.BitArraysX: BitArrayAlt # , bstring
#import BitsX: BitArrayAlt, bstring

include("test_aqua.jl")
include("test_qiskit_runtime.jl")
