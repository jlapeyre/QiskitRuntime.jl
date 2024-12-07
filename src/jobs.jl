module Jobs

using Dates: DateTime
import ..Instances: Instance
import ..Accounts: UserId
import ..Utils
import ..Decode

let
function _validate_jobid(job_id::AbstractString)
    length(job_id) == 20 || error("job id has incorrect length")
    occursin(r"^[a-z|0-9]+$", job_id) || error("Illegal character in job id")
    true
end

global JobId
struct JobId
    id::String
    function JobId(id::String)
        _validate_jobid(id)
        new(id)
    end
end
end

Base.print(io::IO, id::JobId) = print(io, id.id)

# For automatic conversion to `String` at call sites.
Base.convert(String, id::JobId) = string(id)

# For `id * ".json"
Base.:*(id::JobId, s::String) = string(id) * s
Base.:*(s::String, id::JobId) = s * string(id)

# function Base.convert(::Type{String}, job_id::JobId)
#     string(job_id)
# end
# function Base.convert(::Type{JobId}, job_id::String)
#     JobId(job_id)
# end

@enum JobStatus Queued Running Done Error Cancelled

abstract type Primitive end

struct Sampler <: Primitive end
struct Estimator <: Primitive end
# We need to do something better with options and pubs
struct JobParams
    support_qiskit::Union{Bool, Nothing}
    # Avoid futher headaches with versions. But the endpoint returns an Int, so maybe useless.
    version::VersionNumber
    resilience_level::Union{Int, Nothing} # I think this is deprecated
    options::Union{Dict{Symbol, Any}, Nothing}
    pubs::Vector{Any}
end

function JobParams(dict::Dict)
    pubs = [begin
                [begin
                     isa(p, Dict{Symbol, <:Any}) ? Decode.decode(p) : p
                 end
                 for p in pub]
             end
             for pub in dict[:pubs]]
    JobParams(
        get(dict, :support_qiskit, nothing),
        VersionNumber(dict[:version]),
        get(dict, :resilience_level, nothing),
        get(dict, :options, nothing),
        pubs
    )
end

# struct JobInfo
# end

struct RuntimeJob{PrimitiveT}
    job_id::JobId
    user_id::UserId
    session_id::Union{JobId, Nothing}
    primitive_id::PrimitiveT
    backend_name::String
    creation_date::DateTime
    end_date::Union{DateTime, Nothing}
    instance::Instance
    # state and status in Python runtime and REST API is quite complicated
    # We simply copy the REST API strings here. But this should be revisted.
    # If the following two are alwasy the same, we should remove one of them.
    state::JobStatus
    status::JobStatus
    cost::Int
    private::Bool
    tags::Vector{String}
    params::JobParams
end

Base.show(io::IO, ::MIME"text/plain", rtj::RuntimeJob) =
    Utils._show(io, rtj; newlines=true)

module _Jobs

using Dates: DateTime
import ...Utils
import ...Decode
import ...Instances: Instance
import ...Accounts: UserId
import ...Requests

import ..JobId, ..JobStatus, ..Queued, ..Running, ..Done,  ..Error,  ..Cancelled, ..JobParams,
    ..Sampler, ..Estimator, ..RuntimeJob

# We want to encode "sampler" and "estimator"
# in a type, or proscribed values. But this is clunky.
# Perhaps an enum.
function _primitive(_primitive::AbstractString)
    if _primitive == "sampler"
        Sampler()
    elseif _primitive == "estimator"
        Estimator()
    else
        error("Uknown primitive \"$_primitive\"") # Make this Lazy !
    end
end

# Precompile and hide data in let block for _api_to_job_status
let dict = Dict(
    :Queued => Queued,
    :Running => Running,
    :Completed => Done,
    :Failed => Error,
    :Cancelled => Cancelled
    )

    global _api_to_job_status
    function _api_to_job_status(api_status)
        return dict[Symbol(api_status)]
    end
end

function _make_job(response)

    instance = Instance(response.hub, response.group, response.project)

    session_id = response.session_id
    if ! isnothing(session_id)
        session_id = JobId(session_id)
    end

    tags = response.tags
    tags = isnothing(tags) ? String[] : collect(tags)

    return RuntimeJob(
        JobId(response.id), # job_id
        UserId(response.user_id), # user_id
        session_id, # session_id
        _primitive(response.program.id), # primitive_id
        response.backend, # backend_name
        Decode.parse_response_datetime(response.created), # creation_date
        Decode.parse_response_maybe_datetime(response.ended), # end date
        instance, # instance
        _api_to_job_status(response.state.status), # state
        _api_to_job_status(response.status), # status
        response.cost, # cost
        response.private, # private
        tags, # tags
        # `copy` converts JSON3 efficienct struction into plain old types.
        # This is a bit wasteful. We should pass JSON3 first
        JobParams(copy(response.params))
    )
end


end # module _Jobs


# `Requests.cached_job_ids` returns what we want in this layer. So we just
# import it. Alternative would be to wrap it instead.
import ..Requests: Requests
import ..Accounts
import ..Instances: Instance

import ._Jobs: _make_job

export  job, job_ids, cached_jobs, cached_job_ids, results, user

"""
    job(job_id, service=nothing; refresh=false)::RuntimeJob

Return information on `job_id`.
"""
function job(job_id::JobId, _account=nothing; refresh=false)
    account = isnothing(_account) ? Accounts.QuantumAccount() : _account
    job_response = Requests.job(job_id, account; refresh)
    _make_job(job_response)
end

job(job_id::AbstractString, _account=nothing; kws...) = job(JobId(job_id), _account; kws...)

"""
    job_ids(account=nothing)::Vector

Return a collection of job ids.

`job_ids` first request all the information on the jobs, then
extracts the ids.

Use [`cached_job_ids`](@ref) to get ids only for cached job requests.
"""
function job_ids(account=nothing)
    ids = Requests.job_ids(account)
    (JobId(id) for id in ids)
end

function cached_job_ids()
    ids = Requests.cached_job_ids()
    (JobId(id) for id in ids)
end

function cached_jobs()
    job_ids = Requests.cached_job_ids()
    (job(id) for id in job_ids)
end

struct InstancePlan
    instance::Instance
    plan::String
end

struct UserInfo
    email::String
    instances::Vector{InstancePlan}
end

"""
    user(account=nothing)

Return information about the user.

Information includes the user's email and a list of available instances.
"""
function user(account=nothing)
    _user = Requests.user(account)
    instances = [InstancePlan(Instance(inst.name), inst.plan) for inst in _user.instances]
    UserInfo(_user.email, instances)
end

# Sometimes "result" sometimes "results" in Python version. We should pcik the right one.
"""
    results(job_id, service=nothing; refresh=false)::RuntimeJob

Return results for `job_id`.
"""
function results(job_id, _account=nothing; refresh=false)
    account = isnothing(_account) ? Accounts.QuantumAccount() : _account
    results_response = Requests.results(job_id, account; refresh)
    Decode.decode(results_response)
end

"""
    results(job::RuntimeJob)

Return results associated with `job`.
"""
results(job::RuntimeJob) = results(job.job_id)

end # module Jobs
