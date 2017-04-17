immutable HTTPError <: Exception
    resp::Response
end

response(err::HTTPError) = err.resp

function showerror(io::IO, err::HTTPError)
    msg = readstring(resp)
    println("HTTPError: $msg")
end

immutable EtcdError <: Exception
    resp::Dict
end

response(err::EtcdError) = err.resp

function showerror(io::IO, err::EtcdError)
    err_code = err.resp["errorCode"]
    msg = get(err.resp, "message", "Unknown error")
    println(io, "EtcdError: $msg ($err_code).")
end

function request(f::Function, uri::String, opts::Dict; n=5, max_delay=10.0)
    retry_cond(resp) = in(statuscode(resp), 300:400) && haskey(resp.headers, "Location")

    resp = if isempty(opts)
        retry(() -> f(uri), retry_cond; n=n, max_delay=max_delay)()
    else
        retry(() -> f(uri; query=opts), retry_cond; n=n, max_delay=max_delay)()
    end

    data = try
        Requests.json(resp)
    catch _
        readstring(resp)
    end

    if isa(data, Dict) && Base.haskey(data, "errorCode")
        throw(EtcdError(data))
    elseif statuscode(resp) >= 400
        throw(HTTPError(resp))
    end

    return data
end
