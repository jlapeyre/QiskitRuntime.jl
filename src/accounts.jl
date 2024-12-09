# eventually, we can store the three parts
# struct Instance
#     instance::String
# end

module Accounts

import ..JSON

const _DEFAULT_ACCOUNT_CONFIG_JSON_FILE = joinpath(homedir(), ".qiskit", "qiskit-ibm.json")
const _DEFAULT_ACCOUNT_NAME = "default"
const _DEFAULT_ACCOUNT_NAME_IBM_QUANTUM = "default-ibm-quantum"
const _DEFAULT_ACCOUNT_NAME_IBM_CLOUD = "default-ibm-cloud"
const _DEFAULT_CHANNEL_TYPE = "ibm_cloud"
const _IBM_QUANTUM_CHANNEL = "ibm_quantum"
const _CHANNEL_TYPES = [_DEFAULT_CHANNEL_TYPE, "ibm_quantum"]


# Note that Python version essentially hardcodes channel == "ibm_quantum"
# We leave this variable at present
"""
`struct` that represents an account with channel 'ibm_quantum.'"
"""
struct QuantumAccount{PT}
    channel::String
    url::String
    token::String
    instance::String
    private_endpoint::Bool
    verify::Bool
    proxies::PT
end

function Base.show(io::IO, ::MIME"text/plain", acct::QuantumAccount)
    println(io, "QuantumAccount(")
    println(io, " channel = ",acct.channel, ",")
    println(io, " token = ", acct.token, ",")
    println(io," instance = ", acct.instance, ",")
    println(io," private_endpoint = ", acct.private_endpoint, ",")
    println(io," verify = ", acct.verify, ",")
    println(io, " proxies = ",acct.proxies, "\n)")
end

function QuantumAccount(channel, instance, url, token;
                 private_endpoint::Bool=false, verify::Bool=false,
                 proxies=nothing)
    return QuantumAccount{typeof(proxies)}(channel, url, token, instance, private_endpoint,
                             verify, proxies)
end

function _read_account_config_file_json()
    acct_file = _DEFAULT_ACCOUNT_CONFIG_JSON_FILE
    isfile(acct_file) || return nothing
    accts_string = String(read(acct_file))
    accts_json = JSON.read(accts_string)
    return accts_json
end

function get_account()
    from_env = _get_account_from_env_variables()
    ! isnothing(from_env) && return from_env
    return _read_account_from_config_file()
end

function _read_account_from_config_file()
    accts_json = _read_account_config_file_json()
    # The only account is default-ibm-quantum.
    # This is dict-like, with a single keydefault-ibm-quantum.
    # We take just the value
    acct = accts_json[_DEFAULT_ACCOUNT_NAME_IBM_QUANTUM]
    return QuantumAccount(acct.channel, acct.instance, acct.url, acct.token;
                   private_endpoint=acct.private_endpoint)
end

function _get_account_from_env_variables() # ::Union{Nothing, QuantumAccount}
    channel = get(ENV, "QISKIT_IBM_CHANNEL", _IBM_QUANTUM_CHANNEL)
    instance = get(ENV, "QISKIT_IBM_INSTANCE", false) || return nothing
    token = get(ENV, "QISKIT_IBM_TOKEN", false) || return nothing
    url = get(ENV, "QISKIT_IBM_URL", false) || return nothing
    return QuantumAccount(channel, instance, url, token)
end

# QISKIT_IBM_TOKEN
# QISKIT_IBM_URL
# QISKIT_IBM_INSTANCE
# QISKIT_IBM_CHANNEL


end # module Accounts
