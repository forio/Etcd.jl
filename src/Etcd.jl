module Etcd

using Requests
import HttpCommon: Response

immutable Client
    host::String
    port::Int
    version::String
end

include("constants.jl")
include("requests.jl")
include("api.jl")
include("utils.jl")

function connect(host::String="localhost", port::Int=2379, version="v2")
    return Client(host, port, version)
end

export
    # methods
    machines,
    stats,
    members,
    leader,
    set,
    create,
    update,
    setdir,
    createdir,
    updatedir,
    delete,
    cas,
    cad,
    watch,
    watchloop,
    watchuntil,

    # Types
    HTTPError,
    EtcdError

end # module
