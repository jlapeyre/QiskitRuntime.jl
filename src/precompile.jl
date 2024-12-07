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
        job.(jobids)
        results.(jobids)
        nothing
    end
end
