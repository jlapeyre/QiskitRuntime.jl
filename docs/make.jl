using Documenter

# This may be a red herring, since, for practical purposes, you have to dev the
# packge anyway.
push!(LOAD_PATH, "..")

# You *must* `pkg> dev path/to/this/package`
using QiskitRuntime

# This sets current module for running doc tests.
# We want to set it to the top-level module.
Documenter.DocMeta.setdocmeta!(QiskitRuntime, :DocTestSetup, :(using QiskitRuntime); recursive=true)

makedocs(
    sitename = "QiskitRuntime.jl",
    format = Documenter.HTML(),
    modules = [QiskitRuntime, QiskitRuntime.Requests],
    doctest = false, # Don't run tests. We run them when running unit tests instead.
    warnonly = [:missing_docs], # Don't fail on a lot of things, like missing doc strings.
    authors = "John Lapeyre",
    pages = [
        "Introduction" => "index.md",
        "Tutorial" => "tutorial.md",
        "Accounts" => "accounts.md",
        "Environment Variables" => "env_vars.md",
        "Requests" => "requests.md",
        "Id Numbers and Tokens" => "ids.md",
        "Development notes" => "dev_notes.md",
        "Index" => "theindex.md",
    ],
    # Following disables remote links, which needs a publically accessible URL.
    # You must do this for a private github repo.
    # remotes = nothing,
    # Following prob not neccesary if remotes=nothing not present
    # repo = Documenter.Remotes.GitHub("jlapeyre", "QiskitRuntime.jl"),
)

# Documenter can also automatically deploy documentation to gh-pages.
# See "Hosting Documentation" and deploydocs() in the Documenter manual
# for more information.
deploydocs(
    repo = "github.com/jlapeyre/QiskitRuntime.jl.git"
)
