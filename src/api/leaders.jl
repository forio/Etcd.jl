leaderuri(cli::Client) = "http://$(cli.host):$(cli.port)/$(cli.version)/stats/leader"

function leader(cli::Client)
    leader_id = request(Requests.get, leaderuri(cli), Dict())["leader"]
    return members(cli)[leader_id]
end
