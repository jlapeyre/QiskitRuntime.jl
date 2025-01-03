module PythonExt

using QiskitRuntime
import QiskitRuntime.Extensions: qk, qr

using PythonCall: PythonCall, @pyconst, pyimport

qk() = @pyconst(pyimport("qiskit"))
qr() = @pyconst(pyimport("qiskit_ibm_runtime"))

end # module PythonExt
