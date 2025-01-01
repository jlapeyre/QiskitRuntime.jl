"""
    module Requests

This module manages requests and responses to the REST API.

Several functions in the `Requests` layer make requests to specific endpoints. For some endpoints,
responses are cached as JSON text files.
A request to an endpoint with a cache works as follows:
* A function requesting a specific endpoint is called. For example [`job`](@ref).
  In this case, a job id is passed as a parameter.
* The cached response is looked up by job id. If a cached response is found, it is read, converted to a `JSON3.Object`, and returned.
* If the cached reponse is not found, a request is
  made to the endpoint. The response string is written to the cache and is also converted to a `JSON3.Object`
  and returned.

If you pass the keyword parameter `refresh=true`, the above scenario is modified.
In this case, the request is sent to the endpoint unconditionally. The cache file, if present,
is overwritten with the new reponse.

Some endpoints have no associated cache. A function in the `Requests` layer accessing this endpoint
simply makes the requests, parses the result, and returns a `JSON3.Object`.

The following two arguments are common to many functions in the API of the `Requests` layer.

# Arguments
-- `qaccount::Union{QuantumAccount, Nothing}=nothing`: The `QuantumAccount` to use. If nothing
    a `QuantumAccount` is created.

# Keyword arguments
-- `refresh::Bool=false`:  If `false`, then a cached response will be preferred. If `true`,
    the a request will be made, and the cache will be updated with a fresh response.

# Options to requests

Many endpoints in the REST API support options, such as filters. Most of these are not yet implemented, although
it is not difficult to do so.

!!! warning
    No measures are taken to protect the cache from corruption in case of errors.
"""
module Requests

module _Requests

import HTTP
import URIs
import ...Accounts: QuantumAccount
import ...Accounts
import ...JSON
import ...Circuits: QASMString
import ...Utils
import ...EnvVars: get_env

# Hardcoding this allows is to eliminate a struct that carries this with QuantumAccount
const _BASE_REST_URL = URIs.URI("https://api.quantum-computing.ibm.com/runtime")

# Return the entire url for `endpoint`
function _endpoint_url(endpoint::AbstractString)
    joinpath(_BASE_REST_URL, endpoint)
end

# Construct a fully qualified cache filename for a response and write the file
# - endpoint: The (possibly modified) endpoint name; used as directory name.
# - response: A JSON3.Object representing the reponse.
# - id: A string identifying the request. For example a job id.
# - cache_dir: The parent dir to the subdir `endpoint`.
#
# `endpoint` is not really necessarily the endpoint, but something similar.
# Because endpoints do not map perfectly to cache directory tree.
function write_response_cache(endpoint, response, id, cache_dir=nothing)
    isnothing(cache_dir) && (cache_dir = endpoint_cache_directory(endpoint))

    if ! isdir(cache_dir)
        mkpath(cache_dir)
    end
    filename = cache_filename(endpoint, id)
    JSON.write_to_file(filename, response)
end

"""
    cache_directory()

Return the top-level directory for caching runtime REST requests.

If `QISKIT_RUNTIME_CACHE_DIR` is set, use it.
Otherwise, use the hard-coded value `"~/.qiskit/runtime_cache"`.
"""
function cache_directory()
    let env_cache_dir = get_env(:QISKIT_RUNTIME_CACHE_DIR)
        isnothing(env_cache_dir) || return env_cache_dir
    end
    return Accounts._Accounts._get_path_in_config("runtime_cache")
end

"""
    endpoint_cache_directory(endpoint)

Return the fully-qualified path to the cache directory for `endpoint`.
"""
function endpoint_cache_directory(endpoint)
    joinpath(cache_directory(), endpoint)
end

# Return the fully qualified filename of a cached response.
# The name is "$id.json".
function cache_filename(endpoint, id)
    joinpath(endpoint_cache_directory(endpoint), id * ".json")
end

# Get the id (say job id) from a filename of the form "$id.json".
function id_from_json_filename(filename)
    (id, _ext) = split(filename, '.')
    id
end

# read_response_cache(endpoint, id)::JSON3.Object
# Read and return the cache file associated with `(endpoint, id)` as a JSON object.
function read_response_cache(endpoint, id)
    cache_file = cache_filename(endpoint, id)
    isfile(cache_file) || return nothing
    JSON.read_from_file(cache_file)
end

# headers for GET
function headers_get(qaccount::QuantumAccount)
    token = string(qaccount.token)
    Dict("Accept" => "application/json",
         "Authorization" => "Bearer $token")
end

# headers for POST
# We might be able to use the same headers. Need to experiment
function headers_post(qaccount::QuantumAccount)
    token = string(qaccount.token)
    Dict("Accept" => "application/json",
         "Content-Type" => "application/json",
         "Authorization" => "Bearer $token")
end

function _get_instance(qaccount::QuantumAccount)
    qaccount.instance
end

# This a small efficiency hack.
# Return (qaccount, instance).
# * If `qaccount` is not nothing, it is returned in the return tuple.
# * If `instance` is not nothing, it is returned in the return tuple.
# * If `qaccount` is nothing, it is created from `QuantumAccount()`
# * If `instance` is nothing it is retrieved from `qaccount`.
#
# We sometimes want to use the default provider (instance),  when `qaccount` was not provided.
# We could create `qaccount` just to extract `instance`.
# But `qaccount` will be created in a downstream call to `GET_request`.
# Here we avoid creating it twice.
# This involves reading the user's config file (or ENV variable, etc.)
# It takes about 0.5 ms on my machine.
function _qaccount_instance(qaccount::Union{Nothing, QuantumAccount}, instance)
    qaccount = isnothing(qaccount) ? QuantumAccount() : qaccount
    instance = isnothing(instance) ? _get_instance(qaccount) : instance
    (qaccount, instance)
end

# Filter queries:
# 1. values `nothing` are removed
# 2. `Instance` converted to `String`
# 3. All others passed unchanged.
# Eh, this is a bit clumsy. Things were ok, except we need
# to convert `Instance` to a `String`. But kws are immuatble
# kws = filter(q -> !isnothing(q.second), kws) no longer works
# Note that the provider is also converted to a string
# `query` is `Dict{Symbol, Any}`. If we knew what the allowed
# types are, we could constrain it more.
# We need: String, Integer, Vector of those. And probably other things.
function _filter_request_queries(kws)
    query = Dict{Symbol, Any}()
    for (k, v) in kws
        v == nothing && continue
        isa(v, Integer) && (v = string(v))
        query[k] = (k == :provider ? string(v) : v)
    end
    return query
end

# Send a GET request to `endpoint` using `qaccount`.
# If `qaccount` is `nothing` or is not passed, then create one with `QuantumAccount()`.
function GET_request(endpoint::AbstractString, qaccount::QuantumAccount=QuantumAccount(); kws...)
    url = _endpoint_url(endpoint)
    query = _filter_request_queries(kws)
    response = HTTP.get(url, headers_get(qaccount); query=query, status_exception=false)
    response.status == 204 && return nothing  # 204 means ok, but nothing to return
    response.status != 200 && throw(ErrorException(lazy"Code $(response.status)"))
    JSON.read(response.body)
end
GET_request(endpoint::AbstractString, ::Nothing; kws...) = GET_request(endpoint; kws...)

# FIXME: check status for errors
function POST_request(endpoint::AbstractString, body, qaccount::QuantumAccount=QuantumAccount())
    url = _endpoint_url(endpoint)
    headers = headers_post(qaccount)
    response = HTTP.post(url; body, headers, status_exception=false)
    response.status == 200 || throw(ErrorException(lazy"Code $(response.status)"))
    JSON.read(response.body)
end
POST_request(endpoint::AbstractString, body, ::Nothing) = POST_request(endpoint, body)

###
### Jobs
###

function _get_job(job_id, qaccount=nothing)
    GET_request("jobs/$job_id", qaccount)
end

function _get_results(job_id, qaccount=nothing)
    GET_request("jobs/$job_id/results", qaccount)
end

# refresh == true means fetch data; don't use cache
# `get_func` is a function that calls `GET_request
function _cache_or_query(id, endpoint::AbstractString,
                         get_func,
                         qaccount=nothing; refresh=false, kws=nothing)
    if !refresh
        json = read_response_cache(endpoint, id)
        isnothing(json) || return json
    end
    if isnothing(kws)
        response = get_func(id, qaccount)
    else
        response = get_func(id, qaccount; kws...)
    end
    if !isnothing(response)
        write_response_cache(endpoint, response, id)
    end
    response
end

# Not authorized to perform this action
function admin_metrics(job_id::AbstractString, qaccount=nothing)
    GET_request("admin/jobs/$job_id/metrics", qaccount)
end

# Not authorized for this
function hub_workloads(qaccount=nothing; instance=nothing)
    if isnothing(instance)
        qaccount = QuantumAccount()
        instance = _get_instance(qaccount)
    end
    GET_request("workloads/admin", qaccount; instance)
end

###
### Backends
###

# Not finished
# function _get_backends(qaccount=nothing; provider=nothing)
#     GET_request("backends", qaccount; provider)
# end

## FIXME: remove this
function run_job_test()
    qaccount = QuantumAccount()
    endpoint = "jobs"
    url = joinpath(_BASE_REST_URL, endpoint)
    hub = qaccount.instance.hub
    group = qaccount.instance.group
    project = qaccount.instance.project
#    backend_name = "ibm_nazca"
    backend_name = "ibm_kyiv"
    quantum_program =
        """
OPENQASM 3.0;
include "stdgates.inc";
bit[2] meas;
rz(pi/2) \$0;
sx \$0;
rz(pi/2) \$0;
meas[0] = measure \$0;
meas[1] = measure \$1;
"""

    params = Dict(
    "pubs" => [[
        quantum_program, [], 128]],
# Failure:  "supports_qiskit" is unknown parameter
#    "supports_qiskit" => false,
    "version" => 2,
    )
    # headers = Dict(
    #     "Accept" => "application/json",
    #     "Content-Type" => "application/json",
    #     "Authorization" => "Bearer $(string(qaccount.token))"
    # )
    headers = headers_post(qaccount)
    body_dict = Dict(
        "program_id" => "sampler",
        "hub" => hub,
        "group" => group,
        "project" => project,
        "backend" => backend_name,
        "params" => params,
    )
    body = JSON.write(body_dict)
    POST_request("jobs", body)
#    return (headers, body)
#    HTTP.post(url; body, headers)
end

# We do this because small text formatting errors produce errors in the html.
function _endpoint(endpoint, url)
    """
    - [endpoint: `"$endpoint"`](https://docs.quantum.ibm.com/api/runtime/tags/$url)
    """
end

end # module _Requests

import ...Circuits: QASMString
import ...Instances
import ...PUBs
import ...Accounts
import ...JSON

import ._Requests: _cache_or_query, _get_job,
    endpoint_cache_directory, id_from_json_filename, GET_request, POST_request,
    _get_results, _qaccount_instance, _endpoint,
    _BASE_REST_URL

export job, jobs, job_ids, user_jobs, results, run_job,
    user_instances, user, workloads,
    backends, backend_status, backend_configuration, backend_defaults

# I don't know how to control Documenter, or the REPL doc systems, as well as I would like
# So the doc strings are here. Users, internal as well, should access these functions from the outer,
# API module. So, when sensible, we actually define the API function out here.
"""
    job(job_id, qaccount=nothing; refresh=false)::JSON3.Object

Retrieve job info for `job_id`

$(_endpoint("job/{job_id}", "jobs#tags__jobs__operations__GetJobByIdController_getJobById"))
"""
function job(job_id, qaccount=nothing; refresh=false)
    _cache_or_query(job_id, "job", _get_job, qaccount; refresh)
end

# TODO: Filters. filters everywhere
"""
    job_ids(qaccount=nothing; kws...)::Vector{String}

Return all job ids.

The function [`jobs`](@ref) is called to retrieve the job info
and the ids are extracted and returned.
"""
function job_ids(qaccount=nothing; kws...)
    response = jobs(qaccount; kws...)
    (j.id for j in response.jobs)
end

"""
    user_jobs(qaccount=nothing)::JSON3.Object

Mysterious alternative to `jobs` that returns slightly different results.

$(_endpoint("facade/v1/jobs", "jobs#tags__jobs__operations__listUserJobs"))
"""
function user_jobs(qaccount=nothing)
    GET_request("facade/v1/jobs", qaccount)
end

# TODO: collect and pass filter kwargs
"""
    jobs(qaccount=nothing; tags=nothing)

Return job info on all jobs.

$(_endpoint("jobs", "jobs#tags__jobs__operations__list_jobs"))
"""
function jobs(qaccount=nothing; tags=nothing)
    GET_request("jobs", qaccount; tags)
end

"""
    cached_job_ids()::Generator{Vector{String}}

Return an iterator over all the job ids associated with cached job info.

These are the ids of jobs that were fetched via [`job`](@ref) or [`jobs`](@ref).
"""
function cached_job_ids()
    endpoint = "job"
    cache_dir = endpoint_cache_directory(endpoint)
    filenames = if !isdir(cache_dir)
        String[]
    else
        readdir(cache_dir; sort=false)
    end
    # SubStrings are returned. We convert them to String
    (String(id_from_json_filename(fname)) for fname in filenames)
end

"""
    results(job_id, qaccount=nothing; refresh=false)::JSON3.Object

Return the job results for `job_id`.

$(_endpoint("jobs/{job_id}/results", "jobs#tags__jobs__operations__FindJobResultsController_findJobResult"))

The other kind of data on a job, which we call "job info", is retrieved with [`job`](@ref),
or [`jobs`](@ref)
"""
function results(job_id, qaccount=nothing; refresh=false)
    _cache_or_query(job_id, "results", _get_results, qaccount; refresh)
end

"""
    metrics(job_id, qaccount=nothing)::JSON3.Object

Return metrics for `job_id`.

$(_endpoint("jobs/{job_id}/metrics", "jobs#tags__jobs__operations__get_job_metrics_jid"))
"""
function metrics(job_id, qaccount=nothing)
    GET_request("jobs/$job_id/metrics", qaccount)
end

"""
    transpiled_circuits(job_id, qaccount=nothing)::JSON3.Object

Return transpiled circuits for `job_id`.

$(_endpoint("jobs/{job_id}/transpiled_circuits", "jobs#tags__jobs__operations__get_transpiled_circuits_jid"))
"""
function transpiled_circuits(job_id::AbstractString, qaccount=nothing)
    GET_request("jobs/$job_id/transpiled_circuits", qaccount)
end

# TODO: We were considering caching this. But the response is pretty fast after the
# first one.
# Provider is the same thing as an instance here, I think
"""
    backends(qaccount=nothing; provider=nothing)::JSON3.Object

Return list of backends available to the configured user and instance.

If `provider` is `:all`, then return all backends, even those not available
 to the instance.

I'm pretty sure that "provider" and "instance" mean the same thing.

$(_endpoint("backends", "systems#tags__systems__operations__list_backends"))
"""
function backends(qaccount=nothing; provider=nothing)
    # In this package, we use `nothing` to mean it should be filled in later.
    # But the API uses `nothing` to mean "everything".
    if provider == :all
        provider = nothing
    else
        # If either is `nothing`, then fill it in.
        (qaccount, provider) = _qaccount_instance(qaccount, provider)
    end
# Not yet finished with caching here
#    cache_name = isnothing(provider) ? "all" : Instances.filename_encoded(provider)
#    _cache_or_query(cache_name, "backends", _get_backends, qaccount; refresh)
    GET_request("backends", qaccount; provider)
end

###
### Users
###

# Julia has `Base.instances`. So we call this `user_instances`.
"""
    user_instances(qaccount=nothing)::JSON3.Object

Return a list of instances available to the user.

$(_endpoint("instances", "instances#tags__instances__operations__FindInstancesController_findInstances"))
"""
function user_instances(qaccount=nothing)
    GET_request("instances", qaccount)
end

"""
    user(qaccount=nothing)::JSON3.Object

Get the authenticated user.

The reponse includes the user's email and the same information returned by [`user_instances`](@ref).

$(_endpoint("users/me", "users#tags__users__operations__GetUserMeController_getMyUser"))
"""
function user(qaccount=nothing)
    GET_request("users/me", qaccount)
end

"""
    workloads(qaccount=nothing; instance=nothing)::JSON3.Object

List user workloads

* Compared to [`jobs`](@ref), `workloads` returns a smaller dictionary with less information for each job.
* The default filters are different. Not just the limit on the number of returned jobs.

$(_endpoint("workloads/me", "workloads#tags__workloads__operations__FindWorkloadsMeController_findUserWorkloads"))
"""
function workloads(qaccount=nothing; instance=nothing,
                   limit::Integer=nothing, backend::AbstractString=nothing)
    (qaccount, instance) = _qaccount_instance(qaccount, instance)
    GET_request("workloads/me", qaccount; instance, limit, backend)
end

function backend_status(backend_name::AbstractString, qaccount=nothing)
    GET_request("backends/$backend_name/status", qaccount)
end

function backend_configuration(backend_name::AbstractString, qaccount=nothing)
    GET_request("backends/$backend_name/configuration", qaccount)
end

function backend_defaults(backend_name::AbstractString, qaccount=nothing)
    GET_request("backends/$backend_name/defaults", qaccount)
end

function backend_properties(backend_name::AbstractString, qaccount=nothing; updated_before=nothing)
    GET_request("backends/$backend_name/properties", qaccount; updated_before)
end

function run_job(backend_name::AbstractString, pubs, qaccount=nothing)
    qaccount = isnothing(qaccount) ? Accounts.QuantumAccount() : qaccount
    body = Dict{Symbol, Any}()
    (hub, group, project) = Instances.as_tuple(qaccount.instance)
    body[:program_id] = PUBs.api_primitive_type(pubs)
    body[:hub] = hub
    body[:group] = group
    body[:project] = project
    body[:backend] = backend_name
    params = Dict(
        :pubs => PUBs.api_data_structure(pubs),
#        "supports_qiskit" => PUBs.supports_qiskit(pubs), # Documented, but unrecognized
        :version => 2,
    )
    body[:params] = params
    body_json = JSON.write(body)
    POST_request("jobs", body_json, qaccount)
end

end # module Requests
