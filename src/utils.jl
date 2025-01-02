module Utils

# Convert an object to a data structure that JSON3 will convert
# to JSON to make a REST API request
function api_data_structure end

function wantfancyshow(::Type{T}) where {T}
    return false
end

# Show object optionally with field_names and newlines between fields.
function _show(io::IO, object; field_names=true, newlines=false, indent=0) # printfields::Bool=false)
    T = typeof(object)
    fnames = fieldnames(T)

    outer_indent_str = " "^indent
    inner_indent = 2 + indent
    showfunc = print
    showfunc(io, outer_indent_str, T, "(")
    if newlines
        println(io)
    end
    for (n, field) in enumerate(fnames)
        newlines && showfunc(io, " "^inner_indent)
        if field_names
            showfunc(io, field, " = ")
        end
        subobj = getproperty(object, field)
        if isa(subobj, Array)
            print(io, subobj)
        else
            if wantfancyshow(typeof(subobj))
                _show(io, subobj; field_names, newlines, indent=inner_indent)
            else
                show(io, MIME"text/plain"(), subobj)
            end
        end
        if n != length(fnames)
            if newlines
                showfunc(io, ",")
            else
                showfunc(io, ", ")
            end
        end
        if newlines
            println(io)
        end
    end
    return showfunc(io, outer_indent_str, ")")
end

end # module Utils
