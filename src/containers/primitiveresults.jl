module PrimitiveResults

import Dates
import ..Utils
import ..SomeTypes: PubEncodedCircuit
import ..PauliOperators: PauliOperator

export PrimitiveResult, SamplerPubResult, PubResult, DataBin, Metadata, ExecutionSpan,
    LayerError, PauliLindbladError

struct PrimitiveResult
    pub_results
    metadata
end

Base.show(io::IO, ::MIME"text/plain", pr::PrimitiveResult) =
    Utils._show(io, pr; newlines=true)

struct SamplerPubResult
    data
    metadata
end

struct PubResult
    data
    metadata
end

Base.show(io::IO, ::MIME"text/plain", pr::PubResult) =
    Utils._show(io, pr; newlines=true)

struct DataBin{T}
    fields::T
end

Base.show(io::IO, ::MIME"text/plain", db::DataBin) =
    Utils._show(io, db; newlines=true)

struct Metadata{T}
    fields::T
    version::VersionNumber
end

Base.show(io::IO, ::MIME"text/plain", pr::Metadata) =
    Utils._show(io, pr; newlines=true)

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
    circuit::PubEncodedCircuit
    error::PauliLindbladError
    qubits::Vector{Int}
end

Base.show(io::IO, ::MIME"text/plain", le::LayerError) =
    Utils._show(io, le; newlines=true)

# This does not work because some fields have no copy constructor.
# I don't see an easy way to get this info without an instance of the obj.
# for T in (PubResult, DataBin, Metadata, ExecutionSpan)
#     fnames = fieldnames(T)
#     args = Tuple(:(copy(obj.$x)) for x in fnames)
# #    @eval Base.copy(obj::$T) = $T((copy(getfield(obj, name)) for name in $fnames)...)
# end

end # module PrimitiveResults

