using JSON

export EtcdServer

type EtcdServer
    ip::String
    port::Int

    EtcdServer(ip::String="127.0.0.1",port::Int=4001) = new(ip,port)
end

function etcd_request(http_method,key::String,options=Dict{String,Any}())
    debug("Etcd $http_method called with:",{:key => key, :options => options})
    try
        if isempty(options)
            etcd_response = http_method(key)
        else
            #etcd_response = eval(Expr(:call,http_method,Expr(:kw,:query,options)))
            #ex = Expr(:call,http_method,key,Expr(:kw,:query,options))
            #xdump(ex)
            #etcd_response = eval(ex)
            etcd_response = http_method(key,query=options)
        end
        etcd_response.data
    catch err
        warn("$http_method Request to server failed with $err")
    end
end

function check_etcd_error(etcd_response)
    if isa(etcd_response,Dict) && haskey(etcd_response,"errorCode")
        ec = etcd_response["errorCode"]
        warn("Request failed with error code $(ec)",
             {:reason => Base.get(etcd_errors,ec,"Unknown Error")})
    end
    etcd_response
end
