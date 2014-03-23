include("etcdserver.jl")

stats_prefix(etcd::EtcdServer,
             stats_type) = "http://$(etcd.ip):$(etcd.port)/$(etcd.version)/stats/$(stats_type)"

function stats(etcd::EtcdServer,stats_type::String)
    if stats_type != "leader" &&
       stats_type != "self" &&
       stats_type != "store"
        warn("Stats : Must specify the stats_type to be one of: leader, self or store")
    else
        etcd_request(:get,stats_prefix(etcd,stats_type)) |>
        check_etcd_response
    end
end
