using PrecompileTools: @setup_workload, @compile_workload

@setup_workload begin
    # Putting some things in `setup` can reduce the size of the
    # precompile file and potentially make loading faster.
    nothing
    using QiskitRuntime: cached_jobs, results, job
    @compile_workload begin
        # all calls in this block will be precompiled, regardless of whether
        # they belong to your package or not (on Julia 1.8 and higher)
        jobids = cached_job_ids()
        jobsall = job.(jobids)
        resultsall = results.(jobids)
        io = IOBuffer()
        for j in jobsall
            show(io, MIME"text/plain"(), j)
            string(j)
        end
        for r in resultsall
            show(io, MIME"text/plain"(), r)
            string(r)
        end
        # This is cached as well
        uinf = user_info()
        show(io, MIME"text/plain"(), uinf)
        show(io, uinf)
        string(uinf)
        nothing
    end
end
