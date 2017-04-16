@client MachinesClient

function uri(cli::MachinesClient)
    return "http://$(cli.host):$(cli.port)/$(cli.version)/machines"
end

function machines(cli::MachinesClient)
    return request(Requests.get, uri(cli), Dict())
end

api_path = joinpath(dirname(@__FILE__), "api")

for file in ("keys.jl", "leader.jl", "lock.jl", "stats.jl")
    include(joinpath(api_path, file))
end
