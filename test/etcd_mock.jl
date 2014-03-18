function get_func_signature(fdef::Expr)
    @assert fdef.head == :function || fdef.head == :(=)
    sig , body = fdef.args
    @assert sig.head == :call && isa(sig,Expr)
    fname = sig.args[1]
    args = sig.args[2:end]

    args_parse = foldl(Tuple[],sig.args[2:end]) do acc, el
        if isa(el,Symbol)
            push!(acc,(el,true))
        else
            push!(acc,(el,false))
        end
    end
    calls = try
                open(string(fname),"r") do s
                    seekstart(s)
                    deserialize(s)
                end
            catch err
                if isa(err,EOFError) || isa(err,SystemError)
                    # empty, expected
                    Dict()
                else
                    println("Unexpected error reading file: ",err)
                    throw(err)
                end
            end
    println("Cache: for $fname: ",calls)
    Expr(:function,esc(sig),
         quote
            local args_tup = tuple($(args...))
            local key = foldl(Any[],enumerate($args_parse)) do acc, el
                local index = el[1]
                local symb = args_tup[index]
                if el[2][2]
                    if isempty(names(symb))
                        push!(acc,symb)
                    else
                        push!(acc,
                              [getfield(symb,n) for n in 1:length(names(symb))])
                    end
                else
                    push!(acc,symb)
                end
            end
            if haskey($calls,key)
                #println("Reading from file")
                $calls[key]
            else
                $calls[key] = let; $body; end
                open(string($fname) ,"w+") do s
                    serialize(s,$calls)
                end
                #println("Wrote to file")
                $calls[key]
            end
         end)
end

macro etcd_mock(func)
    get_func_signature(func)
end
