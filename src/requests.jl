module Requests

import HTTP
import URIs
import ..Accounts: Account, read_account_file
import ..JSON

const _DEFAULT_RUNTIME_BASE_URL = URIs.URI("https://api.quantum-computing.ibm.com/runtime")

struct Service
    acct::Account
    base_url::URIs.URI
end

Service(acct) = Service(acct, _DEFAULT_RUNTIME_BASE_URL)
Service() = Service(read_account_file())

function headers(service::Service)
    token = service.acct.token
    Dict("Accept" => "application/json",
         "Authorization" => "Bearer $token")
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

function job(id::String)
    GET_request("jobs/$id")
end

function results(id::String)
    GET_request("jobs/$id/results")
end

function transpiled_circuits(id::String)
    GET_request("jobs/$id/transpiled_circuits")
end

###
### Users
###

# Julia has `Base.instances`. So we call this `user_instances`.
function user_instances()
    GET_request("instances")
end

function user()
    GET_request("users/me")
end


end # module Requests
