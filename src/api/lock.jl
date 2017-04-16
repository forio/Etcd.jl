@client LocksClient

function uri(cli::LocksClient, lock::String)
    return "http://$(cli.host):$(cli.port)/mod/$(cli.version)/lock/$(lock)"
end

# blocking until lock is available
# TODO should add an async lock
function acquire(cli::LocksClient, lock::String, ttl::Int)
    return request(Requests.post, cli, lock, Dict("ttl" => ttl))
end

function renew(cli::LocksClient, lock::String, index::Int, ttl::Int)
    return request(Requests.put, cli, lock, Dict("index" => index, "ttl" => ttl))
end

function release(cli::LocksClient, lock::String, index::Int)
    return request(Requests.delete, cli, lock, Dict("index" => index))
end

function retrieve(cli::LocksClient, lock::String)
    return request(Requests.get, cli, lock, Dict("field" => "index"))
end
