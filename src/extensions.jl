"""
    module Extensions

Define symbols that will be used by package extensions, such as `./ext/PythonExt.jl`.

I don't see an easier way to do this.  The package extension system was designed for rather
quirky and narrow use cases. (Maybe it had to be that way?) It is meant to add additional
methods to existing functions in your main module. Of course many, or most, cases of
conditional dependency don't fit this model.

So we define symbols here that are then imported in the extensions. The symbols here in `Extensions`
are *not* exported when doing `using QiskitRuntime`. You must do `using  QiskitRuntime.Extensions` or
otherwise import them piecemeal.
"""
module Extensions

export qk, qr

function qk end
function qr end

end  # module Extensions
