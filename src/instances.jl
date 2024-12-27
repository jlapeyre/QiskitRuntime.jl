module Instances

struct Instance
    hub::String
    group::String
    project::String
end

# TODO: There are some tools to do this more generically.
function as_tuple(instance::Instance)
    (instance.hub, instance.group, instance.project)
end

# Join the parts of `instance` with separator `sep`.
function as_string(instance::Instance, sep="/")
    join(as_tuple(instance), sep)
end

function Instance(instance::AbstractString)
    (hub, group, project) = split(instance, '/')
    Instance(hub, group, project)
end

function Base.show(io::IO, ::MIME"text/plain", instance::Instance)
    print(io, "Instance(", instance, ")")
end

# We use this for desired result in Utils._show
function Base.show(io::IO, instance::Instance)
    print(io, "Instance(", instance, ")")
end

function Base.print(io::IO, instance::Instance)
    print(io, as_string(instance))
end

# If you include the instance as part of a filename, the slashes will be
# directory separators. Replace them with underscores.
function filename_encoded(instance::Instance)
    as_string(instance, "_")
end

# This allows automatic conversion to `String` when passing `Instance` as a parameter.
# If a function expects a string, passing in instance will work.
# Here `string` falls back to the method for `print` above.
function Base.convert(::Type{String}, instance::Instance)
    string(instance)
end

end # module Instances
