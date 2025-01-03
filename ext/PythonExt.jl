module PythonExt

using QiskitRuntime
import QiskitRuntime.Extensions: qk, qr

using PythonCall: PythonCall, @pyconst, pyimport

qk() = @pyconst(pyimport("qiskit"))
qr() = @pyconst(pyimport("qiskit_ibm_runtime"))

"""
    encode_circuit(circ)


"""
function encode_circuit(circ)
    pyio = pyimport("io")
    zlib = pyimport("zlib")
    base64 = pyimport("base64")

    buff = pyio.BytesIO()
    qk.qpy.dump(circ, buff; version=11)
    buff.seek(0)
    serialized_data = buff.read()
    serialized_data = zlib.compress(serialized_data)
    encoded = base64.standard_b64encode(serialized_data).decode("utf-8")
    return pyconvert(String, encoded)
end


end # module PythonExt
