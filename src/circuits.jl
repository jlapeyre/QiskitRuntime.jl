module Circuits

import ..Utils: api_data_structure

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

function api_data_structure(circ_str::CircuitString)
    return Dict(:__type__ => "QuantumCircuit", :__value__ => string(circ_str))
end

# Truncate printing
function Base.print(io::IO, c::AbstractCircuitString)
    v = c.data
    print(io, typeof(c), "(")
    if length(v) > 100
        print(io, v[1:20], " ... ", v[(end - 20):end])
    else
        print(io, v)
    end
    return print(io, ")")
end

function Base.show(io::IO, ::MIME"text/plain", c::AbstractCircuitString)
    return print(io, c)
end

Base.show(io::IO, c::AbstractCircuitString) = print(io, c)

function Base.string(c::AbstractCircuitString)
    return c.data
end

end # module Circuits
