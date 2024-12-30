# QiskitRuntime

[![](https://img.shields.io/badge/docs-dev-blue.svg)](https://jlapeyre.github.io/QiskitRuntime.jl/dev)
[![Build Status](https://github.com/jlapeyre/QiskitRuntime.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/jlapeyre/QiskitRuntime.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/jlapeyre/QiskitRuntime.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/jlapeyre/QiskitRuntime.jl)
[![Aqua QA](https://raw.githubusercontent.com/JuliaTesting/Aqua.jl/master/badge.svg)](https://github.com/JuliaTesting/Aqua.jl)

## Warnings

### If you use Python, this is the wrong repo. You want [ibm-qiskit-runtime](https://github.com/Qiskit/qiskit-ibm-runtime).

### **This software is not supported at all**. This software is experimental. 

### This software is an incomplete Julia-language front end to the IBM Quantum Platform, via the REST API.

## See the [documentation](https://jlapeyre.github.io/QiskitRuntime.jl/dev)

## This package

### Qiskit runtime service

Many functions, such as `job`, `jobs`, `user` take an optional argument `service`. If `service` is
omitted, then information will be taken from the user's config file `.qisit/qiskit-ibm.json`, or
environment variables. The environment variables will be preferred.

### Configuration file and environment variables

The file and variables are exactly the same as they are for the Python front end:
`.qisit/qiskit-ibm.json` and `QISKIT_IBM_CHANNEL`, `QISKIT_IBM_TOKEN`, `QISKIT_IBM_INSTANCE`,
 `QISKIT_IBM_URL`
 
Only one instance in `.qisit/qiskit-ibm.json` is supported.

### Layers

There are more or less two layers: An interface to the REST API, and a layer on top that returns data of native and cusom
Julia types.

### Caching

Caching is done at the level of entire REST API responses.

Reponses from several endpoints are cached automatically. They can be updated with `refresh=true`. For example
`Requests.job(job_id; refresh=true)`.

Functions in the upper layer also take the keyword argument `refresh` and pass it to the `Requests` layer. For example
`Jobs.job(job_id; refresh=true)`.

Caching is done by dumping the REST responses via JSON3 in `~/.qiskit/runtime_cache/`.

### Encoding/decoding

I don't see how to use an existing system. JSON3 has some support for controlling encoding, but I don't see how
to apply it here. For example, we have nested structures. Or maybe it can be applied.

In any case, at the moment, encoding and decoding is hardcoded. However, I do try to factor it out and collect
it in one place (utils.jl for now).

### Running circuits

The current focus of this package is to facilitate post-processing and further analysis in Julia. Support
for sending QASM3 circuits is (almost) finished. But I don't know if this will be very ergonomic. I don't
have plans to support qpy at the moment.

At some point, adding support for circuits via `PythonCall` should be easy. But I'd prefer to put that in another package or perhaps
an `Extension`.

### Tests

There are no tests.

Testing some parts with caching should be pretty easy. Some kind of mocking is probably necessary
to test the REST API calls.
<!--  LocalWords:  QiskitRuntime repo ibm qiskit
 -->
