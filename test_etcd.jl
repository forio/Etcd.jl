using Requests

type EtcdServer
    ip::IPv4
    port::Int
    server::String
    version::Int
    keys_prefix::String
    server_send::Function
    #EtcdServer(ip,port) = new EtcdServer(parseip(ip),port,
                                         #string(ip,port),2,
                                         #_etcd_server_config(ip,port))
end

function _etcd_server_config(ip,port)

end

#http://127.0.0.1:4001/v2/keys/message
# use a closure for nice interface like statsdclient
get_node(etcd_svr,node::String) = get(etcd_svr.etcd_svr*node)

#function wait_for_rm(c)
function wait_for_rm(cb)
    println("Waiting for RM")
    @async begin
        rm = get("http://127.0.0.1:4001/v2/keys/foo",
                  query={"wait"=>true}).data |> JSON.parse
        #produce(rm)
        cb(rm)
        #notify(c)
    end
end

function do_something_with_rm(rm)
    println("Doing some:",rm)
end

function get_rm()
    #c = Condition()
    #rm = wait_for_rm(c)
    #wait(c)
    wait_for_rm(do_something_with_rm)
    println("Wait done:")
    #new_rm = consume(@task wait_for_rm())
    #println("Wait done: result: ",rm.result)
    #println("Consume done: result: ",new_rm)
    #new_rm
end

#get_rm()

#function dummy(arg)
    #while(true)
        #produce(arg + 1)
    #end
#end

#[consume(@task dummy(i)) for i in 0:4]
