module Jobs

using Dates: DateTime
import Base: Generator
import ..Instances: Instance
import ..Utils
import ..Decode
import ..PrimitiveResults
import ..Ids: JobId, UserId
import ..PUBs: PrimitiveType, EstimatorType, SamplerType

using SumTypes: @sum_type, @cases

"""
    JobStatus

Status of a job as reported by a query to the Runtime.
* `Queued`
* `Running`
* `Done`
* `Error`
* `Cancelled`
"""
@sum_type JobStatus begin
    Queued
    Running
    Done
    Error
    Cancelled
end

# INITIALIZING = "job is being initialized"
# QUEUED = "job is queued"
# VALIDATING = "job is being validated"
# RUNNING = "job is actively running"
# CANCELLED = "job has been cancelled"
# DONE = "job has successfully run"
# ERROR = "job incurred error"

"job is queued"
Queued

"job is actively running"
Running

"job has successfully run"
Done

"job has been cancelled"
Cancelled

"job incurred error"
Error

function Base.convert(::Type{JobStatus}, status::Union{Symbol,AbstractString})
    status = Symbol(status)
    status == :Queued && return Queued
    status == :Running && return Running
    status == :Completed && return Done
    status == :Failed && return Error
    status == :Cancelled && return Cancelled
end

# We need to do something better with options and pubs
struct JobParams{PT}
    support_qiskit::Union{Bool,Nothing}
    version::VersionNumber
    resilience_level::Union{Int,Nothing} # I think this is deprecated
    options::Union{Dict{Symbol,Any},Nothing}
    pubs::Vector{PT}
end

Base.show(io::IO, ::MIME"text/plain", p::JobParams) = Utils._show(io, p; newlines=true)

function JobParams(dict::Dict)
    pubs = _decode_pubs(dict[:pubs])
    return JobParams(
        get(dict, :support_qiskit, nothing),
        VersionNumber(dict[:version]),
        get(dict, :resilience_level, nothing),
        get(dict, :options, nothing),
        pubs,
    )
end

struct RuntimeJob{ResultT,ParamsT}
    job_id::JobId
    user_id::UserId
    session_id::Union{JobId,Nothing}
    primitive_id::PrimitiveType
    backend_name::String
    creation_date::DateTime
    end_date::Union{DateTime,Nothing}
    instance::Instance
    # state and status in Python runtime and REST API is quite complicated
    # We simply copy the REST API strings here. But this should be revisted.
    state
    status::JobStatus
    cost::Int
    private::Bool
    tags::Vector{String}
    params::ParamsT # Union{JobParams, Nothing}
    results::ResultT
end

Base.show(io::IO, ::MIME"text/plain", rtj::RuntimeJob) = Utils._show(io, rtj; newlines=true)

struct SamplerPub{CT,PT}
    circuit::CT
    parameters::Vector{PT}
    shots::Int
end

Base.show(io::IO, ::MIME"text/plain", rtj::SamplerPub) = Utils._show(io, rtj; newlines=true)

struct EstimatorPub{CT,PT,OT}
    circuit::CT
    observables::OT # ::Vector{OT}
    parameters::PT  # ::Vector{PT}
    precision::Float64
end

function Base.show(io::IO, ::MIME"text/plain", rtj::EstimatorPub)
    return Utils._show(io, rtj; newlines=true)
end

module _Jobs

using Dates: DateTime
import ...Utils
import ...Decode
import ...Instances: Instance
import ...Requests
import ...PauliOperators: PauliOperator
import ...Ids: JobId, UserId
import ...PUBs: PrimitiveType, SamplerType, EstimatorType

import ..EstimatorPub
import ..SamplerPub

import ..JobStatus
import ..Queued
import ..Running
import ..Done
import ..Error
import ..Cancelled
import ..JobParams
import ..RuntimeJob

function _decode_pub_sampler(pub)
    npub = [
        begin
            p = isa(p, Dict{Symbol,<:Any}) ? Decode.decode(p) : p
        end for p in pub
    ]
    isnothing(npub[3]) && (npub[3] = 0)
    return SamplerPub(npub...)
end

function _decode_pub_estimator(pub)
    decode = Decode.decode
    if length(pub) == 3
        (circuit, observables, parameters) = (pub...,)
        precision = nothing
    else
        (circuit, observables, parameters, precision) = (pub...,)
    end
    isnothing(precision) && (precision = 0.0)
    if isa(observables, Dict{Symbol,<:Any})
        observables = Dict(PauliOperator(String(k)) => v for (k, v) in observables)
    else
        observables = [PauliOperator(op) for op in observables]
        #        observables = decode(observables)
    end
    return EstimatorPub(decode(circuit), observables, decode(parameters), precision)
end

function _decode_pubs(primitive_id, pubs)
    if primitive_id == EstimatorType
        [_decode_pub_estimator(pub) for pub in pubs]
    elseif primitive_id == SamplerType
        [_decode_pub_sampler(pub) for pub in pubs]
    else
        throw(ErrorException("Unexpected error")) # should be an assertion or s.t.
    end
end

function _job_params(primitive_id::PrimitiveType, dict)
    pubs = _decode_pubs(primitive_id, dict[:pubs])
    return JobParams(
        get(dict, :support_qiskit, nothing),
        VersionNumber(dict[:version]),
        get(dict, :resilience_level, nothing),
        get(dict, :options, nothing),
        pubs,
    )
end

function _make_job(response, results=nothing; params::Bool=true)
    instance = Instance(response.hub, response.group, response.project)

    session_id = response.session_id
    if !isnothing(session_id)
        session_id = JobId(session_id)
    end
    tags = response.tags
    tags = isnothing(tags) ? String[] : collect(tags)

    primitive_id = convert(PrimitiveType, response.program.id)

    # `copy` converts JSON3 efficienct struction into plain old types.
    # This is a bit wasteful. We should pass JSON3 first
    job_params = params ? _job_params(primitive_id, copy(response.params)) : nothing

    return RuntimeJob(
        JobId(response.id), # job_id
        UserId(response.user_id), # user_id
        session_id, # session_id
        primitive_id,
        response.backend, # backend_name
        Decode.parse_response_datetime(response.created), # creation_date
        Decode.parse_response_maybe_datetime(response.ended), # end date
        instance, # instance
        Decode.decode(response.state),
        convert(JobStatus, response.status), # status
        response.cost, # cost
        response.private, # private
        tags, # tags
        job_params,
        results,
    )
end

end # module _Jobs

import ..Requests: Requests
import ..Accounts
import ..Instances: Instance
import ..PUBs: AbstractPUB

# Only here to allow non-fully-qualified symbols in docstring links.
# There should be a better way to do this.
import ..Backends
import ..PUBs

import ._Jobs: _make_job

export job,
    JobId,
    JobParams,
    RuntimeJob,
    InstancePlan,
    UserInfo,
    job_ids,
    cached_jobs,
    cached_job_ids,
    results,
    user_info,
    PrimitiveType,
    JobStatus,
    run_job

"""
    job(job_id::JobId, account=nothing;  params::Bool=true, results::Bool=true, refresh::Bool=false)::RuntimeJob

Return information on `job_id`.

- `params`: If `true` include job input parameters (including the [PUBs](https://docs.quantum.ibm.com/guides/primitive-input-output))).
            Otherwise the field `params` has value `nothing`.
- `results`: If `true` get the job results, if available. Otherwise, the field `results` has value `nothing`.
             Results are retrieved via the function [`results`](@ref).
- `refresh`: If `true` fetch job info and results from the REST API, rather than from cache.
             This also updates the cache. If `refresh` is `false`, then the cache is preferred.

See [`results`](@ref)
"""
function job(
    job_id::JobId,
    account=nothing;
    params::Bool=true,
    results::Bool=true,
    refresh::Bool=false,
)
    job_response = Requests.job(job_id, account; refresh)
    if job_response.status == "Failed"
        # If status is "Failed" and we try to read results from the server, we won't
        # resuls. In fact not even a json object. We just get a string containing an
        # error message. In Requests.GET_request, we choose to throw an error in this
        # case.
        # So if status is "Failed", we don't send a request to the results endpoint.
        _results = nothing
    else
        _results = results ? Jobs.results(job_id, account; refresh) : nothing
    end
    return _make_job(job_response, _results; params)
end
job(job_id::AbstractString, _account=nothing; kws...) = job(JobId(job_id), _account; kws...)

"""
    job(job_in::RuntimeJob, account=nothing;  params::Bool=true, results::Bool=true, refresh::Bool=false)::RuntimeJob

Return information on `job_in`.

The fields `job_in.params` and `job_in.results` may have value `nothing`. Use this method to return a copy of `job_in` with
one or both of these fields populated, according to the keyword arguments `params` and `results`. These keyword arguments
are described in [`job`](@ref)

!!! note
    This function would be more useful if it were optimized to fetch only the needed additional data, copying the rest from
    `jobin`. In fact, at present, it constructs the entire `RuntimeJob` from scratch.
"""
function job(
    _job::RuntimeJob,
    account=nothing;
    params::Bool=true,
    results::Bool=true,
    refresh::Bool=false,
)
    return job(_job.job_id, account; params, results, refresh)
end

"""
    job_ids(account=nothing)

Return an iterator over `JobId`s for all jobs.

`job_ids` first requests all the information on the jobs, then
extracts the ids. This function always makes requests to the REST API and
does not access the cache.

Use [`cached_job_ids`](@ref) to get ids only for cached job requests.
"""
function job_ids(account=nothing)
    ids = Requests.job_ids(account)
    return (JobId(id) for id in ids)
end

# The return type does not accurately describe what is returned. :(
"""
    cached_job_ids()

Return an iterator over `JobId`s of cached jobs.

Use [`job_ids`](@ref) to request ids from the REST API.
"""
function cached_job_ids()::Generator{<:Generator{Vector{String}}}
    ids = Requests.cached_job_ids()
    return (JobId(id) for id in ids)
end

"""
    cached_jobs(; params::Bool=true, results::Bool=true)

Return an iterator over all cached jobs.

- `params`: If `true` include job input parameters (including the pubs).  Otherwise the field `params` has
            value `nothing`.
- `results`: If `true` get the job results, if available. Otherwise, the field `results` has value `nothing`.
"""
function cached_jobs(; params::Bool=true, results::Bool=true)
    return (job(id; params, results) for id in Requests.cached_job_ids())
end

struct InstancePlan
    instance::Instance
    plan::String
end

function Base.show(io::IO, ::MIME"text/plain", obj::InstancePlan)
    return Utils._show(io, obj; newlines=true)
end

struct UserInfo
    email::String
    instances::Vector{InstancePlan}
end

Base.show(io::IO, ::MIME"text/plain", obj::UserInfo) = Utils._show(io, obj; newlines=true)

"""
    user_info(account=nothing; refresh=false)::UserInfo

Return information about the user.

Information includes the user's email and a list of available instances.

!!! note
    The user info returned by the server is determined by the authentication token.
    Unlike other cached information, we do not key the cache by this information in order
    to avoid writing the token as plain text. So if you have more than one account, each
    with an associated token, the cache will not distinguish them. If you switch accounts
    and tokens, you should pass `refresh=true`.

    If you merely generate and use a new token for a single account, you do not need to
    refresh the cache.
"""
function user_info(account=nothing; refresh=false)
    _user = Requests.user_info(account; refresh)
    instances = [InstancePlan(Instance(inst.name), inst.plan) for inst in _user.instances]
    return UserInfo(_user.email, instances)
end

# Sometimes "result" sometimes "results" in Python version. We should pick the right name.
"""
    results(job_id, account=nothing; refresh=false)

Return results for `job_id`.

See [`job`](@ref)
"""
function results(job_id, account=nothing; refresh=false)
    results_response = Requests.results(job_id, account; refresh)
    res = Decode.decode(results_response; job_id)

    # FIXME: Integrate this decoding into the `decode` methods.
    # If res is a Dict, we only recognize length of 2.
    if isa(res, Dict)
        length(res) == 2 &&
            return PrimitiveResults.PlainResult(res[:results], res[:metadata], job_id)
        # We don't know the structure of the `Dict`, so we just add the job id.
        res[:job_id] = job_id
    end

    return res
end

"""
    results(job::RuntimeJob, account=nothing; refresh=false)

Return results associated with `job`.

Results already contained in `job` are returned if it makes sense to do so.

More precisely, if `job.results` is not `nothing` and `refresh` is `false`, then `job.results` is
returned. If `job.results` is `nothing` then results are fetched from the cache or the REST API. If
`refresh` is `false` then the cache is preferred.
"""
function results(job::RuntimeJob, account=nothing; refresh=false)
    (isnothing(job) || refresh) && return results(job.job_id, account; refresh)
    return job.results
end

"""
    run_job(backend_name::AbstractString, pubs::AbstractVector{<:AbstractPUB}, qaccount=nothing)

Run `pubs` on device `backend_name`.

Parameters for controlling error mitigation are not yet supported.

See [`Accounts.QuantumAccount`](@ref), [`PUBs.EstimatorPUB`](@ref),
[`PUBs.SamplerPUB`](@ref), [`Backends.backends`](@ref).
"""
function run_job(
    backend_name::AbstractString,
    pubs::AbstractVector{<:AbstractPUB},
    qaccount=nothing,
)
    response = Requests.run_job(backend_name, pubs, qaccount)
    return JobId(response.id)
end

end # module Jobs
