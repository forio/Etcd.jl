module Etcd

using Requests

abstract AbstractClient

macro client(name)
    return quote
        immutable $name <: AbstractClient
            host::String
            port::Int
            version::String
        end
    end
end

include("constants.jl")
include("requests.jl")
include("api.jl")
include("utils.jl")

global const ETCD_CLIENTS = Dict(
    :machines => MachinesClient,
    :keys => KeysClient,
    :leaders => LeadersClient,
    :locks => LocksClient,
    :stats => StatsClient,
)

function connect(client::Symbol, ip::String="localhost", port::Int=2379, version="v2")
    return ETCD_CLIENTS[client](ip, port, version)
end

export machines, set, create, update, setdir, createdir, updatedir, cas, cad, EtcdError

end # module
