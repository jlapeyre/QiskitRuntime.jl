module Backends

import Dates

import ..Requests

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

function backends()
    Requests.backends
#    collect(
end


end # module Backends
