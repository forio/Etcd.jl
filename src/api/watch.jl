function watch(
    f::Function, cli::Client, key::String;
    wait_index::Int=-1, recursive::Bool=false
)
    t = @async begin
        opts = Dict{String, Any}("wait" => true)

        if recursive
            opts["recursive"] = recursive
        end

        if wait_index > 0
            opts["waitIndex"] = wait_index
        end

        resp = get(cli, key, opts)
        f(resp)
    end

    return t
end

function watchloop(
    f::Function, cli::Client, key::String, wait_index::Int;
    recursive::Bool=false
)
    t = @async begin
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
            if isa(resp, Dict) && haskey(resp, "errorCode")
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
    end

    return t
end

function watchloop(f::Function, cli::Client, key::String; recursive::Bool=false)
    t = @async begin
        while true
            opts = Dict{String, Any}("wait" => true)

            if recursive
                opts["recursive"] = recursive
            end

            resp = get(cli, key, opts)
            f(resp)
        end
    end

    return t
end

function watchuntil(
    f::Function, cli::Client, key::String, p::Function;
    wait_index::Int=-1, recursive::Bool=false
)
    t = @async begin
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
    end

    return t
end
