module Accounts

import ..Ids: Token
import ..Instances

export QuantumAccount, list_accounts, all_accounts

# Note that Python version essentially hardcodes channel == "ibm_quantum".
# We leave this variable at present.
# I have know idea what type `proxies` might be. So the type is parameterized
# at the moment.
"""
`struct` that represents an account with channel 'ibm_quantum.'"
"""
struct QuantumAccount{PT}
    channel::String
    url::String
    token::Token
    instance::Instances.Instance
    private_endpoint::Bool
    verify::Bool
    proxies::PT
end

module _Accounts

import ...JSON
import ...Instances
import ...Utils
import ...Ids: Token
import ...EnvVars: get_env

import ..QuantumAccount

# We copy the names from the Python client, for the  most part.
# But we add some, omit some, and modify some (!)
const _DEFAULT_QISKIT_USER_DIR =  joinpath(homedir(), ".qiskit")
const _DEFAULT_CONFIG_FILENAME = "qiskit-ibm.json"
const _DEFAULT_ACCOUNT_CONFIG_JSON_FILE = joinpath(_DEFAULT_QISKIT_USER_DIR, _DEFAULT_CONFIG_FILENAME)
const _DEFAULT_ACCOUNT_NAME = "default"
const _DEFAULT_ACCOUNT_NAME_IBM_QUANTUM = "default-ibm-quantum"
const _DEFAULT_ACCOUNT_NAME_IBM_CLOUD = "default-ibm-cloud"
const _DEFAULT_CHANNEL_TYPE = "ibm_cloud"
const _IBM_QUANTUM_CHANNEL = "ibm_quantum"
const _CHANNEL_TYPES = [_DEFAULT_CHANNEL_TYPE, "ibm_quantum"]
const _DEFAULT_QISKIT_IBM_AUTH_URL = "https://auth.quantum-computing.ibm.com/api"


Base.show(io::IO, ::MIME"text/plain", account::QuantumAccount) =
    Utils._show(io, account; newlines=true)

QuantumAccount(channel, instance::AbstractString, url, token; kws...) =
    QuantumAccount(channel, Instances.Instance(instance), url, token; kws...)

function QuantumAccount(channel, instance, url, token;
                 private_endpoint::Bool=false, verify::Bool=false,
                 proxies=nothing)
    return QuantumAccount{typeof(proxies)}(channel, url, token, instance, private_endpoint,
                             verify, proxies)
end

function _get_config_path_json()
    _get_path_in_config(_DEFAULT_CONFIG_FILENAME)
    # config_dir = get_env(:QISKIT_CONFIG_DIR, _DEFAULT_QISKIT_USER_DIR)
    # joinpath(config_dir, _DEFAULT_CONFIG_FILENAME)
end

function _get_path_in_config(components...)
    config_dir = get_env(:QISKIT_CONFIG_DIR, _DEFAULT_QISKIT_USER_DIR)
    joinpath(config_dir, components...)
end

# TODO: Allow this to be set by env var? Is there one for the Python impl.?
function _read_account_config_file_json()
    acct_file = _get_config_path_json()
    isfile(acct_file) || return nothing
    accts_string = String(read(acct_file))
    accts_json = try
        JSON.read(accts_string)
    catch e
        throw(ErrorException(LazyString("Parse error while reading ", _DEFAULT_ACCOUNT_CONFIG_JSON_FILE,
                                        "\n", e.msg)))
    end
    return accts_json
end

function _get_account_name(name)
    !isnothing(name) && return name
    name = get_env(:QISKIT_ACCOUNT_NAME)
    isnothing(name) && (name = _DEFAULT_ACCOUNT_NAME_IBM_QUANTUM)
    return name
end

function _read_account_from_config_file(name=nothing)
    accts_json = _read_account_config_file_json()
    isnothing(accts_json) && return nothing
    name = _get_account_name(name)
    account = get(accts_json, name, nothing)
    isnothing(account) && throw(ErrorException(lazy"Account \"$name\" not found"))
    return QuantumAccount(account.channel, account.instance, account.url, Token(account.token);
                   private_endpoint=account.private_endpoint)
end

# instance and token must both be present
function _get_account_from_env_variables() # ::Union{Nothing, QuantumAccount}
    instance = get_env(:QISKIT_IBM_INSTANCE)
    isnothing(instance) && return nothing
    token = get_env(:QISKIT_IBM_TOKEN)
    isnothing(token) && return nothing
    channel = get_env(:QISKIT_IBM_CHANNEL, _IBM_QUANTUM_CHANNEL)
    url = get_env(:QISKIT_IBM_AUTH_URL, _DEFAULT_QISKIT_IBM_AUTH_URL)
    return QuantumAccount(channel, instance, url, token)
end

end # module _Accounts

import ._Accounts: _read_account_config_file_json, _get_account_from_env_variables,
    _read_account_from_config_file

"""
    QuantumAccount(name=nothing)::QuantumAccount

Return a `struct` with information for making requests to the REST API.

The account argument may be omitted making requests to the server, for
example when calling [`QiskitRuntime.Jobs.job`](@ref).
In these cases, the account will be constructed with the form `QuantumAccount()`.

The following are tried in order, and the first to succeed is returned.

- If `name` is not `nothing` then the account with this name is read from
  the configuration file.
- If the account information is specified in enviroment variables `QISKIT_IBM_INSTANCE`
  and `QISKIT_IBM_TOKEN`, then these are used to construct the `QuantumAccount`. The
  configuration file is not read. (And need not exist.)
- If the environment variable `QISKIT_ACCOUNT_NAME` is set, then this account is
  read from the configuration file.
- The default account `"default-ibm-quantum"` is read from the configuration file.

The configuration file is typically `~/.qiskit/qiskit-ibm.json`.

In case the account is constructed from environment variables, the variables
`QISKIT_IBM_CHANNEL`, `QISKIT_IBM_AUTH_URL` may be set as well to override defaults.

# Examples
(The tokens and instances below are invented, and are not related to any real account.)


```jldoctest
julia> accts = list_accounts() # List the accounts in the config file.
2-element Vector{String}:
 "default-ibm-quantum"
 "qiskit-other"

julia> QuantumAccount(accts[1]) # Get the first account
QuantumAccount{Nothing}(
  channel = "ibm_quantum",
  url = "https://auth.quantum-computing.ibm.com/api",
  token = Token("de638e834a4925507bf4181220eff41d116a7baabd9a339cc2e8a3be570f6196cec2f3d77aabc773e1ae1e62ba67b3a5a7d0bbe9de015b89ec65692803c547e9"),
  instance = Instance(hub-one/group-one/project-one),
  private_endpoint = false,
  verify = false,
  proxies = nothing
)

julia> QuantumAccount(accts[2]) # Get the second account
QuantumAccount{Nothing}(
  channel = "ibm_quantum",
  url = "https://auth.quantum-computing.ibm.com/api",
  token = Token("726f2418e17c5845aad93c8e8a3cccaa642b9473132aaec47da93cb2f619fe3d156fb4962ebf8865bed278970bbddc3db0caf58c429b2fffd8c8c0359d80b43a"),
  instance = Instance(hub-two/group-two/project-two),
  private_endpoint = false,
  verify = false,
  proxies = nothing
)

julia> QuantumAccount() # Get the default account, "default-ibm-quantum"
QuantumAccount{Nothing}(
  channel = "ibm_quantum",
  url = "https://auth.quantum-computing.ibm.com/api",
  token = Token("de638e834a4925507bf4181220eff41d116a7baabd9a339cc2e8a3be570f6196cec2f3d77aabc773e1ae1e62ba67b3a5a7d0bbe9de015b89ec65692803c547e9"),
  instance = Instance(hub-one/group-one/project-one),
  private_endpoint = false,
  verify = false,
  proxies = nothing
)
```

We change the default account name with an environment variable. To reduce verbosity,
we just show the `instance.`
```jldoctest
julia> ENV["QISKIT_ACCOUNT_NAME"] = "qiskit-other";

julia> QuantumAccount().instance
Instance(hub-two/group-two/project-two)
```

Here we set the account with environment variables, ignoring the configuration file.
```jldoctest
julia> ENV["QISKIT_IBM_TOKEN"] = "f99b2a42c50ef0314434b0a5e60d8eab6b08112dd4259446e7172a34d61c48ea0a1b349e367dd62d7088fc0d0e97948f0d09fe46c4e34dd9550cdee97256e9a8";

julia> ENV["QISKIT_IBM_INSTANCE"] = "a/b/c";

julia> QuantumAccount()
QuantumAccount{Nothing}(
  channel = "ibm_quantum",
  url = "https://auth.quantum-computing.ibm.com/api",
  token = Token("f99b2a42c50ef0314434b0a5e60d8eab6b08112dd4259446e7172a34d61c48ea0a1b349e367dd62d7088fc0d0e97948f0d09fe46c4e34dd9550cdee97256e9a8"),
  instance = Instance(a/b/c),
  private_endpoint = false,
  verify = false,
  proxies = nothing
)

julia> foreach(k -> delete!(ENV, k), ("QISKIT_IBM_INSTANCE", "QISKIT_IBM_TOKEN", "QISKIT_ACCOUNT_NAME"));

```
"""
function QuantumAccount(name=nothing)
    # if list
    #     accts_json = _read_account_config_file_json()
    #     isnothing(accts_json) && return nothing
    #     return string.(keys(accts_json))
    # end
    if isnothing(name) # Only prefer env variables if name is nothing
        from_env = _get_account_from_env_variables()
        !isnothing(from_env) && return from_env
    end
    quantum_account = _read_account_from_config_file(name)
    if isnothing(quantum_account)
        throw(ErrorException(lazy"User configuration file \"$name\" not found."))
    end
    return quantum_account
end

# - If `list` is `true` then a list of names of accounts is read from the configuration
#   file and returned.
function list_accounts()
    accts_json = _read_account_config_file_json()
    isnothing(accts_json) && return nothing
    return string.(keys(accts_json))
end

function all_accounts()
    names = list_accounts()
    isnothing(names) && return nothing
    [_read_account_from_config_file(name) for name in names]
end

end # module Accounts
