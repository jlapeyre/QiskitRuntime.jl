"""
    module API

This module determines what gets imported if you do `using QiskitRuntime`.

It works by importing the explicitly `export`ed symbols from each of several submodules
and then re-exporting them all. Alternatively, if you `use` one of the submodules, for
example `using QiskitRuntime.Jobs`, then only the symbols exported by that module will be
imported.

Note that submodule `Requests` is special. Its symbols conflict with the symbols exported
by submodules that implement a layer on REST requests. So to get the exported symbols from
`Requests`, you must explicitly do `using QiskitRuntim.Requests`.
"""
module API

using Reexport: Reexport

Reexport.@reexport using ..QiskitRuntime.Ids
Reexport.@reexport using ..QiskitRuntime.JSON
Reexport.@reexport using ..QiskitRuntime.Jobs
Reexport.@reexport using ..QiskitRuntime.Decode
Reexport.@reexport using ..QiskitRuntime.Accounts
Reexport.@reexport using ..QiskitRuntime.PauliOperators
Reexport.@reexport using ..QiskitRuntime.Backends
Reexport.@reexport using ..QiskitRuntime.PrimitiveResults
Reexport.@reexport using ..QiskitRuntime.Instances
Reexport.@reexport using ..QiskitRuntime.PUBs
Reexport.@reexport using ..QiskitRuntime.Circuits
Reexport.@reexport using ..QiskitRuntime.EnvVars

# Names in Requests and higher layers will conflict. So, we don't import most of these.
# Just a few...
Reexport.@reexport using ..QiskitRuntime.Requests: RuntimeServiceException, Requests

end #module API
