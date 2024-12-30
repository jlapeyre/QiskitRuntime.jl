"""
    module EnvVars

`EnvVars` is has no user-facing API

Provides `get_env` to return the value of an envirnoment variable.
"""
module EnvVars

export get_env

module _EnvVars

# The Python client uses the env var QISKIT_IBM_RUNTIME_API_URL for the authentication
# url, which is usually "https://auth.quantum-computing.ibm.com/api" I find this name
# confusing. So, I call it QISKIT_IBM_AUTH_URL". In any case, we don't use it.

const _ENV_VARS = [
    :QISKIT_CONFIG_DIR,
    :QISKIT_ACCOUNT_NAME,
    :QISKIT_IBM_CHANNEL,
    :QISKIT_IBM_INSTANCE,
    :QISKIT_IBM_TOKEN,
    :QISKIT_IBM_AUTH_URL,
    :QISKIT_RUNTIME_CACHE_DIR
]

# Unused at the moment
# :QISKIT_IBM_RUNTIME_LOG_LEVEL

end # module _EnvVars

import ._EnvVars: _ENV_VARS

"""
    get_env(name::Symbol, default=nothing)

Return the value for environment variable `name` or `default` if `name` is not present.

!!! note
    An `@assert`ion is made that `name` is an environment variable used by `QiskitRuntime.jl`.
"""
function get_env(name::Symbol, default=nothing)
    @assert name in _ENV_VARS
    get(ENV, string(name), default)
end

end # module EnvVars
