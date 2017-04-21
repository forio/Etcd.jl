using Base.Test
using Etcd

info("Starting etcd server...")
const timeout = 600     # A longer timeout for travis testing
# const timeout = 60    # More reasonable local timeout
const server = Etcd.start(timeout)  # Start server with timeout of 60 sec
const host = "localhost"
const port = 2379
const version = "v2"

@testset "Etcd" begin
    cli = Etcd.connect(host, port, version)

    @testset "machines" begin
        resp = machines(cli)
        @test isa(resp, AbstractArray)
        @test length(resp) == 2
        @test contains(resp[1], host)
        @test contains(resp[1], "$port")
    end

    @testset "stats" begin
        resp = stats(cli, "store")
        @test isa(resp, Dict)
        resp = stats(cli, "self")
        @test isa(resp, Dict)
        @test_throws HTTPError stats(cli, "foobar")
    end

    @testset "members" begin
        resp = members(cli)
        @test isa(resp, Dict)
        @test length(resp) == 1
    end

    @testset "leaders" begin
        resp = leader(cli)
        @test isa(resp, Dict)
    end

    @testset "keys" begin
        @testset "set" begin
            resp = set(cli, "/mykey", "myvalue"; ttl=1)
            @test isa(resp, Dict)
            @test haskey(resp, "action")
            @test resp["action"] == "set"
            @test haskey(resp, "node")
            @test haskey(resp["node"], "key")
            @test resp["node"]["key"] == "/mykey"
            @test haskey(resp["node"], "value")
            @test resp["node"]["value"] == "myvalue"

            sleep(2)    # expire
        end

        @testset "create" begin
            resp = create(cli, "/mykey", "myvalue"; ttl=2)

            @test isa(resp, Dict)
            @test haskey(resp, "action")
            @test resp["action"] == "create"
            @test haskey(resp, "node")
            @test haskey(resp["node"], "key")
            @test resp["node"]["key"] == "/mykey"
            @test haskey(resp["node"], "value")
            @test resp["node"]["value"] == "myvalue"

            @test_throws EtcdError create(cli, "/mykey", "myvalue"; ttl=1)
            sleep(3)    # expire
        end

        @testset "update" begin
            set(cli, "/mykey", "myvalue"; ttl=2)
            resp = update(cli, "/mykey", "mynewvalue"; ttl=1)
            @test isa(resp, Dict)
            @test haskey(resp, "action")
            @test resp["action"] == "update"
            @test haskey(resp, "node")
            @test haskey(resp["node"], "key")
            @test resp["node"]["key"] == "/mykey"
            @test haskey(resp["node"], "value")
            @test resp["node"]["value"] == "mynewvalue"

            sleep(3)    # expire
        end

        @testset "setdir" begin
            resp = setdir(cli, "/mydir"; ttl=1)
            @test isa(resp, Dict)
            @test haskey(resp, "action")
            @test resp["action"] == "set"
            @test haskey(resp, "node")
            @test haskey(resp["node"], "key")
            @test resp["node"]["key"] == "/mydir"
            @test haskey(resp["node"], "dir")
            @test resp["node"]["dir"]

            sleep(2)    # expire
        end

        @testset "createdir" begin
            resp = createdir(cli, "/mydir"; ttl=2)
            @test isa(resp, Dict)
            @test haskey(resp, "action")
            @test resp["action"] == "create"
            @test haskey(resp, "node")
            @test haskey(resp["node"], "key")
            @test resp["node"]["key"] == "/mydir"
            @test haskey(resp["node"], "dir")
            @test resp["node"]["dir"]

            @test_throws EtcdError createdir(cli, "/mydir"; ttl=1)

            sleep(3)    # expire
        end

        @testset "updatedir" begin
            @test_throws EtcdError updatedir(cli, "/mydir"; ttl=1)
            setdir(cli, "/mydir"; ttl=2)
            resp = updatedir(cli, "/mydir"; ttl=1)
            @test isa(resp, Dict)
            @test haskey(resp, "action")
            @test resp["action"] == "update"
            @test haskey(resp, "node")
            @test haskey(resp["node"], "key")
            @test resp["node"]["key"] == "/mydir"
            @test haskey(resp["node"], "dir")
            @test resp["node"]["dir"]

            sleep(3)    # expire
        end

        @testset "ordered_set" begin
            resp = set(cli, "/queue", "Job1"; ttl=3, ordered=true)
            @test isa(resp, Dict)
            @test haskey(resp, "action")
            @test resp["action"] == "create"
            @test haskey(resp, "node")
            @test haskey(resp["node"], "value")
            @test resp["node"]["value"] == "Job1"
            resp = set(cli, "/queue", "Job2"; ttl=2, ordered=true)
            @test isa(resp, Dict)
            @test haskey(resp, "action")
            @test resp["action"] == "create"
            @test haskey(resp, "node")
            @test haskey(resp["node"], "value")
            @test resp["node"]["value"] == "Job2"
            resp = get(cli, "/queue"; sort=true, recursive=true)
            @test isa(resp, Dict)
            @test haskey(resp, "action")
            @test resp["action"] == "get"
            @test haskey(resp, "node")
            @test haskey(resp["node"], "nodes")
            @test isa(resp["node"]["nodes"], AbstractArray)
            @test length(resp["node"]["nodes"]) == 2

            sleep(3)
        end

        @testset "haskey" begin
            set(cli, "/mykey", "myvalue"; ttl=2)
            @test haskey(cli, "/mykey")
            @test !haskey(cli, "/mymissingkey")

            sleep(3)    # expire
        end

        @testset "cas" begin
            set(cli, "/mykey", "myvalue"; ttl=2)
            resp = Etcd.cas(cli, "/mykey", "mynewvalue"; prev_value="myvalue", ttl=1)
            @test isa(resp, Dict)
            @test haskey(resp, "action")
            @test resp["action"] == "compareAndSwap"
            @test haskey(resp, "node")
            @test haskey(resp["node"], "key")
            @test resp["node"]["key"] == "/mykey"
            @test haskey(resp["node"], "value")
            @test resp["node"]["value"] == "mynewvalue"
            @test haskey(resp, "prevNode")
            @test haskey(resp["prevNode"], "key")
            @test resp["prevNode"]["key"] == "/mykey"
            @test haskey(resp["prevNode"], "value")
            @test resp["prevNode"]["value"] == "myvalue"

            # @test_throws EtcdError Etcd.cas(cli, "/mykey", "myvalue")

            sleep(3)
        end

        @testset "cad" begin
            set(cli, "/mykey", "myvalue"; ttl=2)
            # @test_throws EtcdError Etcd.cad(cli, "/mykey")

            resp = Etcd.cad(cli, "/mykey"; prev_value="myvalue")
            @test isa(resp, Dict)
            @test haskey(resp, "action")
            @test resp["action"] == "compareAndDelete"
            @test haskey(resp, "node")
            @test haskey(resp["node"], "key")
            @test resp["node"]["key"] == "/mykey"
            @test haskey(resp, "prevNode")
            @test haskey(resp["prevNode"], "key")
            @test resp["prevNode"]["key"] == "/mykey"
            @test haskey(resp["prevNode"], "value")
            @test resp["prevNode"]["value"] == "myvalue"

            sleep(3)
        end

        @testset "watch" begin
            c = Channel{Dict}(32)
            set_resp = set(cli, "/mykey", "myvalue"; ttl=2)
            idx = set_resp["node"]["modifiedIndex"] + 1

            t = watch(cli, "/mykey"; wait_index=idx, recursive=true) do resp
                put!(c, resp)
            end

            set_resp = set(cli, "/mykey", "newvalue"; ttl=2)
            wait(t)
            c_resp = take!(c)
            @test set_resp == c_resp || c_resp["action"] == "expire"

            sleep(2)
        end

        @testset "watchloop" begin
            c = Channel{Dict}(32)

            t = watchloop(cli, "/mykey"; recursive=true) do resp
                put!(c, resp)
            end

            set_resp = set(cli, "/mykey", "val1"; ttl=1)
            c_resp = take!(c)
            @test set_resp == c_resp || c_resp["action"] == "expire"
            set_resp = set(cli, "/mykey", "val2"; ttl=1)
            c_resp = take!(c)
            @test set_resp == c_resp || c_resp["action"] == "expire"
            try
                schedule(t, InterruptException(); error=true)
                wait(t)
            end

            sleep(2)
        end

        @testset "watchuntil" begin
            c = Channel{Dict}(32)
            set_resp = set(cli, "/mykey", "val1"; ttl=2)
            idx = set_resp["node"]["modifiedIndex"] + 1
            predicate(r) = r["node"]["modifiedIndex"] > 5

            t = watchuntil(cli, "/mykey", predicate; wait_index=idx, recursive=true) do resp
                put!(c, resp)
            end

            i = 2
            set_resp = set(cli, "/mykey", "val$i"; ttl=1)
            sleep(0.2)
            while isready(c)
                c_resp = take!(c)
                @test set_resp == c_resp || c_resp["action"] == "expire"
                i += 1
                set_resp = set(cli, "/mykey", "val$i"; ttl=1)
                sleep(0.2)
            end

            wait(t)
            sleep(2)
        end
    end
end

sleep(5)
info("Stopping etcd server...")
kill(server)
