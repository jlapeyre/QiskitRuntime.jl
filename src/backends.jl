module Backends

import Dates

import ..Requests
import ..Utils

struct BackendProperties
    backend_name::String
    backend_version::VersionNumber
    last_update_date::Dates.DateTime

    function BackendProperties(
        backend_name,
        backend_version,
        last_update_date,
        )
        if isa(last_update_date, String)
            if endswith(last_update_date, 'Z')
                last_update_date = last_update_date[1:end-1]
            end
        end
        return new(backend_name,
                   VersionNumber(backend_version),
                   Dates.DateTime(last_update_date))
    end
end

mutable struct Backend
    const name::String
    const backend_version::VersionNumber
    properties::BackendProperties
end


function Backend(name::AbstractString)
    props = Requests.backend_properties(name)
    backend_name = props.backend_name
    backend_version = props.backend_version
    last_update_date = props.last_update_date
    props_obj = BackendProperties(backend_name, backend_version, last_update_date)

    Backend(backend_name, VersionNumber(backend_version), props_obj)
end

# Several words for one thing: provider == instance = hubgroupproject
"""
    backends(service=nothing; pending=false, testing=false, instance=nothing)

Return a list of available backends. If `pending` is `true`, then return
a list of tuples `(name, num_pending_jobs)` sorted by `num_pending_jobs`.
If `testing` is `true` then include test devices; those beginning with `"test_"`.
"""
function backends(service=nothing; pending=false, testing=false, instance=nothing)
    backend_result = Requests.backends(service; provider=instance)
    backend_names = collect(backend_result.devices)
    if !testing
        backend_names = filter(!startswith("test_"), backend_names)
    end
    pending || return backend_names
    pending_jobs =
        [backend_status(b).pending_jobs for b in backend_names]
    names_pending = collect(zip(backend_names, pending_jobs))
    sort!(names_pending; lt = (x,y) -> x[2] < y[2])
    names_pending
end

struct BackendStatus
#    backend_name::String
    backend_version::Union{Nothing, VersionNumber}
    operational::Bool
    pending_jobs::Int
    status_msg::String
end

Base.show(io::IO, ::MIME"text/plain", bs::BackendStatus) = Utils._show(io, bs)

function backend_status(backend_name::AbstractString, service=nothing)
    st = Requests.backend_status(backend_name, service)
    version = isempty(st.backend_version) ?
        nothing : VersionNumber(st.backend_version)
    BackendStatus(
        # st.backend_name,
        version,
        st.state, # operational
        st.length_queue, # pending_jobs
        st.message)
end

end # module Backends
