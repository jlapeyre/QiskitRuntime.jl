"""
    module EnvVars

Enforce documentation and a safe interface to the environment variables used by
QiskitRuntime.jl

"safe" means that typos in environment variable names will result in immediate run time or compile time
errors.
"""
module EnvVars

export env_vars, get_env, set_env!

module _EnvVars

# The Python client uses the env var QISKIT_IBM_RUNTIME_API_URL for the authentication
# url, which is usually "https://auth.quantum-computing.ibm.com/api" I find this name
# confusing. So, I call it QISKIT_IBM_AUTH_URL". In any case, we don't use it.

# If a docstring is missing for any of these, QiskitRuntime will fail to compile
const _ENV_VARS = [
    :QISKIT_USER_DIR,
    :QISKIT_ACCOUNT_NAME,
    :QISKIT_IBM_INSTANCE,
    :QISKIT_IBM_TOKEN,
    :QISKIT_RUNTIME_CACHE_DIR,
    :QISKIT_IBM_CHANNEL,
    :QISKIT_IBM_AUTH_URL,
    :QISKIT_IBM_RUNTIME_LOG_LEVEL,
]

const _var_docs =
    let unused = "Currently unused by QiskitRuntime.jl",
        _var_descr = Dict(
            :QISKIT_USER_DIR => "The directory storing user data for Qiskit Runtime, including credentials and cache.",
            :QISKIT_ACCOUNT_NAME => "The name of the account in the credentials file to use by default.",
            :QISKIT_IBM_INSTANCE => "The instance (\"hub/group/project\") used only when setting the account via environment variables.",
            :QISKIT_IBM_TOKEN => "The token, or API key, used only when setting the account via environment variables.",
            :QISKIT_RUNTIME_CACHE_DIR => "The full path of the REST API response cache overriding the default \$HOME/.qiskit/runtime_cache.",
            :QISKIT_IBM_CHANNEL => "The channel name used only when setting the account via environment variables. $unused",
            :QISKIT_IBM_AUTH_URL => "The url used for authentication. $unused",
            :QISKIT_IBM_RUNTIME_LOG_LEVEL => unused,
        )

        _var_doc(varname) = "`$varname`" * " - " * _var_descr[varname]
        join(map(_var_doc, _ENV_VARS), "\n\n")
    end

# Unused at the moment
# :QISKIT_IBM_RUNTIME_LOG_LEVEL

end # module _EnvVars

import ._EnvVars: _ENV_VARS, _var_docs

"""
    get_env(name::Symbol, default=nothing)

Return the value for environment variable `name`, or `default` if `name` is not present.

!!! note
    An error is thrown if `name` is not an environment variable used by `QiskitRuntime.jl`.
"""
function get_env(name::Symbol, default=nothing)
    name in _ENV_VARS || throw(
        ArgumentError(lazy"Environment variable `$name` is not used by QiskitRuntime.jl"),
    )
    return get(ENV, string(name), default)
end

"""
    set_env!(name::Symbol, val::Union{AbstractString, Nothing})

Set the value for environment variable `name` to `val`.

If `val` is `nothing`, then `name` is deleted from `Base.ENV`.

!!! note
    An error is thrown if `name` is not an environment variable used by `QiskitRuntime.jl`.
"""
function set_env!(name::Symbol, val::Union{AbstractString,Nothing})
    name in _ENV_VARS || throw(
        ArgumentError(lazy"Environment variable `$name` is not used by QiskitRuntime.jl"),
    )
    sname = string(name)
    if isnothing(val)
        haskey(ENV, sname) && delete!(ENV, sname)
    else
        ENV[sname] = val
    end
end

"""
    env_vars()

Return a `Dict` of all environment variables used by QiskitRuntime.jl and their values.

If the environment variable is not set then its value is `nothing` in the returned
`Dict`. Here "not set" means it is not a key in `Base.ENV`.

# Variables:
$_var_docs
"""
function env_vars()
    return Dict{Symbol,Union{String,Nothing}}(var => get_env(var) for var in _ENV_VARS)
end

end # module EnvVars
