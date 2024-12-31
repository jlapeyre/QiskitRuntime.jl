module PrimitiveResults

# structs in this module could be reorganized.

import Dates
import ..Utils
import ..Circuits: CircuitString
import ..PauliOperators: PauliOperator
import ..Ids: JobId

export PrimitiveResult, PlainResult, SamplerPubResult, PubResult, DataBin, Metadata, ExecutionSpan,
    LayerError, PauliLindbladError

struct Metadata
    fields::Dict{Symbol, Any}
    version::VersionNumber
end

Base.show(io::IO, ::MIME"text/plain", pr::Metadata) =
    Utils._show(io, pr; newlines=true)

struct PubResult
    data
    metadata
end

Base.show(io::IO, ::MIME"text/plain", pr::PubResult) =
    Utils._show(io, pr; newlines=true)

"""
    struct PrimitiveResult{T}

This struct contains job results that were tagged with the type `PrimitiveResults`.

`T` is related to the type of [PUBs](https://docs.quantum.ibm.com/guides/primitive-input-output) in
this container. We currently find values of `PubResult` and `SamplerPubResult`. I think the former
may really be used always and only for EstimatorV2 results. But I am not sure.
"""
struct PrimitiveResult{T}
    pub_results::Vector{T}
    metadata::Metadata
    job_id::JobId
end

Base.show(io::IO, ::MIME"text/plain", pr::PrimitiveResult) =
    Utils._show(io, pr; newlines=true)

# Some results are not typed. They are a plain dict.
# We make up a name: `PlainResult`

"""
    struct PlainResult

This contains job results that were returned as a `Dict` with two keys, `:results`, and `:metadata`.
I have not yet found documentation on results returned in this form. The struct `PlainResult` is
an ad-hoc way to handle this case.
"""
struct PlainResult
    results
    metadata
    job_id::JobId
end

Base.show(io::IO, ::MIME"text/plain", pr::PlainResult) =
    Utils._show(io, pr; newlines=true)

struct SamplerPubResult
    data
    metadata
end

Base.show(io::IO, ::MIME"text/plain", r::SamplerPubResult) =
    Utils._show(io, r; newlines=true)


struct DataBin{T}
    fields::T
end

Base.show(io::IO, ::MIME"text/plain", db::DataBin) =
    Utils._show(io, db; newlines=true)

struct ExecutionSpan{T}
    start::Dates.DateTime
    stop::Dates.DateTime
    data_slices::T
end

Base.copy(es::ExecutionSpan) = ExecutionSpan(es.start, es.stop, copy(es.data_slices))

struct PauliLindbladError
    generators::Vector{PauliOperator}
    rates::Vector{Float64}
end

Base.show(io::IO, ::MIME"text/plain", pe::PauliLindbladError) =
    Utils._show(io, pe; newlines=true)

struct LayerError
    circuit::CircuitString
    error::PauliLindbladError
    qubits::Vector{Int}
end

Base.show(io::IO, ::MIME"text/plain", le::LayerError) =
    Utils._show(io, le; newlines=true)

struct LayerNoise
    unique_mitigated_layers::Int
    unique_mitigated_layers_noise_overhead::Vector{Float64}
    total_mitigated_layers::Int
    noise_overhead::Float64
end

Base.show(io::IO, ::MIME"text/plain", le::LayerNoise) =
    Utils._show(io, le; newlines=true)

# This does not work because some fields have no copy constructor.
# I don't see an easy way to get this info without an instance of the obj.
# for T in (PubResult, DataBin, Metadata, ExecutionSpan)
#     fnames = fieldnames(T)
#     args = Tuple(:(copy(obj.$x)) for x in fnames)
# #    @eval Base.copy(obj::$T) = $T((copy(getfield(obj, name)) for name in $fnames)...)
# end

end # module PrimitiveResults
