module Ids

import Random

export JobId, UserId, Token

function validate end

###
### JobId
###

export JobId, validate, UserId, Token

struct JobId
    id::String
    function JobId(id::String)
        validate(JobId, id)
        new(id)
    end
end

"""
    validate(::Type{JobId}, job_id::AbstractString)

Return `true` if `job_id` is a valid job id.

`job_id` must be a twenty digit string of `0-9` and `a-z`. There may
be other restrictions, but we don't know about them and cannot check them.
"""
function validate(::Type{JobId}, job_id::AbstractString)
    length(job_id) == 20 || error("job id has incorrect length")
    occursin(r"^[a-z|0-9]+$", job_id) || error("Illegal character in job id")
    true
end

Random.rand(rng::Random.AbstractRNG, ::Random.SamplerType{JobId}) =
    JobId(lowercase(Random.randstring(rng, 20)))

Base.print(io::IO, id::JobId) = print(io, id.id)

# It's not clear to me where these are used
Base.convert(::Type{String}, id::JobId) = string(id)
Base.convert(::Type{JobId}, id::AbstractString) = JobId(id)

# For `id * ".json"
Base.:*(id::JobId, s::String) = string(id) * s
Base.:*(s::String, id::JobId) = s * string(id)

###
### UserId
###

# I have not seen a schema, so I am guessing based on a few inputs.
# Input strings are 24 hex "digits".
struct UserId
    data::NTuple{3, UInt32}

    function UserId(data::NTuple{3, UInt32})
        new(data)
    end

    function UserId(str::AbstractString)
        parse(UserId, str)
    end
end

Base.string(uid::UserId) = join((string(x;base=16, pad=8) for x in uid.data), "")

Random.rand(rng::Random.AbstractRNG, ::Random.SamplerType{UserId}) =
    UserId(Tuple(rand(rng, UInt32) for _ in 1:3))

# See UUID implementation for more efficient way to do this
# But it uses StringMemory.
function Base.tryparse(::Type{UserId}, str::AbstractString, parsef::F=tryparse) where {F}
    length(str) == 24 || return nothing
    strparts = Tuple(@view str[(i-1)*8 + 1:i*8] for i in 1:3)
    nums = (parsef(UInt32, part; base=16) for part in strparts)
    any(isnothing, nums) && return nothing
    UserId(Tuple(nums))
end

function Base.parse(::Type{UserId}, str::AbstractString)
    length(str) == 24 || throw(ValueError(lazy"UserId must be 24 hex digits"))
    tryparse(UserId, str, parse)
end

function Base.show(io::IO, id::UserId)
    print(io, typeof(id), "(")
    show(io, string(id))
    print(io, ")")
end

function Base.print(io::IO, id::UserId)
    print(io, string(id))
end

###
### Token
###

# We assume the token is just 512 random bits.
struct Token
    data::NTuple{8, UInt64}

    function Token(data::NTuple{8, UInt64})
        new(data)
    end

    function Token(str::AbstractString)
        parse(Token, str)
    end
end

function Base.show(io::IO, tok::Token)
    print(io, typeof(tok), "(")
    show(io, string(tok))
    print(io, ")")
end

Random.rand(rng::Random.AbstractRNG, ::Random.SamplerType{Token}) =
    Token(Tuple(rand(rng, UInt64) for _ in 1:8))

Base.string(token::Token) = join((string(x;base=16, pad=16) for x in token.data), "")

Base.convert(::Type{Token}, id::AbstractString) = Token(id)

function Base.tryparse(::Type{Token}, str::AbstractString, parsef::F=tryparse) where {F}
    strparts = Tuple(@view str[(i-1)*16 + 1:i*16] for i in 1:8)
    nums = (parsef(UInt64, part; base=16) for part in strparts)
    any(isnothing, nums) && return nothing
    Token(Tuple(nums))
end

function Base.parse(::Type{Token}, str::AbstractString)
    length(str) == 128 || throw(ArgumentError(lazy"Token must be 128 hex digits"))
    tryparse(Token, str, parse)
end

end # module Ids