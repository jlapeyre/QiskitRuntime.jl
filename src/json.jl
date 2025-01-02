module JSON

using JSON3

function read(str::Union{AbstractString,AbstractVector{UInt8}})
    return JSON3.read(str)
end

function write(dict::AbstractDict)
    return JSON3.write(dict)
end

function write_to_file(filename, json_obj)
    open(filename, "w") do io
        return JSON3.pretty(io, json_obj)
    end
end

# Ugh.
# JSON3.read tries to interpret a String parameter
# as either JSON or a filename. Because there is no
# good package/culture in Julia for filesytem path objects.
# I have started a package for this. But best to leave that aside
# at the moment.
function read_from_file(filename)
    return JSON3.read(filename)
end

end # module JSON
