function keysuri(cli::Client, key::String)
    return "http://$(cli.host):$(cli.port)/$(cli.version)/keys$(key)"
end

function Base.get(cli::Client, key::String; sort::Bool=false, recursive::Bool=false)
    return get(cli, key, Dict{String, Any}(); sort=sort, recursive=recursive)
end

function Base.get(cli::Client, key::String, opts::Dict{String, Any}; sort::Bool=false, recursive::Bool=false)
    opts["sorted"] = sort
    opts["recursive"] = recursive
    opts = filter!((key, val) -> !isa(val, Bool) || val, opts)
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

function set(cli::Client, key::String, value::String; ttl::Int=-1, ordered=false)
    opts = Dict{String, Any}("value" => value)

    if ordered
        return post(cli, key, opts; ttl=ttl)
    else
        return put(cli, key, opts; ttl=ttl)
    end
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
