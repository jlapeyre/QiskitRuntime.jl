module Instances

export Instance

struct Instance
    hub::String
    group::String
    project::String
end

# TODO: There are some tools to do this more generically.
function as_tuple(instance::Instance)
    (; hub, group, project) = instance
    return (hub, group, project)
end

# Join the parts of `instance` with separator `sep`.
function as_string(instance::Instance, sep="/")
    return join(as_tuple(instance), sep)
end

"""
    Instance(instance::AbstractString)

Construct an `Instance` from a string of the form `"hub/group/project"`.

```jldoctest
julia> inst = Instance("a_hub/a_group/a_project")
Instance(a_hub/a_group/a_project)

julia> inst.project
"a_project"

julia> Instance("a_hub/a_group/a_project/")
ERROR: ArgumentError: Expecting three parts separated by '/'. Got 4 parts
```
"""
function Instance(instance::AbstractString)
    parts = split(instance, '/')
    length(parts) == 3 || throw(
        ArgumentError(
            lazy"Expecting three parts separated by '/'. Got $(length(parts)) parts",
        ),
    )
    (hub, group, project) = parts
    return Instance(hub, group, project)
end

function Base.show(io::IO, ::MIME"text/plain", instance::Instance)
    return print(io, "Instance(", instance, ")")
end

# We use this for desired result in Utils._show
function Base.show(io::IO, instance::Instance)
    return print(io, "Instance(", instance, ")")
end

function Base.print(io::IO, instance::Instance)
    return print(io, as_string(instance))
end

# If you include the instance as part of a filename, the slashes will be
# directory separators. Replace them with underscores.
function filename_encoded(instance::Instance)
    return as_string(instance, "_")
end

# This allows automatic conversion to `String` when passing `Instance` as a parameter.
# If a function expects a string, passing in instance will work.
# Here `string` falls back to the method for `print` above.
function Base.convert(::Type{String}, instance::Instance)
    return string(instance)
end

end # module Instances
