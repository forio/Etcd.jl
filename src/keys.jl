
include("etcdserver.jl")

keys_prefix(etcd::EtcdServer,key::String) =
    "http://$(etcd.ip):$(etcd.port)/$(etcd.version)/keys$(key)"

function get(etcd::EtcdServer,key::String;
             sort::Bool=false,recursive::Bool=false)
   etcd_request(:get,keys_prefix(etcd,key),
                filter((k,v)->v,
                       {"sorted"=>sort,"recursive"=>recursive})) |>
   check_etcd_response
end

function set(etcd::EtcdServer,key::String,value::String;
             ttl::Union(Int,Nothing)=nothing)
   etcd_request(:put,keys_prefix(etcd,key),
                filter((k,v)->!is(v,nothing),
                       {"value"=>value,"ttl"=>ttl})) |>
   check_etcd_response
end

function set_dir(etcd::EtcdServer,key::String;
                 ttl::Union(Int,Nothing)=nothing)
   etcd_request(:put,keys_prefix(etcd,key),
                filter((k,v)->!is(v,nothing),
                       {"value"=>"","ttl"=>ttl,"dir"=>true})) |>
   check_etcd_response
end

function create_dir(etcd::EtcdServer,key::String;
                    ttl::Union(Int,Nothing)=nothing)
   etcd_request(:put,keys_prefix(etcd,key),
                filter((k,v)->!is(v,nothing),
                       {"value"=>"","ttl"=>ttl,
                        "prevExist"=>false,"dir"=>true})) |>
   check_etcd_response
end

function update_dir(etcd::EtcdServer,key::String;
                    ttl::Union(Int,Nothing)=nothing)
   etcd_request(:put,keys_prefix(etcd,key),
                filter((k,v)->!is(v,nothing),
                       {"value"=>"","ttl"=>ttl,
                        "prevExist"=>true,"dir"=>true})) |>
   check_etcd_response
end

function create(etcd::EtcdServer,key::String,value::String;
                ttl::Union(Int,Nothing)=nothing)
   etcd_request(:put,keys_prefix(etcd,key),
                filter((k,v)->!is(v,nothing),
                       {"value"=>value,"ttl"=>ttl,
                        "prevExist"=>false})) |>
   check_etcd_response
end

function update(etcd::EtcdServer,key::String,value::String;
                ttl::Union(Int,Nothing)=nothing)
   etcd_request(:put,keys_prefix(etcd,key),
                filter((k,v)->!is(v,nothing),
                       {"value"=>value,"ttl"=>ttl,
                        "prevExist"=>true})) |>
   check_etcd_response
end

function create_in_order(etcd::EtcdServer,key::String,value::String;
                         ttl::Union(Int,Nothing)=nothing)
   etcd_request(:post,keys_prefix(etcd,key),
                filter((k,v)->!is(v,nothing),
                       {"value"=>value,"ttl"=>ttl})) |>
   check_etcd_response
end

add_child(etcd::EtcdServer,key::String,value::String;
          ttl::Union(Int,Nothing)=nothing) = create_in_order(etcd,
                                                             key,
                                                             value,
                                                             ttl=ttl)

function create_in_order_dir(etcd::EtcdServer,key::String;
                             ttl::Union(Int,Nothing)=nothing)
   etcd_request(:post,keys_prefix(etcd,key),
                filter((k,v)->!is(v,nothing),
                       {"value"=>"","ttl"=>ttl})) |>
   check_etcd_response
end

add_child_dir(etcd::EtcdServer,key::String;
              ttl::Union(Int,Nothing)=nothing) = create_in_order_dir(etcd,
                                                                     key,
                                                                     ttl=ttl)

function exists(etcd::EtcdServer,key::String)
   etcd_request(:get,keys_prefix(etcd,key)) |>
   (rsp)->if isa(rsp,Dict)
              try
                  JSON.parse(rsp) |>
                  (rsp)->!haskey(rsp,"errorCode")
              catch
                  false
              end
          else
              false
          end
end

has_key(etcd::EtcdServer,key::String) = exists(etcd,key)

function delete(etcd::EtcdServer,key::String)
   etcd_request(:delete,keys_prefix(etcd,key)) |>
   check_etcd_response
end

function delete_dir(etcd::EtcdServer,key::String;recursive::Bool=false)
   etcd_request(:delete,keys_prefix(etcd,key),
                filter((k,v)->v,
                       {"dir"=>true,"recursive"=>recursive})) |>
   check_etcd_response
end

function compare_and_delete(etcd::EtcdServer,key::String;
                            prev_value::Union(String,Nothing)=nothing,
                            prev_index::Union(Int,Nothing)=nothing)
   if is(prev_value,nothing) && is(prev_index,nothing)
       warn("Must specify either prev_value (a string) or prev_index (an integer)")
   else
       etcd_request(:delete,keys_prefix(etcd,key),
                    filter((k,v)->!is(v,nothing),
                           {"prevValue"=>prev_value,
                            "prevIndex"=>prev_index})) |>
       check_etcd_response
    end
end

function compare_and_swap(etcd::EtcdServer,key::String,value::String;
                          prev_value::Union(String,Nothing)=nothing,
                          prev_index::Union(Int,Nothing)=nothing,
                          ttl::Union(Int,Nothing)=nothing)
   if is(prev_value,nothing) && is(prev_index,nothing)
       warn("Must specify either prev_value (a string) or prev_index (an integer)")
   else
       etcd_request(:put,keys_prefix(etcd,key),
                    filter((k,v)->!is(v,nothing),
                           {"value"=>value,
                            "prevValue"=>prev_value,
                            "prevIndex"=>prev_index,
                            "ttl"=>ttl})) |>
       check_etcd_response
    end
end

test_and_set(etcd::EtcdServer,key::String,value::String;
             prev_value::Union(String,Nothing)=nothing,
             prev_index::Union(Int,Nothing)=nothing,
             ttl::Union(Int,Nothing)=nothing) = compare_and_swap(etcd,key,value,
                                                                 prev_value=prev_value,
                                                                 prev_index=prev_index,
                                                                 ttl=ttl)

function watch(etcd::EtcdServer,key::String,cb::Function;
               wait_index::Union(Int,Bool)=false,
               recursive::Bool=false)
   @async begin
       etcd_request(:get,keys_prefix(etcd,key),
                    filter((k,v)->v,
                           {"wait"=>true,
                            "recursive"=>recursive,
                            "waitIndex"=>wait_index})) |>
       check_etcd_response |>
       cb
   end
end

function keep_watching(etcd::EtcdServer,key::String,cb::Function;
                       wait_index::Union(Int,Bool)=false,
                       recursive::Bool=false)
    @async begin
        while true
            etcd_request(:get,keys_prefix(etcd,key),
                         filter((k,v)->v,
                         {"wait"=>true,
                          "recursive"=>recursive,
                          "waitIndex"=>wait_index})) |>
            check_etcd_response |>
            cb
            if wait_index != false
                wait_index += 1
            end
        end
    end
end

function watch_until(etcd::EtcdServer,key::String,
                     cb::Function,
                     should_terminate::Function;
                     wait_index::Union(Int,Bool)=false,
                     recursive::Bool=false)
   @async begin
       while true
           ev = etcd_request(:get,keys_prefix(etcd,key),
                        filter((k,v)->v,
                        {"wait"=>true,
                         "recursive"=>recursive,
                         "waitIndex"=>wait_index})) |>
                check_etcd_response
           cb(ev)
           if should_terminate(ev)
               break
           end
           if wait_index != false
               wait_index += 1
           end
       end
    end
end
