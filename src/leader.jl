include("etcdserver.jl")

# TODO macro-ized
leader_prefix(etcd::EtcdServer,
              leader::String) = "http://$(etcd.ip):$(etcd.port)/mod/v2/leader/$(leader)"

function set_leader(etcd::EtcdServer,leader::String;
                    name::Union(String,Nothing)=nothing,
                    ttl::Union(Int,Nothing)=nothing)
    if is(name,nothing) && is(ttl,nothing)
        warn("Must specify a name and ttl for leader")
    else
        etcd_request(Requests.put,leader_prefix(etcd,leader),
                    {"name"=>name,"ttl"=>ttl}) |>
        check_etcd_error
    end
end

function get_leader(etcd::EtcdServer,leader::String)
    etcd_request(Requests.get,leader_prefix(etcd,leader)) |>
    check_etcd_error
end

function delete_leader(etcd::EtcdServer,leader::String;
                       name::Union(String,Nothing)=nothing)
    if is(name,nothing)
        warn("Must specify leader name for deletion")
    else
        etcd_request(Requests.delete,leader_prefix(etcd,leader),{"name"=>name}) |>
        check_etcd_error
    end
end
