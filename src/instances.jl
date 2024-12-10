module Instances

struct Instance
    hub::String
    group::String
    project::String
end

function Instance(instance::AbstractString)
    (hub, group, project) = split(instance, '/')
    Instance(hub, group, project)
end

function Base.show(io::IO, ::MIME"text/plain", instance::Instance)
    print(io, "Instance(", instance, ")")
end

function Base.print(io::IO, instance::Instance)
    print(io, join((instance.hub, instance.group, instance.project), "/"))
end

end # module Instances
