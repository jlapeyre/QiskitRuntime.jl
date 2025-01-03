module PythonExt

using QiskitRuntime
import QiskitRuntime.Extensions: qk, qr, encode_circuit, QuantumCircuitT

using PythonCall: PythonCall, @pyconst, pyimport, pyconvert,
    pytype

qk() = @pyconst(pyimport("qiskit"))
qr() = @pyconst(pyimport("qiskit_ibm_runtime"))


QuantumCircuitT() = @pyconst(pyimport("qiskit")).QuantumCircuit

# See https://github.com/Qiskit/qiskit-ibm-runtime/blob/0f345d847c5db22d7e3ffc1836e25a1bdc098f27/qiskit_ibm_runtime/utils/json.py#L260-L269
"""
    encode_circuit(circuit)::String

qpy-serialize, compress, and bas64 encode the `circuit`

`circuit` is a `Py` `QuantumCircuit`. The resulting string
is suitable for sending to the REST API.
"""
function encode_circuit(circuit)
    pyio = pyimport("io")
    zlib = pyimport("zlib")
    base64 = pyimport("base64")
    qk = pyimport("qiskit")
    qpy = pyimport("qiskit.qpy")
    # Must send version 11 qpy to the server
    qpy_version = 11
    buff = pyio.BytesIO()
    # "Serialize" `circuit` as qpu, write to `buff`
    qpy.dump(circuit, buff; version=qpy_version)
    buff.seek(0)
    # get array of bytes
    serialized_data = buff.read()
    # zlib compress
    serialized_data = zlib.compress(serialized_data)
    # bas64 encoded as Pthon `str`
    encoded = base64.standard_b64encode(serialized_data).decode("utf-8")
    return pyconvert(String, encoded)
end

end # module PythonExt
