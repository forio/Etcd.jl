**[Quickstart](#quickstart)** |
**[Configure the Etcd server](#configure-the-etcd-server)** |
**[Using Etcd Client](#using-etcddclient)**

# Etcd.jl

A Julia [Etcd](https://github.com/coreos/etcd) client implementation.

## Quickstart

```julia
julia> Pkg.add("Etcd")
julia> using Etcd
```

### Configure the Etcd server

The library defaults to Etcd server at 127.0.0.1:4001.


```julia
server = Etcd.EtcdServer()
EtcdServer("127.0.0.1",4001,"v2")
```

Or you can specify the server ip address and port number.

```julia
server = Etcd.EtcdServer("172.17.42.1",5001)
EtcdServer("172.17.42.1",5001,"v2")
```

### Using Etcd Client

#### Setting Key Values


```julia
etcd = Etcd.EtcdServer()
EtcdServer("127.0.0.1",4001,"v2")
```

Set a value on the `/foo/bar` key:

```julia
julia> Etcd.set(etcd,"/foo/bar","Hello World")
["action"=>"set","node"=>["createdIndex"=>1803,"key"=>"/foo/bar","value"=>"Hello World","modifiedIndex"=>1803]]
```

Set a value on the `/foo/bar` key with a value that expires in 60 seconds:

```julia
julia> Etcd.set(etcd,"/foo/bar","Hello World",ttl=60)
["action"=>"set","node"=>["createdIndex"=>1805,"key"=>"/foo/bar","value"=>"Hello World","expiration"=>"2014-03-25T01:19:39.182867998Z","ttl"=>60,"modifiedIndex"=>1805]]
```

Note that the ttl value can be set with all the following commands by specifying `ttl=ttl_expiry_time_in_seconds`

Conditionally set a value on `/foo/bar` if the previous value was "Hello world":

```julia
julia> Etcd.compare_and_swap(etcd,"/foo/bar","Goodbye Cruel World",prev_value="Hello World")
["action"=>"compareAndSwap","prevNode"=>["createdIndex"=>1811,"key"=>"/foo/bar","value"=>"Hello World","modifiedIndex"=>1811],"node"=>["createdIndex"=>1811,"key"=>"/foo/bar","value"=>"Goodbye Cruel World","modifiedIndex"=>1812]]
```

You can also conditionally set a value based on the previous etcd index.
Conditionally set a value on `/foo/bar` if the previous etcd index was 1818:

```julia
julia> Etcd.compare_and_swap(etcd,"/foo/bar","Goodbye Cruel World",prev_index=1818)
["action"=>"compareAndSwap","prevNode"=>["createdIndex"=>1818,"key"=>"/foo/bar","value"=>"Hello World","modifiedIndex"=>1818],"node"=>["createdIndex"=>1818,"key"=>"/foo/bar","value"=>"Goodbye Cruel World","modifiedIndex"=>1820]]
```

Create a new key `/foo/boo`, only if the key did not previously exist:

```julia
julia> Etcd.create(etcd,"/foo/boo","Hello World")
["action"=>"create","node"=>["createdIndex"=>1822,"key"=>"/foo/boo","value"=>"Hello World","modifiedIndex"=>1822]]
```

Create a new dir `/fooDir`, only if the directory did not previously exist:

```julia
julia> Etcd.create_dir(etcd,"/fooDir")
["action"=>"create","node"=>["createdIndex"=>1826,"key"=>"/fooDir","dir"=>true,"modifiedIndex"=>1826]]
```

Update an existing key `/foo/bar`, only if the key already existed:

```julia
julia> Etcd.update(etcd,"/foo/boo","Merhaba")
["action"=>"update","prevNode"=>["createdIndex"=>1822,"key"=>"/foo/boo","value"=>"Hello World","modifiedIndex"=>1822],"node"=>["createdIndex"=>1822,"key"=>"/foo/boo","value"=>"Merhaba","modifiedIndex"=>1828]]
```

You can also Create (`create_dir`) or update (`update_dir`) a directory.

#### Retrieving key values

Get the current value for a single key in the local etcd node:

```julia
julia> Etcd.get(etcd,"/foo/bar")
["action"=>"get","node"=>["createdIndex"=>1817,"key"=>"/foo/bar","value"=>"Hello World","modifiedIndex"=>1817]]
```
