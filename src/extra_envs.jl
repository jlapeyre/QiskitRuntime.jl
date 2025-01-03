"""
    module ExtraEnvs

Contains facilites for managing an environment of extra (auxilliary) packages.

The module defines [`ExtraEnv`](@ref) and implements functions that use data therein
to manipulate the stack of environements (`Base.LOAD_PATH`).

There are some functions missing. For example, for adding and removing packages from the
`ExtraEnv`. This can be done manually, but is would be a bit fiddle. These functions might
be added later.
"""
module ExtraEnvs

using Pkg: Pkg

export ExtraEnv,
    ensure_in_stack,
    is_in_stack,
    env_exists,
    create_env,
    delete_from_stack!,
    activate_env,
    update_env

"""
    struct ExtraEnv

Data for defining an "extra" shared environment.

When working with a particular package, you might frequently use certain other packages that
are not in the dependencies of the particular one. `ExtraEnv` is meant to help manage these
other packages. You can do this by hand as well. But it's sometimes not easy to remember
what you want to do and exactly how to do it.

`ExtraEnv` helps you create a shared environment and make sure it is in your stack of environments
so that its packages are visibile when it is not the active environment. You are *not* meant
to do work with the environment in `ExtraEnv` activated.

The most important function for creating an `ExtraEnv` and making it visible is [`ensure_in_stack`](@ref).

# Fields
- `name::String`: the name of the extra environment
- `packages::Vector{Symbol}`: A list of packages to use to initialize the environment.

See [`update_env`](@ref) [`create_env`](@ref), [`ensure_in_stack`](@ref), [`env_exists`](@ref),
[`activate_env`](@ref), [`is_in_stack`](@ref), [`delete_from_stack!`](@ref).

# Syncing `(env::ExtraEnv).packages` with the environment's `Project.toml`

We don't provide a way to do this. I don't think `Pkg` exposes tools for this. But we
could proably find and read the `Project.toml` file. So the packages in the environment
may differ from those in `(env::ExtraEnv).packages`. We only provide
[`update_env`](@ref) which blindly adds everything in `env.packages` to the
environment `env.name`.

# Examples
```jldoctest
julia> ExtraEnv("an_extra_env", [:Example])
ExtraEnv("an_extra_env", [:Example])

julia> ExtraEnv("@an_extra_env", [:Example])
ExtraEnv("an_extra_env", [:Example])
```
"""
struct ExtraEnv
    name::String
    packages::Vector{Symbol}

    function ExtraEnv(name::AbstractString, packages::AbstractVector)
        return new(_no_at_name(name), [Symbol(p) for p in packages])
    end
end

"""
    ExtraEnv(env_name::AbstractString)

Initialize an `ExtraEnv` with an empty list of packages.

# Examples
```jldoctest
julia> ExtraEnv("an_extra_env")
ExtraEnv("an_extra_env", Symbol[])

julia> ExtraEnv("@an_extra_env")
ExtraEnv("an_extra_env", Symbol[])
```
"""
ExtraEnv(env_name::AbstractString) = ExtraEnv(env_name, Symbol[])

# Make sure `name` starts with "@".
# Prepend an "@" only if it is missing.
function _at_name(name::AbstractString)
    startswith(name, "@") && return string(name)
    return string("@", name)
end

# Make sure `name` does *not* start with "@"
# Remove "@" if present.
function _no_at_name(name::AbstractString)
    isempty(name) && return ""
    startswith(name, "@") && return string(@view name[2:end])
    return string(name)
end

"""
    ensure_in_stack(env_name::AbstractString, env_packages::AbstractVector)::ExtraEnv

Create `env = ExtraEnv(env_name, env_packages)`, run `ensure_in_stack(env)` and return `env`.

Elements of `env_packages` should be `AbstractString`s or `Symbol`s.

See [`ExtraEnv`](@ref).

# Examples
```julia-repl
julia> ensure_in_stack("my_extra_env", [:PackageA, :PackageB]);
```
"""
function ensure_in_stack(env_name::AbstractString, env_packages::AbstractVector)
    env = ExtraEnv(env_name, [Symbol(p) for p in env_packages])
    ensure_in_stack(env)
    return env
end

"""
    ensure_in_stack(env::ExtraEnv)::ExtraEnv

Ensure that a shared environment `env.name` with `env.packages` is in your stack.

Recall that the environment stack is `Base.LOAD_PATH`.

If `env.name` does not name a shared environment, create it and add `env.packages`.
Furthermore, if `env.name` is not in the stack, add it to the stack.

After this runs, the packages `env.packages` should be available in whatever project
is active.

!!! note
    If you have added packages to `env.packages` (say with `push!(env.packages, :APack)`)
    then `ensure_in_stack` will not automatically add these to the environment. To do
    this, you must call `update_env(env)`.

See [`ExtraEnv`](@ref).
"""
function ensure_in_stack(env::ExtraEnv)::ExtraEnv
    env_exists(env) || create_env(env)
    atenv = _at_name(env.name) # This must already be the case!
    atenv in Base.LOAD_PATH || push!(Base.LOAD_PATH, atenv)
    return env
end

"""
    is_in_stack(env_name::AbstractString)::Bool

Return `true` if the shared environment `env_name` is in the environment stack.

If `env_name` does not start with `'@'`, it is prepended. The stack is `Base.LOAD_PATH`.
"""
function is_in_stack(env_name::AbstractString)::Bool
    return _at_name(env_name) in Base.LOAD_PATH
end

"""
    is_in_stack(env::ExtraEnv)::Bool

Return `true` if the shared environment `env.name` is in the environment stack.

See [`ExtraEnv`](@ref).
"""
is_in_stack(env::ExtraEnv)::Bool = is_in_stack(env.name)

"""
    env_exists(env::ExtraEnv)::Bool

Return `true` if the shared environment in `env` already exists.

See [`ExtraEnv`](@ref).
"""
env_exists(env::ExtraEnv)::Bool = env_exists(env.name)

"""
    env_exists(env_name::AbstractString)::Bool

Return `true` if the shared environment `env_name` already exists.

`env_name` may begin with "@" or not.

This environment might be activated via `Pkg.activate(env_name)`
If done from the `pkg` repl, the name must start with `'@'`.
"""
function env_exists(env_name::AbstractString)::Bool
    return _no_at_name(env_name) in readdir(Pkg.envdir())
end

"""
    create_env(env::ExtraEnv)

Create a shared environment named `env.name` with packages `env.packages`.

If the shared environment `env.name` already exists, an error is thrown.

See [`ExtraEnv`](@ref).
"""
function create_env(env::ExtraEnv)
    env_exists(env) &&
        throw(ErrorException(lazy"Environment \"$(env.name)\" already exists"))
    return update_env(env)
end

"""
    update_env(env::ExtraEnv)

Add all packages in `env.packages` to the shared environment `env.name`.

If the shared environment `env.name` does not exist, it is created.

This is the same as [`create_env`](@ref) except no check is made that the environment
does not already exist. Any packages that have already been added to the environment
will be added again, which should be little more than a no-op.

# Examples

Say I want to add `CondaPkg.jl` to the packages in `env::ExtraEnv`.

```julia-repl
julia> env.packages
2-element Vector{Symbol}:
 :PythonCall
 :StatsBase

julia> push!(env.packages, :CondaPkg)
3-element Vector{Symbol}:
 :PythonCall
 :StatsBase
 :CondaPkg

julia> update_env(env)
  Activating project at `~/.julia/environments/qkruntime_extra`
  ...
  Updating `~/.julia/environments/qkruntime_extra/Project.toml`
 [992eb4ea] + CondaPkg v0.2.24
```
"""
function update_env(env::ExtraEnv)
    current_project = Base.active_project()
    try
        Pkg.activate(_no_at_name(env.name); shared=true)
        for pkg in env.packages
            @show pkg
            Pkg.add(string(pkg))
        end
    catch
        rethrow()
    finally
        Pkg.activate(current_project)
    end
end

"""
    update_env(env_name::AbstractString, env_packages::AbstractVector)::ExtraEnv

Create `env = ExtraEnv(env_name, env_packages)` and create or update the environment `env_name`.

The shared environment `env_name` will be created if it does not exist.
Possible existing packages in the the environment are not removed. If
packages in `env_packages` are already in the environment, they are added again.

Elements of `env_packages` should be `AbstractString`s or `Symbol`s.

`update_env` is the same as `create_env(env_name, env_packages)` except that the
latter will throw an error if the environment already exists.

See [`ExtraEnv`](@ref).
"""
function update_env(env_name::AbstractString, env_packages::AbstractVector)
    env = ExtraEnv(env_name, [Symbol(p) for p in env_packages])
    update_env(env)
    return env
end

"""
    delete_from_stack!(env::ExtraEnv)

Delete environment `env.name` wherever it occurs in the stack `Base.LOAD_PATH`.

See [`ExtraEnv`](@ref).
"""
function delete_from_stack!(env::ExtraEnv)
    return delete_from_stack!(env.name)
end

"""
    delete_from_stack!(env_name::Union{AbstractString, Symbol})

Delete environment `env_name` wherever it occurs in the stack `Base.LOAD_PATH`.

See [`ExtraEnv`](@ref).
"""
function delete_from_stack!(env_name::Union{AbstractString,Symbol})
    stack = Base.LOAD_PATH
    atname = _at_name(env_name)
    return deleteat!(stack, findall(==(atname), stack)...)
end

"""
    activate_env(env::ExtraEnv)

Activate the shared environment `env.name`.

You might want to do this to add or remove packages from the environment.
But it is not necessary to activate it to use it.

See [`ExtraEnv`](@ref), [`create_env`](@ref), [`ensure_in_stack`](@ref),
[`env_exists`](@ref).
"""
function activate_env(env::ExtraEnv)
    return Pkg.activate(_no_at_name(env.name); shared=true)
end

end # module ExtraEnvs
