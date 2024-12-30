module Accounts

export QuantumAccount

import ..JSON
import ..Instances
import ..Utils
import ..Ids: Token

const _DEFAULT_QISKIT_USER_DIR =  joinpath(homedir(), ".qiskit")
const _DEFAULT_ACCOUNT_CONFIG_JSON_FILE = joinpath(_DEFAULT_QISKIT_USER_DIR, "qiskit-ibm.json")
const _DEFAULT_ACCOUNT_NAME = "default"
const _DEFAULT_ACCOUNT_NAME_IBM_QUANTUM = "default-ibm-quantum"
const _DEFAULT_ACCOUNT_NAME_IBM_CLOUD = "default-ibm-cloud"
const _DEFAULT_CHANNEL_TYPE = "ibm_cloud"
const _IBM_QUANTUM_CHANNEL = "ibm_quantum"
const _CHANNEL_TYPES = [_DEFAULT_CHANNEL_TYPE, "ibm_quantum"]

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

# TODO: Allow this to be set by env var? Is there one for the Python impl.?
function _read_account_config_file_json()
    acct_file = _DEFAULT_ACCOUNT_CONFIG_JSON_FILE
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

"""
    QuantumAccount()

Return a structure that contains information necessary for making
requests to the REST API. This includes an access token and an instance.

This reads `~/.qiskit/qiskit-ibm.json`. Environment variables take precedent.
The latter has been implemented but is not tested.
"""
function QuantumAccount()
    from_env = _get_account_from_env_variables()
    ! isnothing(from_env) && return from_env
    quantum_account = _read_account_from_config_file()
    if isnothing(quantum_account)
        throw(ErrorException(lazy"User configuration file \"$_DEFAULT_ACCOUNT_CONFIG_JSON_FILE\" not found."))
    end
    return quantum_account
end

function _read_account_from_config_file()
    accts_json = _read_account_config_file_json()
    isnothing(accts_json) && return nothing
    # The only account is default-ibm-quantum.
    # This is dict-like, with a single keydefault-ibm-quantum.
    # We take just the value
    account = accts_json[_DEFAULT_ACCOUNT_NAME_IBM_QUANTUM]
    return QuantumAccount(account.channel, account.instance, account.url, Token(account.token);
                   private_endpoint=account.private_endpoint)
end

function _get_account_from_env_variables() # ::Union{Nothing, QuantumAccount}
    channel = get(ENV, "QISKIT_IBM_CHANNEL", _IBM_QUANTUM_CHANNEL)
    instance = get(ENV, "QISKIT_IBM_INSTANCE", false) || return nothing
    token = get(ENV, "QISKIT_IBM_TOKEN", false) || return nothing
    url = get(ENV, "QISKIT_IBM_URL", false) || return nothing
    return QuantumAccount(channel, instance, url, token)
end

end # module Accounts
