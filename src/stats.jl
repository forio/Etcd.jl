include("etcdserver.jl")

# TODO macro-ized
stats_prefix(etcd::EtcdServer,
             stats_type) = "http://$(etcd.ip):$(etcd.port)/v2/stats/$(stats_type)"

function stats(etcd::EtcdServer,stats_type::String)
    if stats_type != "leader" &&
       stats_type != "self" &&
       stats_type != "store"
        warn("Stats : Must specify the stats_type to be one of: leader, self or store")
    else
        etcd_request(Requests.get,stats_prefix(etcd,stats_type)) |>
        check_etcd_error |>
        JSON.parse
    end
end
