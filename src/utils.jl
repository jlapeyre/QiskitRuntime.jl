module Utils

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
            show(io, MIME"text/plain"(), subobj)
        end
        if n != length(fnames)
            showfunc(io, ", ")
        end
        if newlines
            println(io)
        end
    end
    showfunc(io, outer_indent_str, ")")
end

end # module Utils
