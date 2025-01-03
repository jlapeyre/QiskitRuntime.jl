# Using PythonCall and other packages

There are a few ways to try to conveniently use packages that are not
dependencies of `QiskitRuntime`. (Or of any other package you want to use)

You can dump all of the desired packages in your default environment. But this is widely
discouraged, for good reasons. If you are relatively new to Julia, you will surely ignore
this advice and add packages in whatever environment you happen to be in. Eventually,
version conflicts, long load and compile times, and failed compilation will become more
trouble than the convenience is worth.

We provide [`QiskitRuntime.ExtraEnvs`](@ref), which
is meant to manage extra packages. The most important is `PythonCall` for communicating with Python.
I'll explain how to use it below.

## PythonCall for Python langauge [Qiskit](https://github.com/Qiskit) packages

We want to use the Python language packages [qiskit](https://github.com/Qiskit/qiskit) (the Qiskit SDK) and
[qiskit-ibm-runtime](https://github.com/Qiskit/qiskit-ibm-runtime) (the Qiskit Runtime IBM Client).

### Setting up a Python environment

`PythonCall` can completely manage your Python environment, installing Python and required packages using
its own robust system, avoiding things like `pip` altogether.
You might not want to use this, for a couple of reasons.

* The last time I tried this, I found it rather heavy and obtrusive. For example, it silently and without prompting began to download a Python distribution, binary and all. Howver, my imperfect understanding is that in the meantime, the author has added more flexibility and ergonomics.
* `QiskitRuntime` is not meant to completely hide the Python from the user and only expose Julia. In fact most people using `QiskitRuntime` will be very familiar with qiskit and qiskit-ibm-runtime. And they know how to manage a Python environment that includes these packages and various other supporting packages particular to the user.

### Manage the Python environment yourself

In order to prevent PythonCall from installing Python and a bunch of other stuff
set the environment variable `JULIA_CONDAPKG_BACKEND`. For example, from within Julia:

```julia
ENV["JULIA_CONDAPKG_BACKEND"] = "Null"
```

Then, do something like

* `python -m venv ./venvs/py312` to set up an environment.
* activate the environment
* add at least `qiskit` and `qiskit-ibm-runtime` to the environment.
* Start a Julia REPL (or notebook, etc) from a shell with the Python environment activated.

### Let PythonCall manage the environment

Unset `JULIA_CONDAPKG_BACKEND` if you have set it. The file [./CondaPkg.toml](https://github.com/jlapeyre/QiskitRuntime.jl/blob/main/CondaPkg.toml) specifies that `PythonCall`, via `CondaPkg` should install qiskit and qiskit-ibm-runtime. See the `CondaPkg` docs for how to add more.

!!! warning
    I tried using `PythonCall/CondaPkg`. I can `pyimport("qiskit")`. But not `qiskit-ibm-runtime`.
    There is some binary incompatibility involving openssl.
    There are several GH issues on the `PythonCall` and `CondaPkg` repos.
    And the problem is apparetnly "solved".
    But it was not immediately obvious to me how to successfully `pyimport("qiskit-ibm-runtime")`.

### Loading PythonCall

Assuming you have set up you environment using one of the methods above (or another method),
you can now load `PythonCall` as follows (or use another method if you prefer)

Read the file [`./extra/extras.jl`](https://github.com/jlapeyre/QiskitRuntime.jl/blob/main/extra/extra.jl).
Add or remove packages from the list. Then do `include("./extra/extras.jl")`.  The packages in the list
will then be available without polluting any `Project.toml`s or dependency lists. Furthemore, `PythonCall`
will be loaded, and the extension [`./ext/PythonExt.jl`](https://github.com/jlapeyre/QiskitRuntime.jl/blob/main/ext/PythonExt.jl) will be loaded as well.

You should be able to do this (depending on if and how you edit extra.jl).

```julia-repl
julia> using Revise; using QiskitRuntime;

julia> include("extra/extra.jl");

julia> circ = qk().QuantumCircuit(2); circ.cx(0, 1); print(circ)

q_0: ──■──
     ┌─┴─┐
q_1: ┤ X ├
     └───┘
```

Using `qr()` and `qk()` is not super convenient. But you can't do `using QiskitRuntime.SomeModule: qk, qr` to
get handles to the modules. Still there could be an easier way.

!!! note
    Using the `Pkg` package extension features is sort of convenient at the moment. But we will
    likely instead make a second Julia package that properly depends on both `QiskitRuntime.jl` and
    `PythonCall.jl`.


```@raw html
<!--  LocalWords:  PythonCall QiskitRuntime ExtraEnvs toml julia ENV CONDAPKG BACKEND
 -->
```
