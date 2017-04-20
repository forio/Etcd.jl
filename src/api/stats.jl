function statsuri(cli::Client, stats_type::String)
    return "http://$(cli.host):$(cli.port)/$(cli.version)/stats/$(stats_type)"
end

function stats(cli::Client, stats_type::String)
    return request(Requests.get, statsuri(cli, stats_type), Dict())
end
