machinesuri(cli::Client) = "http://$(cli.host):$(cli.port)/$(cli.version)/machines"

function machines(cli::Client)
    resp = request(Requests.get, machinesuri(cli), Dict())
    return map(strip, split(resp, ','))
end
