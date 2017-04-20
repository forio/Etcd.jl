membersuri(cli::Client) = "http://$(cli.host):$(cli.port)/$(cli.version)/members"

function members(cli::Client)
    resp = request(Requests.get, membersuri(cli), Dict())
    return map(m -> m["id"] => m, resp["members"]) |> Dict
end
