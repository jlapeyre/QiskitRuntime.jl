module JSON

using JSON3

function read(str::Union{AbstractString, AbstractVector{UInt8}})
    JSON3.read(str)
end

function write_to_file(filename, json_obj)
    open(filename, "w") do io
        JSON3.pretty(io, json_obj)
    end
end

end # module JSON

