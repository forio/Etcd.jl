#####################################
#            Machines               #
#####################################
machinesuri(cli::Client) = "http://$(cli.host):$(cli.port)/$(cli.version)/machines"

function machines(cli::Client)
    resp = request(Requests.get, machinesuri(cli), Dict())
    return map(strip, split(resp, ','))
end

#####################################
#           Stats                   #
#####################################
function statsuri(cli::Client, stats_type::String)
    return "http://$(cli.host):$(cli.port)/$(cli.version)/stats/$(stats_type)"
end

function stats(cli::Client, stats_type::String)
    return request(Requests.get, statsuri(cli, stats_type), Dict())
end

#####################################
#           Members                 #
#####################################
membersuri(cli::Client) = "http://$(cli.host):$(cli.port)/$(cli.version)/members"

function members(cli::Client)
    resp = request(Requests.get, membersuri(cli), Dict())
    return map(m -> m["id"] => m, resp["members"]) |> Dict
end

#####################################
#           Leaders                 #
#####################################
leaderuri(cli::Client) = "http://$(cli.host):$(cli.port)/$(cli.version)/stats/leader"

function leader(cli::Client)
    leader_id = request(Requests.get, leaderuri(cli), Dict())["leader"]
    return members(cli)[leader_id]
end

#####################################
#            Keys                   #
#####################################
function keysuri(cli::Client, key::String)
    return "http://$(cli.host):$(cli.port)/$(cli.version)/keys$(key)"
end

function Base.get(cli::Client, key::String; sort::Bool=false, recursive::Bool=false)
    opts = Dict{String, Any}("sorted" => sort, "recursive" => recursive)
    opts = filter!((key, val) -> val, opts)
    return request(Requests.get, keysuri(cli, key), opts)
end

function put(cli::Client, key::String, opts::Dict{String, Any}; ttl::Int=-1)
    if ttl > 0
        opts["ttl"] = ttl
    end

    return request(Requests.put, keysuri(cli, key), opts)
end

function post(cli::Client, key::String, opts::Dict{String, Any}; ttl::Int=-1)
    if ttl > 0
        opts["ttl"] = ttl
    end

    return request(Requests.post, keysuri(cli, key), opts)
end

function delete(cli::Client, key::String, opts::Dict{String, Any})
    return request(Requests.delete, keysuri(cli, key), opts)
end

function set(cli::Client, key::String, value::String; ttl::Int=-1)
    opts = Dict{String, Any}("value" => value)
    return put(cli, key, opts; ttl=ttl)
end

function setdir(cli::Client, key::String; ttl::Int=-1)
    opts = Dict{String, Any}("value" => "", "dir" => true)
    return put(cli, key, opts; ttl=ttl)
end

function create(cli::Client, key::String, value::String; ttl::Int=-1)
    opts = Dict{String, Any}("value" => value, "prevExist" => false)
    return put(cli, key, opts; ttl=ttl)
end

function update(cli::Client, key::String, value::String; ttl::Int=-1)
    opts = Dict{String, Any}("value" => value, "prevExist" => true)
    return put(cli, key, opts; ttl=ttl)
end

function createdir(cli::Client, key::String; ttl::Int=-1)
    opts = Dict{String, Any}("value" => "", "prevExist" => false, "dir" => true)
    return put(cli, key, opts; ttl=ttl)
end

function updatedir(cli::Client, key::String; ttl::Int=-1)
    opts = Dict{String, Any}("value" => "", "prevExist" => true, "dir" => true)
    return put(cli, key, opts; ttl=ttl)
end

function create_in_order(cli::Client, key::String, value::String; ttl::Int=-1)
     opts = Dict{String, Any}("value" => value)
     return post(cli, key, opts; ttl=ttl)
end

function add_child(cli::Client, key::String, value::String; ttl::Int=-1)
    return create_in_order(cli, key, value; ttl=ttl)
end

function create_in_order_dir(cli::Client, key::String; ttl::Int=-1)
    opts = Dict{String, Any}("value" => "")
    return post(cli, key, opts; ttl=ttl)
end

function add_child_dir(cli::Client, key::String; ttl::Int=-1)
    return create_in_order_dir(cli, key, ttl=ttl)
end

function exists(cli::Client, key::String)
    try
        Base.get(cli, key)
        return true
    catch err
        # expect "Key not found"(100) error
        if err.resp["errorCode"] == 100
            return false
        else
            rethrow()
        end
    end
end

Base.haskey(cli::Client, key::String) = exists(cli, key)

delete(cli::Client, key::String) = delete(cli, key, Dict())

function deletedir(cli::Client, key::String; recursive::Bool=false)
    opts = Dict{String, Any}("dir" => true, "recursive" => recursive)
    delete(cli, key, filter!((k,v)->v, opts))
end

function cad(
    cli::Client, key::String;
    prev_value::Union{String, Void}=nothing, prev_index::Int=-1,
)
    opts = Dict{String, Any}()
    if !is(prev_value, nothing)
       opts["prevValue"] = prev_value
    end

    if prev_index > 0
       opts["prevIndex"] = prev_index
    end

    return delete(cli, key, opts)
end

function cas(
    cli::Client, key::String, value::String;
    prev_value::Union{String, Void}=nothing, prev_index::Int=-1, ttl::Int=-1
)
    opts = Dict{String, Any}("value" => value)

    if !is(prev_value, nothing)
       opts["prevValue"] = prev_value
    end

    if prev_index > 0
       opts["prevIndex"] = prev_index
    end

    return put(cli, key, opts; ttl=ttl)
end

function watch(
    f::Function, cli::Client, key::String;
    wait_index::Int=-1, recursive::Bool=false
)
    @async begin
        try
            opts = Dict{String, Any}("wait" => true)

            if recursive
                opts["recursive"] = recursive
            end

            if wait_index > 0
                opts["waitIndex"] = wait_index
            end

            resp = get(cli, key, opts)
            return f(resp)
        catch err
            warn("watch failed $err for key $key")
        end
    end
end

function watchloop(
    f::Function, cli::Client, key::String, wait_index::Int;
    recursive::Bool=false
)
    @async begin
        try
            while true
                opts = Dict{String, Any}(
                    "wait" => true,
                    "waitIndex" => wait_index
                )

                if recursive
                    opts["recursive"] = recursive
                end

                resp = get(cli, key, opts)
                resp = try
                    JSON.parse(resp)
                catch err
                    resp
                end

                # we handle the error here, since it provides us with the
                # current index
                if isa(resp, Dict) && haskey(resp,"errorCode")
                    # extract index
                    if haskey(resp,"index")
                        wait_index = resp["index"] + 1
                    else
                        err_code = resp["errorCode"]
                        reason = get(ETCD_ERRORS, err_code, "Unknown Error")
                        warn("Request Failed ($(err_code)): $reason")
                        break
                    end
                elseif !isa(resp, Void)
                    f(resp)
                    wait_index = maximum([
                        Base.get(resp["node"],"createdIndex",0),
                        Base.get(resp["node"],"modifiedIndex",0),
                        wait_index
                    ])
                    wait_index += 1
                end
            end
        catch err
            warn("keep_watching_index failed $err for key $key")
        end
    end
end

function watchloop(f::Function, cli::Client, key::String; recursive::Bool=false)
    @async begin
        try
            while true
                opts = Dict{String, Any}("wait" => true)

                if recursive
                    opts["recursive"] = recursive
                end

                resp = get(cli, key, opts)
                f(resp)
            end
        catch err
            warn("keep_watching failed $err for key $key")
        end
    end
end

function watchuntil(
    f::Function, cli::Client, key::String, p::Function;
    wait_index::Int=-1, recursive::Bool=false
)
    @async begin
        try
            while true
                opts = Dict{String, Any}("wait" => true)

                if recursive
                    opts["recursive"] = recursive
                end

                if wait_index > 0
                    opts["waitIndex"] = wait_index
                end

                resp = get(cli, key, opts)
                f(resp)

                if p(resp)
                    break
                end

                if wait_index > 0
                    wait_index += 1
                end
            end
        catch err
            warn("watch_until failed $err for key $key")
        end
    end
end
