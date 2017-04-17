using Base.Test
using Etcd

info("Starting etcd server...")
const timeout = 60
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

        @testset "create_in_order" begin
        end

        @testset "add_child" begin
        end

        @testset "create_in_order_dir" begin
        end

        @testset "add_child_dir" begin
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
        end

        @testset "watchloop" begin
        end

        @testset "watchuntil" begin
        end
    end
end

sleep(5)
info("Stopping etcd server...")
kill(server)
