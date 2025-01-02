# Set this at runtime so that it is not compiled in.
# function set_cache_dir_for_test()
#     set_env!(:QISKIT_RUNTIME_CACHE_DIR, joinpath(pkgdir(QiskitRuntime), "test", ".qiskit", "runtime_cache"))
# end

import Dates

@testset "Failed Job" begin
    job_id = JobId("dxv3sk6y1ae0008n6zbg")
    thejob = job(job_id)
    @test thejob.status == JobStatus'.Error
    @test thejob.user_id == UserId("ad23bc0732543df64f35cd12")
    @test isnothing(thejob.results)
    @test thejob.instance == Instance("the-hub/the-group/the-project")
    @test isa(thejob.tags, Vector{String})
    @test isempty(thejob.tags)
    @test thejob.end_date == Dates.DateTime("2025-01-02T07:14:23.636")
end

@testset "decoding" begin
    empty_ndarray = "eJyb7BfqGxDJyFDGUK2eklqcXKRupaBuk2ahrqOgnpZfVFKUmBefX5SSChJ3S8wpTtVRUC/OSCxIVbdS0DDQ0dRRqFWgAHABAFOzG1s="
    v = QiskitRuntime.Decode.decode_decompress_deserialize_numpy(empty_ndarray)
    @test isa(v, Vector{Float64})
    @test isempty(v)

    date_str = "2024-12-10T20:12:05.533Z"
    date_obj = QiskitRuntime.Decode.parse_response_datetime(date_str)
    @test date_obj == Dates.DateTime("2024-12-10T20:12:05.533")
end

@testset "SamplerPUBResult" begin
    job_id = JobId("na6gz6njpwihhasjfesi")
    job_result = Requests.results(job_id);
    @test job_result isa JSON3.Object
    @test Decode.is_typed_value(job_result)
    primitive_result = Decode.decode(job_result; job_id)
    @test primitive_result isa PrimitiveResult
    @test primitive_result.pub_results isa Vector{SamplerPUBResult}
    @test primitive_result.pub_results[1].data isa DataBin{<:NamedTuple}
    bit_array_alt = primitive_result.pub_results[1].data.fields.meas
    @test bit_array_alt isa BitArrayAlt{UInt8, 2}
    @test size(bit_array_alt) == (10, 4096)
    bit_arr2 = bit_array_alt[:, 1]

    # Following is not what we want. We want a slice to return the same kind of object,
    # and populated efficiently. But that will take work to implement for BitArrayAlt.
    # It may not be worth the effort. Instead, copy to Base.BitArray
    @test bit_arr2 isa Vector{Bool}
    @test bit_arr2 == Bool[0, 0, 1, 0, 1, 1, 0, 1, 0, 0]
end
