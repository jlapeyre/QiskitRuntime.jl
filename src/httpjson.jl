# From Discourse. Not using at the moment

module HTTPJSON3
import HTTP, JSON3

function json3_layer(handler)
    return function(req; kw...)
        HTTP.setheader(req, "Content-Type" => "application/json")
        r = handler(req; kw...)
        HTTP.Response(r.status, r.headers, JSON3.read(r.body); r.request)
    end
end

function HTTP.Messages.bodysummary(obj::Union{JSON3.Object, JSON3.Array})
    io = IOBuffer()
    print(io, obj)
    String(take!(io))
end

HTTP.@client [json3_layer]
end # module HTTPJSON3
