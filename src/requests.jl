const _DEFAULT_RUNTIME_BASE_URL = "https://api.quantum-computing.ibm.com/runtime"

struct Service
    acct::Account
    base_url::String
end

Service(acct) = Service(acct, _DEFAULT_RUNTIME_BASE_URL)
Service() = Service(read_account_file())

function headers(service::Service)
    token = service.acct.token
    Dict("Accept" => "application/json",
         "Authorization" => "Bearer $token")
end

function GET_request(endpoint::String, service::Service; kws...)
    url = service.base_url * "/" * endpoint
    # `nothing` means no kw was supplied
    kws = filter(q -> !isnothing(q.second), kws)
    response = HTTP.get(url, headers(service); query=kws)
    JSON.read(String(response.body))
end
GET_request(endpoint::String; kws...) = GET_request(endpoint, Service(); kws...)
GET_request(endpoint::String, ::Nothing; kws...) = GET_request(endpoint, Service(); kws...)

# TODO. validate kws
function jobs(service=nothing; tags=nothing)
    GET_request("jobs", service; tags)
end

function job(id::String)
    GET_request("jobs/$id")
end

function transpiled_circuits(id::String)
    GET_request("jobs/$id/transpiled_circuits")
end

#function job(
