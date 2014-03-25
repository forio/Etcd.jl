**[Quickstart](#quickstart)** |
**[Configure the Etcd server](#configure-the-etcd-server)** |
**[Using Etcd Client](#using-etcd-dclient)**

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

Conditionally set a value on `/foo/bar` if the previous value was "Hello world". `test_and_set` is an alias for `compare_and_swap`. 

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

Add `recursive=true` to recursively list sub-directories.

Check for existence of a key:

```julia
julia> Etcd.exists(etcd,"/foo/bar")
true
```

#### Deleting keys

Delete a key:

```julia
julia> Etcd.create_dir(etcd,"/foo/qux")
julia> Etcd.delete(etcd,"/foo/boo")
["action"=>"delete","prevNode"=>["createdIndex"=>1822,"key"=>"/foo/boo","value"=>"Merhaba","modifiedIndex"=>1828],"node"=>["createdIndex"=>1822,"key"=>"/foo/boo","modifiedIndex"=>1837]]
```

Delete an empty directory:

```julia
julia> Etcd.delete_dir(etcd,"/foo/qux")
["action"=>"delete","prevNode"=>["createdIndex"=>1838,"key"=>"/foo/qux","dir"=>true,"modifiedIndex"=>1838],"node"=>["createdIndex"=>1838,"key"=>"/foo/qux","dir"=>true,"modifiedIndex"=>1839]] 
```

Recursively delete a key and all child keys:

```julia
julia> Etcd.get(etcd,"/foo",recursive=true)
["action"=>"get","node"=>["nodes"=>{["createdIndex"=>1817,"key"=>"/foo/bar","value"=>"Hello World","modifiedIndex"=>1817],["createdIndex"=>1818,"key"=>"/foo/baz","value"=>"Goodbye Cruel World","modifiedIndex"=>1820]},"createdIndex"=>1803,"key"=>"/foo","dir"=>true,"modifiedIndex"=>1803]]
ulia> Etcd.delete_dir(etcd,"/foo",recursive=true)
["action"=>"delete","prevNode"=>["createdIndex"=>1803,"key"=>"/foo","dir"=>true,"modifiedIndex"=>1803],"node"=>["createdIndex"=>1803,"key"=>"/foo","dir"=>true,"modifiedIndex"=>1844]]
julia> Etcd.get(etcd,"/foo",recursive=true)
["message"=>"Key not found","cause"=>"/foo","index"=>1844,"errorCode"=>100]
```

Conditionally delete `/foo/bar` if the previous value was "Hello world":

```julia
julia> Etcd.create(etcd,"/foo/bar","bar value")
["action"=>"create","node"=>["createdIndex"=>1845,"key"=>"/foo/bar","value"=>"bar value","modifiedIndex"=>1845]]
julia> Etcd.compare_and_delete(etcd,"/foo/bar",prev_value="bar value")
["action"=>"compareAndDelete","prevNode"=>["createdIndex"=>1845,"key"=>"/foo/bar","value"=>"bar value","modifiedIndex"=>1845],"node"=>["createdIndex"=>1845,"key"=>"/foo/bar","modifiedIndex"=>1846]]
```

Conditionally delete `/foo/bar` if the previous etcd index was 1849:

```julia
julia> Etcd.create(etl,"/foo/bar","Hello World")
["action"=>"create","node"=>["createdIndex"=>1849,"key"=>"/foo/bar","value"=>"Hello World","modifiedIndex"=>1849]]
julia> Etcd.compare_and_delete(etl,"/foo/bar",prev_index=1849)
["action"=>"compareAndDelete","prevNode"=>["createdIndex"=>1849,"key"=>"/foo/bar","value"=>"Hello World","modifiedIndex"=>1849],"node"=>["createdIndex"=>1849,"key"=>"/foo/bar","modifiedIndex"=>1850]]
```


#### Get all machines in the cluster

```julia
julia> Etcd.machines(et)
"http://172.17.42.1:5001, http://172.17.42.1:5002, http://172.17.42.1:5003"
```

#### Leader module

##### Set leader

##### Get leader of the cluster