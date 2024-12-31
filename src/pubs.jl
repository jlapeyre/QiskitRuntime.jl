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

abstract type AbstractPUB{CircT, ParamsT} end

"""
    SamplerPUB{CircT, ParamsT}

A [PUB](https://docs.quantum.ibm.com/guides/primitive-input-output#pubs) for the Sampler primitive.
"""
struct SamplerPUB{CircT, ParamsT, ST<:Union{Int, Nothing}} <: AbstractPUB{CircT, ParamsT}
    _circuit::CircT
    _params::ParamsT
    _num_shots::ST

    function SamplerPUB(circuit, params=nothing, num_shots=nothing)
        new{typeof(circuit), typeof(params), typeof(num_shots)}(circuit, params, num_shots)
    end
end

# FIXME: Do we want `validate` like the Python version has?
# FIXME: Use one of the struct helper macros in a package. QuickTypes maybe.
# What we have now is pretty verbose.
"""
    EstimatorPUB{CircT, ParamsT}

A [PUB](https://docs.quantum.ibm.com/guides/primitive-input-output#pubs) for the Estimator primitive.
"""
struct EstimatorPUB{CircT, ParamsT, ObsT} <: AbstractPUB{CircT, ParamsT}
    _circuit::CircT
    _observables::ObsT # a Vector, or do we need general Array?
    _params::ParamsT
    _precision::Float64

    function EstimatorPUB(circuit, observables, params=Any[], precision=0.0)
        new{typeof(circuit), typeof(params), typeof(observables)}(circuit, observables, params, precision)
    end
end

end # module PUBs
