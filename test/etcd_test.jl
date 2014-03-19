using Base.Test
include("../src/Etcd.jl")
include("etcd_mock.jl")

# XXX ideally this macro would create that temp func and use that
# instead of this interface here
@etcd_mock test_machines(et) = Etcd.machines(et)
@etcd_mock test_set(et,k,v,t) = Etcd.set(et,k,v,ttl=t)
@etcd_mock test_get(et,k,s,r) = Etcd.get(et,k,sort=s,recursive=r)
@etcd_mock test_create_dir(et,k,t) = Etcd.create_dir(et,k,ttl=t)
@etcd_mock test_add_child(et,k,v,t) = Etcd.add_child(et,k,v,ttl=t)
@etcd_mock test_add_child_dir(et,k,t) = Etcd.add_child_dir(et,k,ttl=t)
@etcd_mock test_delete(et,k) = Etcd.delete(et,k)
@etcd_mock test_set_dir(et,k,t) = Etcd.set_dir(et,k,ttl=t)
@etcd_mock test_delete_dir(et,k,r) = Etcd.delete_dir(et,k,recursive=r)

function setup_etcd()
    et = Etcd.EtcdServer()
    println("Etcd server created at: ",et)
    et
end

function test_etcd_machines(et)
    mach = test_machines(et)
    @test mach == "http://127.0.0.1:4001"
end

function test_etcd_set(et)
    key = "/test"
    val = "testvalue"
    set_node = test_set(et,key,val,5)
    @test haskey(set_node,"node")
    @test haskey(set_node["node"],"key")
    @test set_node["node"]["key"] == key
    @test haskey(set_node["node"],"value")
    @test set_node["node"]["value"] == val
    @test set_node["node"]["ttl"] == 5
end

function test_etcd_get(et)
    key = "/foo"
    value = "bar"
    ttl = 5
    # set it
    set_node = test_set(et,key,value,ttl)
    # then get it
    get_node = test_get(et,key,false,false)
    @test haskey(get_node,"node")
    @test haskey(get_node["node"],"key")
    @test get_node["node"]["key"] == key
    @test haskey(get_node["node"],"value")
    @test get_node["node"]["value"] == value
end

function test_etcd_create_dir(et)
    # create dir
    d_name = "/fooDir"
    ttl = 5
    dir = test_create_dir(et,d_name,ttl)
    k0 = test_set(et,"/fooDir/k0", "v0", ttl)
    k1 = test_set(et,"/fooDir/k1", "v1", ttl)

    # Return kv-pairs in sorted order
    nodes = test_get(et,d_name,true,false)
    println("nodes:",nodes)
    ch_dir = test_create_dir(et,d_name*"/childDir",ttl)
    k2 = test_set(et,d_name*"/childDir/k2", "v2", ttl)

    # recursively get kv-pairs in sorted order
    nodes = test_get(et,d_name,true,true)
    @test length(nodes["node"]["nodes"]) == 3
    @test nodes["node"]["nodes"][1]["nodes"][1]["key"] == "/fooDir/childDir/k2"
    @test nodes["node"]["nodes"][1]["nodes"][1]["value"] == "v2"
    @test nodes["node"]["nodes"][1]["nodes"][1]["ttl"] == ttl

    @test nodes["node"]["nodes"][2]["key"] == "/fooDir/k0"
    @test nodes["node"]["nodes"][2]["value"] == "v0"
    @test nodes["node"]["nodes"][2]["ttl"] == ttl

    @test nodes["node"]["nodes"][3]["key"] == "/fooDir/k1"
    @test nodes["node"]["nodes"][3]["value"] == "v1"
    @test nodes["node"]["nodes"][3]["ttl"] == ttl
end

function test_etcd_add_child(et)
    d_name = "/booDir"
    ch_dir = test_create_dir(et,d_name,5)
    c1 = test_add_child(et,d_name,"v0",5)
    c2 = test_add_child(et,d_name,"v1",5)

    nodes = test_get(et,d_name,true,false)
    @test length(nodes["node"]["nodes"]) == 2
    @test nodes["node"]["nodes"][1]["value"] == "v0"
    @test nodes["node"]["nodes"][2]["value"] == "v1"

    # Creating a child under a nonexistent directory should succeed.
    # The directory should be created.
    c3 = test_add_child(et,"/nonexistentDir","foo",5)
    @test c3["node"]["value"] == "foo"
end

function test_etcd_add_child_dir(et)
    d_name = "/looDir"
    ch_dir = test_create_dir(et,d_name,5)
    c1 = test_add_child_dir(et,d_name,5)
    c2 = test_add_child_dir(et,d_name,6)

    nodes = test_get(et,d_name,true,false)
    @test length(nodes["node"]["nodes"]) == 2
    @test nodes["node"]["nodes"][1]["ttl"] == 5
    @test nodes["node"]["nodes"][2]["ttl"] == 6

    # Creating a child under a nonexistent directory should succeed.
    # The directory should be created.
    c3 = test_add_child_dir(et,"/nonexistentDir",5)
    @test haskey(c3["node"],"key")
end

function test_etcd_delete(et)
    key = "/foo"
    value = "baz"
    ttl = 5
    set_node = test_set(et,key,value,ttl)
    # delete node
    del_node = test_delete(et,key)
    @test del_node["prevNode"]["value"] == value
end

function test_etcd_delete_dir(et)
    test_set_dir(et,"/foo",5)
    # test delete an empty dir
    del_dir = test_delete_dir(et,"/foo",false)

    @test haskey(del_dir["node"],"value") == false
    @test del_dir["prevNode"]["dir"] == true
    @test haskey(del_dir["prevNode"],"value") == false

    # test ability to not delete a non-empty directory
    d_name = "/gooDir"
    ttl = 5
    dir = test_create_dir(et,d_name,ttl)
    foo = test_set(et,d_name*"/goo", "gar", ttl)
    del_dir = test_delete_dir(et,d_name,false)
    @test haskey(del_dir,"errorCode")

    del_dir = test_delete_dir(et,d_name,true)
    @test del_dir["prevNode"]["dir"] == true
    @test haskey(del_dir["prevNode"],"value") == false
    @test haskey(del_dir["node"],"value") == false
end

function test_etcd()
    et = setup_etcd()
    test_funcs = [test_etcd_machines,
                  test_etcd_set,
                  test_etcd_get,
                  test_etcd_create_dir,
                  test_etcd_add_child,
                  test_etcd_add_child_dir,
                  test_etcd_delete,
                  test_etcd_delete_dir
                  ]
    [f(et) for f in test_funcs]
end

test_etcd()
