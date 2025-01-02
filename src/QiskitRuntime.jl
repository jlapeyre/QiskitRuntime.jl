"""
    module QiskitRuntime

`QiskitRuntime` is a client for the [Qiskit Runtime REST API](https://docs.quantum.ibm.com/api/runtime) written in the Julia language.

`QiskitRuntime` is analagous to the Python-language client [qiskit-ibm-runtime](https://github.com/Qiskit/qiskit-ibm-runtime).

!!! warning

    `QiskitRuntime` is very new, incomplete, and API-unstable.

    `QiskitRuntime.jl` is *completely unsupported*. No person or entity is responsible for providing any support to users of this software.

# Accounts

Many functions, such as `job`, `jobs`, `user` take an optional argument `account`. If
`account` is omitted, then information will be taken from the user's config file
`~/.qisit/qiskit-ibm.json`, or environment variables. The environment variables will be
preferred. See [`Accounts.QuantumAccount`](@ref).

# Layers

There are more or less two layers: An interface to the REST API, and a layer on top that returns data of native and custom
Julia types.

# Caching

Caching is done at the level of entire REST API responses.

Reponses from several endpoints are cached automatically. They can be updated with `refresh=true`. For example
`Requests.job(job_id; refresh=true)`.

Functions in the upper layer also take the keyword argument `refresh` and pass it to the `Requests` layer. For example
`Jobs.job(job_id; refresh=true)`.

Caching is done by dumping the REST responses via JSON3 in `~/.qiskit/runtime_cache/`.
"""
module QiskitRuntime

include("env_vars.jl")
include("ids.jl")
# Vendored at 6065fab7 from QuantumClifford.jl
include("quantum_info/pauli_operators.jl")
include("npz2.jl")
include("bitarraysx.jl")
include("utils.jl")
include("circuits.jl")
include("containers/primitiveresults.jl")
include("decoding.jl")
include("json.jl")
include("pubs.jl")
include("instances.jl")
include("accounts.jl")
include("run_jobs.jl")
include("requests.jl")
include("backends.jl")
include("jobs.jl")

using Reexport: Reexport
include("api.jl")
Reexport.@reexport using .API

# Set this environment var to something other than "false"
# in order to skip precompilation while developing.
if get(ENV, "QISKIT_RUNTIME_NO_PRECOMPILE", "false") == "false"
    include("precompile.jl")
end

end # module QiskitRuntime
