
# Set this at runtime so that it is not compiled in.
function set_cache_dir_for_test()
    ENV["QISKIT_RUNTIME_CACHE_DIR"] = joinpath(pkgdir(QiskitRuntime), "test", "runtime_cache")
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

@testset "SamplerPubResult" begin
    job_id = "cxd2zbxtpsjg0083m72g"
    set_cache_dir_for_test()
    job_result = Requests.results(job_id);
    @test job_result isa JSON3.Object
    @test Decode.is_typed_value(job_result)
    primitive_result = Decode.decode(job_result)
    @test primitive_result isa PrimitiveResult
    @test primitive_result.pub_results isa Vector{SamplerPubResult}
    @test primitive_result.pub_results[1].data isa DataBin{<:NamedTuple}
    bit_array_alt = primitive_result.pub_results[1].data.fields.meas
    @test bit_array_alt isa BitArrayAlt{UInt8, 2}
    @test size(bit_array_alt) == (10, 4096)
    bit_arr2 = bit_array_alt[:, 1]

    # Following is not what we want. We want a slice to return the same kind of object,
    # and populated efficiently. But that will take work to implement for BitArrayAlt.
    # It may not be worth the effort. Instead, copy to Base.BitArray
    @test bit_arr2 isa Vector{Bool}

    @test bstring(bit_arr2) == "0010110100"
end
