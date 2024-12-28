"""
    module QiskitRuntime

`QiskitRuntime` is a client for the [Qiskit Runtime REST API](https://docs.quantum.ibm.com/api/runtime) written in the Julia language.

`QiskitRuntime` is analagous to the Python-language client [qiskit-ibm-runtime](https://github.com/Qiskit/qiskit-ibm-runtime).

!!! warning

    `QiskitRuntime` is very new, incomplete, and API-unstable.

    `QiskitRuntime.jl` is *completely unsupported*. No person or entity is responsible for providing any support to users of this software.

Furthermore, the focus at the moment is more on retreiving data than on submitting workloads.

# Environment variables

The following environment variables override defaults.

- `QISKIT_RUNTIME_CACHE_DIR`: The top-level directory where REST responses are cached.
- `QISKIT_IBM_URL`: The url used for authentication (*not* for REST endpoints).
- `QISKIT_IBM_CHANNEL`:
- `QISKIT_IBM_INSTANCE`: In the form "hub/group/project".
- `QISKIT_IBM_TOKEN`: The authentication token
"""
module QiskitRuntime

# Vendored at 6065fab7 from QuantumClifford.jl
include("quantum_info/pauli_operators.jl")
include("npz2.jl")
include("bitarraysx.jl")
include("utils.jl")
include("some_types.jl")
include("containers/primitiveresults.jl")
include("decoding.jl")
include("json.jl")
include("qasm.jl")
include("pubs.jl")
include("instances.jl")
include("accounts.jl")
include("requests.jl")
include("jobs.jl")
include("backends.jl")

import Reexport
include("api.jl")
Reexport.@reexport using .API

# Comment this out during development for faster compilation when
# restarting.
include("precompile.jl")

end # module QiskitRuntime
