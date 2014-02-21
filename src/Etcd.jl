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

function check_etcd_error(etcd_response)
    if haskey(etcd_response,"errorCode")
        ec = etcd_response["errorCode"]
        warn("Request failed with error code $(ec)",
             {:reason => get(etcd_errors,ec,"Unknown Error")})
    end
    etcd_response
end

function EtcdServer(ip::String="127.0.0.1",port::Int=4001)
    # version 2 XXX
    keys_prefix = "http://$(ip):$(port)/v2/keys"

    EtcdServer(parseip(ip),port,
               function get(key::String;sort::Bool=false,recursive::Bool=false)
                   etcd_request(Requests.get,string(keys_prefix,key),
                                filter((k,v)->v,
                                       {"sorted"=>sort,"recursive"=>recursive})) |>
                   check_etcd_error
               end,
               function set(key::String,value::String;ttl::Union(Int,Nothing)=nothing)
                   etcd_request(Requests.put,string(keys_prefix,key),
                                filter((k,v)->!is(v,nothing),
                                       {"value"=>value,"ttl"=>ttl})) |>
                   check_etcd_error
               end,
               function set_dir(key::String;ttl::Union(Int,Nothing)=nothing)
                   etcd_request(Requests.put,string(keys_prefix,key),
                                filter((k,v)->!is(v,nothing),
                                       {"value"=>"","ttl"=>ttl,"dir"=>true})) |>
                   check_etcd_error
               end,
               function create_dir(key::String;ttl::Union(Int,Nothing)=nothing)
                   etcd_request(Requests.put,string(keys_prefix,key),
                                filter((k,v)->!is(v,nothing),
                                       {"value"=>"","ttl"=>ttl,
                                        "prevExist"=>false,"dir"=>true})) |>
                   check_etcd_error
               end,
               function update_dir(key::String;ttl::Union(Int,Nothing)=nothing)
                   etcd_request(Requests.put,string(keys_prefix,key),
                                filter((k,v)->!is(v,nothing),
                                       {"value"=>"","ttl"=>ttl,
                                        "prevExist"=>true,"dir"=>true})) |>
                   check_etcd_error
               end,
               function create(key::String,value::String;ttl::Union(Int,Nothing)=nothing)
                   etcd_request(Requests.put,string(keys_prefix,key),
                                filter((k,v)->!is(v,nothing),
                                       {"value"=>value,"ttl"=>ttl,
                                        "prevExist"=>false})) |>
                   check_etcd_error
               end,
               function update(key::String,value::String;ttl::Union(Int,Nothing)=nothing)
                   etcd_request(Requests.put,string(keys_prefix,key),
                                filter((k,v)->!is(v,nothing),
                                       {"value"=>value,"ttl"=>ttl,
                                        "prevExist"=>true})) |>
                   check_etcd_error
               end,
               function create_in_order(key::String,value::String;
                                        ttl::Union(Int,Nothing)=nothing)
                   etcd_request(Requests.post,string(keys_prefix,key),
                                filter((k,v)->!is(v,nothing),
                                       {"value"=>value,"ttl"=>ttl})) |>
                   check_etcd_error
               end,
               function create_in_order_dir(key::String;ttl::Union(Int,Nothing)=nothing)
                   etcd_request(Requests.post,string(keys_prefix,key),
                                filter((k,v)->!is(v,nothing),
                                       {"value"=>"","ttl"=>ttl})) |>
                   check_etcd_error
               end,
               function exists(key::String)
                   etcd_request(Requests.get,string(keys_prefix,key)) |>
                   (rsp)->haskey(rsp,"errorCode")
               end,
               function delete(key::String)
                   etcd_request(Requests.delete,string(keys_prefix,key)) |>
                   check_etcd_error
               end,
               function delete_dir(key::String,recursive::Bool=false)
                   etcd_request(Requests.delete,string(keys_prefix,key),
                                filter((k,v)->v,
                                       {"dir"=>true,"recursive"=>recursive})) |>
                   check_etcd_error
               end,
               function compare_and_delete(key::String,
                                           prev_value::Union(String,Nothing)=nothing,
                                           prev_index::Union(Int,Nothing)=nothing)
                   if is(prev_value,nothing) && is(prev_index,nothing)
                       warn("Have to specify either prev_value or prev_index")
                   else
                       etcd_request(Requests.delete,string(keys_prefix,key),
                                    filter((k,v)->!is(v,nothing),
                                           {"prevValue"=>prev_value,
                                            "prevIndex"=>prev_index})) |>
                       check_etcd_error
                    end
               end,
               function compare_and_swap(key::String,value::String,
                                         prev_value::Union(String,Nothing)=nothing,
                                         prev_index::Union(Int,Nothing)=nothing,
                                         ttl::Union(Int,Nothing)=nothing)
                   if is(prev_value,nothing) && is(prev_index,nothing)
                       warn("Have to specify either prev_value or prev_index")
                   else
                       etcd_request(Requests.put,string(keys_prefix,key),
                                    filter((k,v)->!is(v,nothing),
                                           {"value"=>value,
                                            "prevValue"=>prev_value,
                                            "prevIndex"=>prev_index,
                                            "ttl"=>ttl})) |>
                       check_etcd_error
                    end
               end,
               function watch(key::String,cb::Function;
                              wait_index::Union(Int,Bool)=false,
                              recursive::Bool=false)
                   @async begin
                       etcd_request(Requests.get,string(keys_prefix,key),
                                    filter((k,v)->v,
                                           {"wait"=>true,
                                            "recursive"=>recursive,
                                            "waitIndex"=>wait_index})) |>
                       check_etcd_error |>
                       cb
                   end
               end)
end

function etcd_request(http_method,key::String,options=Dict{String,Any}())
    debug("Etcd $http_method called with:",{:key => key, :options => options})
    try
        if isempty(options)
            #eval(Expr(:call,Requests.http_method))
            etcd_response = http_method(key)
        else
            etcd_response = http_method(key,query=options)
        end
        etcd_response.data |> JSON.parse
    catch err
        warn("$http_method Request to server failed with $err")
    end
end

