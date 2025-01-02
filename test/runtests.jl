using QiskitRuntime
import Dates
using Test
import JSON3

using QiskitRuntime.PrimitiveResults: PrimitiveResult, SamplerPUBResult, DataBin

import QiskitRuntime.BitArraysX: BitArrayAlt

old_user_dir = get_env(:QISKIT_USER_DIR)
set_env!(:QISKIT_USER_DIR, joinpath(pkgdir(QiskitRuntime), "test", ".qiskit"))

try
    include("test_qiskit_runtime.jl")
    include("test_doctests.jl")
catch
    throw(ErrorException("tests failed"))
finally
    set_env!(:QISKIT_USER_DIR, old_user_dir)
end

include("test_aqua.jl")
