module SomeTypes

# This is an encoded Python type. I don't know where in the source code is
# the code for decoding the value. Doesn't do much good, since this
# is (always) a QuantumCircuit.
# QASM3 strings should not hit this code path
# We use this type temporarily; In part to avoid printing enormous encoded circuits.
struct PubEncodedCircuit{T} # T is of type Symbol. May be tricks online to restrict
    value::String
end

# Truncate printing
function Base.print(io::IO, c::PubEncodedCircuit)
    v = c.value
    print(io, typeof(c), "(")
    if length(v) > 100
        print(io, v[1:20], " ... ", v[end-20:end])
    else
        print(io, v)
    end
    print(io, ")")
end

function Base.show(io::IO, ::MIME"text/plain", c::PubEncodedCircuit)
    print(io, c)
end

Base.show(io::IO, c::PubEncodedCircuit) = print(io, c)

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

# It's not clear to me where these are used
Base.convert(::Type{String}, id::JobId) = string(id)
Base.convert(::Type{JobId}, id::AbstractString) = JobId(id)

# For `id * ".json"
Base.:*(id::JobId, s::String) = string(id) * s
Base.:*(s::String, id::JobId) = s * string(id)

end # module SomeTypes
