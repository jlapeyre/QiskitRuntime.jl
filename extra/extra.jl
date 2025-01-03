# You can load this with `include("./extra/extra.jl")`

# Say you are working with `QiskitRuntime` as the active environment.  Or with in another
# environment where you are using `QiskitRuntime`.  Load this file to make the listed
# packages available without polluting dependencies of any other packages.
#
# See help for `ExtraEnv`

using QiskitRuntime.ExtraEnvs

# You can add or remove packages from the list
env = ensure_in_stack("qkruntime_extra", [:PythonCall, :CondaPkg, :StatsBase])

# Note: if you add packages to the list above, you must call
# `update_env(env)`, or else add the packages to "qkruntime_extra" manually, using `Pkg`.
#
# The advantage of `ensure_in_stack` is that it is very fast if the environment
# exists and you do not want to change it.

# For convenience we import (or using) PythonCall after making it available.
using PythonCall

# You can't actually get at any symbols in PythonExt.jl, even if fully qualified.
# That's how extensions work. So one does the following.
# Import the symbols that will be "extended" by PythonExt.jl
using QiskitRuntime.Extensions

# There is probably some kind of behind-the-API trick to make this easier.
