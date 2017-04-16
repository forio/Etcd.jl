@client LeadersClient

function uri(cli::LeadersClient, leader::String)
    return "http://$(cli.host):$(cli.port)/mod/$(cli.version)/leader/$(leader)"
end

function get(cli::LeadersClient, leader::String)
    return request(Requests.get, cli, leader, Dict())
end

function set(cli::LeadersClient, leader::String, name::String, ttl::Int)
    opts = Dict("name" => name, "ttl" => ttl)
    return request(Requests.put, cli, leader, opts)
end

function delete(cli::LeadersClient, leader::String, name::String)
    return request(Requests.delete, cli, leader, Dict("name" => name))
end
