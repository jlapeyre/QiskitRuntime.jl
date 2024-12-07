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
    sitename = "QiskitRuntime",
    format = Documenter.HTML(),
    modules = [QiskitRuntime, QiskitRuntime.Requests],
    doctest = false, # Don't run tests. We run them when running unit tests instead.
    warnonly = true, # Don't fail on a lot of things, like missing doc strings.
    pages = [
        "Introduction" => "index.md",
        "Requests" => "requests.md",
    ],
    # Following disables remote links, which needs a publically accessible URL.
    # You must do this for a private github repo.
    remotes = nothing,
)

# Documenter can also automatically deploy documentation to gh-pages.
# See "Hosting Documentation" and deploydocs() in the Documenter manual
# for more information.
#=deploydocs(
    repo = "<repository url>"
)=#
