immutable EtcdError <: Exception
    resp::Dict
end

function showerror(io::IO, err::EtcdError)
    err_code = err.resp["errorCode"]
    msg = get(err.resp, "message", "Unknown error")
    println(io, "EtcdError: $(err.msg) ($(err.rc)).")
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
    end

    return data
end

function request(f::Function, cli::AbstractClient, key::String, args...; kwargs...)
    return request(f, uri(cli, key), args...; kwargs...)
end
