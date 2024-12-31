module PUBs

export SamplerPUB, EstimatorPUB

## Primitive Unified Blocks (PUB)
## https://docs.quantum.ibm.com/guides/primitive-input-output#pubs

### May want to make an AbstractPrimitive, or some other organizational idea.

# May want to parameterize `num_shots` to allow it to be nothing.
# Or use some kind of `Option` type
# http://www.qiskit.org/schemas/sampler_v2_schema.json
# circuit: The quantum circuit in QASM string or base64-encoded QPY format.

# Primitive Unit Bloc of data Each PUB is of the form (Circuit, Parameters, Shots) where
# the circuit is required, parameters should be passed only for parametrized circuits, and
# shots is optional.


"""
    SamplerPUB{CircT, ParamsT}

A [PUB](https://docs.quantum.ibm.com/guides/primitive-input-output#pubs) for the Sampler primitive.
"""
struct SamplerPUB{CircT, ParamsT}
    circuit::CircT
    params::ParamsT
    num_shots::Int
end

"""
    EstimatorPUB{CircT, ParamsT}

A [PUB](https://docs.quantum.ibm.com/guides/primitive-input-output#pubs) for the Estimator primitive.
"""
struct EstimatorPUB{CircT, ParamsT, ObsT}
    circuit::CircT
    observables::Vector{ObsT}
    parameters::ParamsT
    precision::Float64
end

end # module PUBs
