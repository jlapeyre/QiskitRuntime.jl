"""
    module Ids

This module implements identification numbers and related objects.

`structs` implemented here include: [`JobId`](@ref), [`UserId`](@ref), and [`Ids.Token`](@ref).

!!! note
    We may want to expose less from this module than we do at present. For example, generating bogus
    ids is useful for mocking, but probabaly not for most users.
"""
module Ids

using Random: Random

export JobId, UserId, Token, validate

function validate end

###
### JobId
###

export JobId, validate, UserId, Token

"""
    struct JobId

Wrapper type for job ids

Because a session id is the first job id in a batch, `JobId` is used for session id as well.
The data is stored as a string that is validated on construction.

Note that passing validation is a necessary, but not sufficient condition for distinguishing job ids
returned by the server. We could investigate the format of job ids and tighten up the validation.

See [`validate`](@ref)
"""
struct JobId
    id::String
    function JobId(id::String)
        validate(JobId, id)
        return new(id)
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
    return true
end

"""
    Random.rand(rng::Random.AbstractRNG, ::Random.SamplerType{JobId})

Return a random `JobId`.

The set of strings sampled is actually larger than that of true job ids.
See [`JobId`](@ref).
"""
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

"""
    struct UserId

Wraps a user id.

The server returns 24 hex digits. We encode this as 96 bits in three `UInt32`s.
Thus, validation occurs on construction.
"""
struct UserId
    data::NTuple{3,UInt32}

    function UserId(data::NTuple{3,UInt32})
        return new(data)
    end

    function UserId(str::AbstractString)
        return parse(UserId, str)
    end
end

Base.string(uid::UserId) = join((string(x; base=16, pad=8) for x in uid.data), "")

"""
    Random.rand(rng::Random.AbstractRNG, ::Random.SamplerType{UserId}) =

Construct a random `UserId`.

This is done by generating and wrapping three `UInt32`s.
!!! note
    We may not want to expose this. It is used for mocking data.
"""
Random.rand(rng::Random.AbstractRNG, ::Random.SamplerType{UserId}) =
    UserId(Tuple(rand(rng, UInt32) for _ in 1:3))

# See UUID implementation for more efficient way to do this
# But it uses StringMemory.
function Base.tryparse(::Type{UserId}, str::AbstractString, parsef::F=tryparse) where {F}
    length(str) == 24 || return nothing
    strparts = Tuple(@view str[((i - 1) * 8 + 1):(i * 8)] for i in 1:3)
    nums = (parsef(UInt32, part; base=16) for part in strparts)
    any(isnothing, nums) && return nothing
    return UserId(Tuple(nums))
end

function Base.parse(::Type{UserId}, str::AbstractString)
    length(str) == 24 || throw(ValueError(lazy"UserId must be 24 hex digits"))
    return tryparse(UserId, str, parse)
end

function Base.show(io::IO, id::UserId)
    print(io, typeof(id), "(")
    show(io, string(id))
    return print(io, ")")
end

function Base.print(io::IO, id::UserId)
    return print(io, string(id))
end

###
### Token
###

# We assume the token is just 512 random bits.
"""
    struct Token

Wraps authentication tokens.

The server and the web dashboard express tokens as strings of 128 lower-case hexadecimal
digits. We store this as eight `UInt64`s. In particular, the `Token` is validated upon
construction.

Uppercase hexadecimal characters are allowed when parsing.

```jldoctest
julia> typeof(Token("884fad8b23e0cb2e19ae5df80aab5003e968ea4e3a69c6efce9a776b26cb157bb7456b189a964bdba89423ecb2e7b4d23c2644a672c9ba6ef2a1551bed5879d3"))
Token

julia> Token("abc123")
ERROR: ArgumentError: Token must be 128 hex digits

julia> Token("ABCDAD8B23E0CB2E19AE5DF80AAB5003E968EA4E3A69C6EFCE9A776B26CB157BB7456B189A964BDBA89423ECB2E7B4D23C2644A672C9BA6EF2A1551BED5879D3")
Token("abcdad8b23e0cb2e19ae5df80aab5003e968ea4e3a69c6efce9a776b26cb157bb7456b189a964bdba89423ecb2e7b4d23c2644a672c9ba6ef2a1551bed5879d3")
```
"""
struct Token
    data::NTuple{8,UInt64}

    function Token(data::NTuple{8,UInt64})
        return new(data)
    end

    function Token(str::AbstractString)
        return parse(Token, str)
    end
end

function Base.show(io::IO, tok::Token)
    print(io, typeof(tok), "(")
    show(io, string(tok))
    return print(io, ")")
end

"""
    Random.rand(rng::Random.AbstractRNG, ::Random.SamplerType{Token}) =

Generate a random `Token`.

This might be useful for putting a bogus token in your [credentials file](@ref credentials_file).
"""
Random.rand(rng::Random.AbstractRNG, ::Random.SamplerType{Token}) =
    Token(Tuple(rand(rng, UInt64) for _ in 1:8))

Base.string(token::Token) = join((string(x; base=16, pad=16) for x in token.data), "")

Base.convert(::Type{Token}, id::AbstractString) = Token(id)

function Base.tryparse(::Type{Token}, str::AbstractString, parsef::F=tryparse) where {F}
    strparts = Tuple(@view str[((i - 1) * 16 + 1):(i * 16)] for i in 1:8)
    nums = (parsef(UInt64, part; base=16) for part in strparts)
    any(isnothing, nums) && return nothing
    return Token(Tuple(nums))
end

function Base.parse(::Type{Token}, str::AbstractString)
    length(str) == 128 || throw(ArgumentError(lazy"Token must be 128 hex digits"))
    return tryparse(Token, str, parse)
end

end # module Ids
