@client StatsClient

function uri(cli::StatsClient, stats_type::String)
    return "http://$(cli.host):$(cli.port)/$(cli.version)/stats/$(stats_type)"
end

function stats(cli::StatsClient, stats_type::String)
    if stats_type != "leader" &&
       stats_type != "self" &&
       stats_type != "store"
        warn("Stats : Must specify the stats_type to be one of: leader, self or store")
    else
        request(Requests.get, cli, stats_type, Dict())
    end
end
