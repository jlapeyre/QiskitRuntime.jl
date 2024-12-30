using QiskitRuntime

# This code is meant for running the doctests from the Julia REPL
# Or as a script.
# For example:
# julia> include("rundoctests.jl")

try
    DocMeta
catch
    using Documenter; DocMeta.setdocmeta!(QiskitRuntime, :DocTestSetup, :(using QiskitRuntime); recursive=true);
end

function clean_env()
    for k in ("QISKIT_CONFIG_DIR", "QISKIT_IBM_TOKEN", "QISKIT_IBM_INSTANCE")
        if !isnothing(get(ENV, k, nothing))
            delete!(ENV, "QISKIT_CONFIG_DIR")
        end
    end
end

clean_env()

ENV["QISKIT_CONFIG_DIR"] = joinpath(pkgdir(QiskitRuntime), "test", ".qiskit")

try
    Documenter.doctest(QiskitRuntime)
catch
    println("Doc tests failed")
end

clean_env()

nothing;
