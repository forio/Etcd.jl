using Requests
using Lumberjack

include("constants.jl")

type EtcdServer
    ip::IPv4
    port::Int
    get::Function
    set::Function
    set_dir::Function
    create_dir::Function
    update_dir::Function
    create::Function
    update::Function
    create_in_order::Function
    create_in_order_dir::Function
    exists::Function
    delete::Function
    delete_dir::Function
    compare_and_delete::Function
    compare_and_swap::Function
    watch::Function
end

function EtcdServer(ip::String="127.0.0.1",port::Int=4001)
    keys_prefix = "http://$(ip):$(port)/v2/keys"

    EtcdServer(parseip(ip),port,
               function get(key::String;sort::Bool=false,recursive::Bool=false)
                   _get(string(keys_prefix,key),
                        {"sorted"=>sort,"recursive"=>recursive})
               end,
               function set(key::String,value::String;ttl=nothing)
                   _set(string(keys_prefix,key),{"value"=>value,
                                                 "ttl"=>ttl})
               end,
               function set_dir(key::String;ttl=nothing)
                   _set(string(keys_prefix,key),{"value"=>"",
                                                 "ttl"=>ttl,
                                                 "dir"=>true})
               end,
               function create_dir(key::String;ttl=nothing)
                   _set(string(keys_prefix,key),{"value"=>"",
                                                 "ttl"=>ttl,
                                                 "prevExist"=>false,
                                                 "dir"=>true})
               end,
               function update_dir(key::String;ttl=nothing)
                   _set(string(keys_prefix,key),{"value"=>"",
                                                 "ttl"=>ttl,
                                                 "prevExist"=>true,
                                                 "dir"=>true})
               end,
               function create(key::String,value::String;ttl=nothing)
                   _set(string(keys_prefix,key),{"value"=>value,
                                                 "ttl"=>ttl,
                                                 "prevExist"=>false})
               end,
               function update(key::String,value::String;ttl=nothing)
                   _set(string(keys_prefix,key),{"value"=>value,
                                                 "ttl"=>ttl,
                                                 "prevExist"=>true})
               end,
               function create_in_order(key::String,value::String;ttl=nothing)
                   _in_order(string(keys_prefix,key),{"value"=>value,
                                                      "ttl"=>ttl})
               end,
               function create_in_order_dir(key::String;ttl=nothing)
                   _in_order(string(keys_prefix,key),{"value"=>"",
                                                      "ttl"=>ttl})
               end,
               function exists(key::String)
                   _get(string(keys_prefix,key)) |> (rsp)->haskey(rsp,"errorCode")
               end,
               # handle error when trying to non-empty dir without specifying
               # recursive etc
               function delete(key::String)
                    _delete(string(keys_prefix,key),{"recursive"=>false,
                                                     "dir"=>false})
               end,
               function delete_dir(key::String,recursive::Bool=false)
                    _delete(string(keys_prefix,key),{"recursive"=>recursive,
                                                     "dir"=>true})
               end,
               function compare_and_delete(key::String,
                                           prev_value::Union(String,Nothing)=nothing,
                                           prev_index::Union(Int,Nothing)=nothing)
                    if is(prev_value,nothing) && is(prev_index,nothing)
                        warn("Have to specify either prev_value or prev_index")
                    else
                        _delete(string(keys_prefix,key),{"prevValue"=>prev_value,
                                                         "prevIndex"=>prev_index})
                    end
               end,
               function compare_and_swap(key::String,value::String,
                                         prev_value::String,prev_index::Uint64,
                                         ttl=nothing)
               end,
               function watch(key::String,cb::Function;wait_index::Union(Int,Bool)=false,
                              recursive::Bool=false)
                   @async begin
                       cb(_get(string(keys_prefix,key),
                               {"wait"=>true,"recursive"=>recursive,
                                "waitIndex"=>wait_index}))
                   end
               end)
end

function _get(key::String,options=Dict{String,Bool}())
    debug("Etcd get called with:",{:key => key, :options => options})
    filter!((k,v)->v,options)
    try
        if isempty(options)
            rsp = get(key)
        else
            rsp = get(key,query=options)
        end
        rsp.data |> JSON.parse
    catch err
        warn("GET Request to server failed with $err")
    end
end

function _set(key::String,options=Dict{String,Any}())
    debug("Etcd set called with:",{:key => key, :options => options})
    filter!((k,v)->!is(v,nothing),options)
    try
        rsp = put(key,query=options)
        rsp.data |> JSON.parse
    catch err
        warn("PUT Request to server failed with $err")
    end
end

function _in_order(key::String,options=Dict{String,Any}())
    debug("Etcd inorder called with:",{:key => key, :options => options})
    filter!((k,v)->!is(v,nothing),options)
    try
        rsp = post(key,query=options)
        rsp.data |> JSON.parse
    catch err
        warn("POST Request to server failed with $err")
    end
end

function _delete(key::String,options=Dict{String,Any}())
    debug("Etcd delete called with:",{:key => key, :options => options})
    filter!((k,v)->v,options)
    try
        if isempty(options)
            rsp = delete(key)
        else
            rsp = delete(key,query=options)
        end
        rsp.data |> JSON.parse
    catch err
        warn("DELETE Request to server failed with $err")
    end
end

function error(rsp)
    if haskey(rsp,"errorCode")
        ec = rsp["errorCode"]
        warn("Request failed with error code $(ec)",
             {:reason => get(etcd_errors,ec,"Unknown Error")})
    end
end

