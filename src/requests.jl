module Requests

import HTTP
import URIs
import ..Accounts: QuantumAccount
import ..Accounts
import ..JSON

const _DEFAULT_RUNTIME_BASE_URL = URIs.URI("https://api.quantum-computing.ibm.com/runtime")

struct Service
    acct::QuantumAccount
    base_url::URIs.URI
end

Service(acct) = Service(acct, _DEFAULT_RUNTIME_BASE_URL)
Service() = Service(Accounts.get_account())

function headers(service::Service)
    token = service.acct.token
    Dict("Accept" => "application/json",
         "Authorization" => "Bearer $token")
end

function _get_instance(service::Service)
    service.acct.instance
end

# Return (service, instance). If input `service` is `nothing`
# get default service
# This a small efficiency hack.
# We sometimes want to use the default provider (instance),
# when `service` was not provided.
# We could create `service` just to extract `instance`.
# But `service` will be created in a downstream call to `GET_request`.
# Here we avoid creating it twice.
# This involves reading the user's config file (or ENV variable, etc.)
# It takes about 0.5 ms on my machine.
function _service_instance(service::Union{Nothing, Service})
    service = isnothing(service) ? Service() : service
    instance = _get_instance(service)
    (service, instance)
end

function GET_request(endpoint::String, service::Service; kws...)
    url = joinpath(service.base_url, endpoint)
    kws = filter(q -> !isnothing(q.second), kws)
    JSON.read(HTTP.get(url, headers(service); query=kws).body)
end
GET_request(endpoint::String, ::Nothing; kws...) = GET_request(endpoint, Service(); kws...)
GET_request(endpoint::String; kws...) = GET_request(endpoint, Service(); kws...)

###
### Jobs
###

function jobs(service=nothing; tags=nothing)
    GET_request("jobs", service; tags)
end

function job(job_id::String, service=nothing)
    GET_request("jobs/$job_id", service)
end

function results(job_id::String, service=nothing)
    GET_request("jobs/$job_id/results", service)
end

function metrics(job_id::String, service=nothing)
    GET_request("jobs/$job_id/metrics", service)
end

function transpiled_circuits(job_id::String, service=nothing)
    GET_request("jobs/$job_id/transpiled_circuits", service)
end

###
### Users
###

# Julia has `Base.instances`. So we call this `user_instances`.
function user_instances(service=nothing)
    GET_request("instances", service)
end

function user(service=nothing)
    GET_request("users/me", service)
end

# This may not be working correctly
function hub_workloads(service=nothing; instance=nothing)
    if isnothing(instance)
        service = Service()
        instance = get_instance(service)
    end
    GET_request("workloads/admin", service; instance)
end

# Provider is the same thing as an instance here, I think
"""
    backends(service=nothing; provider=nothing)

Return list of backends. If `provider` is `:all`, then
return all backends.
"""
function backends(service=nothing; provider=nothing)
    if provider == :all
        provider = nothing
    else
        (service, provider) = _service_instance(service)
    end
    GET_request("backends", service; provider)
end

function backend_status(backend_name::AbstractString, service=nothing)
    GET_request("backends/$backend_name/status", service)
end

function backend_configuration(backend_name::AbstractString, service=nothing)
    GET_request("backends/$backend_name/configuration", service)
end

function backend_defaults(backend_name::AbstractString, service=nothing)
    GET_request("backends/$backend_name/defaults", service)
end

function backend_properties(backend_name::AbstractString, service=nothing; updated_before=nothing)
    GET_request("backends/$backend_name/properties", service; updated_before)
end

end # module Requests
