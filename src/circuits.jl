module Circuits

export AbstractCircuitString, CircuitString, QASMString

abstract type AbstractCircuitString end

"""
    QASMString

OpenQASM 3 program as a `String`.
"""
struct QASMString <: AbstractCircuitString
    data::String
end

"""
    struct CircuitString

Serialized, compressed, encoded data  of Python `QuantumCircuit` type

The `QuantumCircuit` was serialized as qpy, then compressed with zlib, then base64 encoded.
"""
struct CircuitString <: AbstractCircuitString
    data::String
end

# Truncate printing
function Base.print(io::IO, c::AbstractCircuitString)
    v = c.data
    print(io, typeof(c), "(")
    if length(v) > 100
        print(io, v[1:20], " ... ", v[end-20:end])
    else
        print(io, v)
    end
    print(io, ")")
end

function Base.show(io::IO, ::MIME"text/plain", c::AbstractCircuitString)
    print(io, c)
end

Base.show(io::IO, c::AbstractCircuitString) = print(io, c)

function Base.string(c::AbstractCircuitString)
    c.data
end

end # module Circuits
