# QiskitRuntime.jl

!!! warning
    This documentation is **not** for the standard client [qiskit-ibm-runtime](https://github.com/Qiskit/qiskit-ibm-runtime) to
    the [Qiskit Runtime REST API](https://docs.quantum.ibm.com/api/runtime)

    To find information on the easiest, best, way to use the Qiskit Runtime use this link:

    [qiskit-ibm-runtime](https://github.com/Qiskit/qiskit-ibm-runtime)

    The documentation you are reading now is only for the **highly experimental Julia-language** client, not for the
    [Python-langauge client](https://github.com/Qiskit/qiskit-ibm-runtime).

!!! warning
    Documentation pages for `QiskitRuntime.jl` are a WIP.

```@meta
DocTestSetup = quote
    using QiskitRuntime
end
```

## Contents

The contents are jumbled and out of order. Documenter is difficult.

```@contents
Depth = 2
```

## Introduction

```@meta
DocTestSetup = quote
  ENV["QISKIT_CONFIG_DIR"] = joinpath(pkgdir(QiskitRuntime), "test", ".qiskit")
end
```

```@autodocs
Modules = [QiskitRuntime]
```

## Jobs

```@autodocs
Modules = [QiskitRuntime.Jobs]
```

## Backends

```@autodocs
Modules = [QiskitRuntime.Backends]
```

## Accounts

```@autodocs
Modules = [QiskitRuntime.Accounts]
```

```@meta
DocTestSetup = quote
    delete!(ENV, "QISKIT_IBM_TOKEN")
    delete!(ENV, "QISKIT_IBM_INSTANCE")
end
```

## Instances

```@autodocs
Modules = [QiskitRuntime.Instances]
```

```@meta
DocTestSetup = quote
    delete!(ENV, "QISKIT_CONFIG_DIR")
end
```

```@meta
DocTestSetup = nothing
```

## PUBs

```@autodocs
Modules = [QiskitRuntime.PUBs]
```



# Index
```@index
```
