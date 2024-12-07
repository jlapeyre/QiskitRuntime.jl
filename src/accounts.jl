module Accounts

import ..JSON
import ..Instances
import ..Utils

const _DEFAULT_QISKIT_USER_DIR =  joinpath(homedir(), ".qiskit")
const _DEFAULT_ACCOUNT_CONFIG_JSON_FILE = joinpath(_DEFAULT_QISKIT_USER_DIR, "qiskit-ibm.json")
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

function _read_account_config_file_json()
    acct_file = _DEFAULT_ACCOUNT_CONFIG_JSON_FILE
    isfile(acct_file) || return nothing
    accts_string = String(read(acct_file))
    accts_json = JSON.read(accts_string)
    return accts_json
end

function QuantumAccount()
    from_env = _get_account_from_env_variables()
    ! isnothing(from_env) && return from_env
    return _read_account_from_config_file()
end

function _read_account_from_config_file()
    accts_json = _read_account_config_file_json()
    # The only account is default-ibm-quantum.
    # This is dict-like, with a single keydefault-ibm-quantum.
    # We take just the value
    account = accts_json[_DEFAULT_ACCOUNT_NAME_IBM_QUANTUM]
    return QuantumAccount(account.channel, account.instance, account.url, account.token;
                   private_endpoint=account.private_endpoint)
end

function _get_account_from_env_variables() # ::Union{Nothing, QuantumAccount}
    channel = get(ENV, "QISKIT_IBM_CHANNEL", _IBM_QUANTUM_CHANNEL)
    instance = get(ENV, "QISKIT_IBM_INSTANCE", false) || return nothing
    token = get(ENV, "QISKIT_IBM_TOKEN", false) || return nothing
    url = get(ENV, "QISKIT_IBM_URL", false) || return nothing
    return QuantumAccount(channel, instance, url, token)
end

# I have not seen a schema, so I am guessing based on a few inputs.
# Input strings are 24 hex "digits". This is 24 * 4 == 96 bits
# This can be stored in a UInt128.
struct UserId
    id::UInt128
end

const _USER_ID_LENGTH = 24

"""
    UserId(id_str::AbstractString)

Construct user id from the user id string in REST response.
"""
function UserId(id_str::AbstractString)
    length(id_str) == _USER_ID_LENGTH || error("Incorrect user id string length")
    UserId(parse(UInt128, "0x" * id_str))
end

function Base.print(io::IO, id::UserId)
    print(io, string(id.id; base=16, pad=_USER_ID_LENGTH))
end

function Base.show(io::IO, id::UserId)
    print(typeof(id), "(")
    # `string` will omit highest run of unset bits
    show(io, string(id.id; base=16))
    print(")")
end

end # module Accounts
