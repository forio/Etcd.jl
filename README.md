**[Quickstart](#quickstart)** |
**[Configure the Etcd server](#configure-the-etcd-server)** |
**[Using Etcd Client](#using-etcd-client)**

# Etcd.jl
[![stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://Rory-Finnegan.github.io/Etcd.jl/stable/)
[![latest](https://img.shields.io/badge/docs-latest-blue.svg)](https://Rory-Finnegan.github.io/Etcd.jl/latest/)
[![Build Status](https://travis-ci.org/Rory-Finnegan/Etcd.jl.svg?branch=master)](https://travis-ci.org/Rory-Finnegan/Etcd.jl)
[![codecov](https://codecov.io/gh/Rory-Finnegan/Etcd.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/Rory-Finnegan/Etcd.jl)

A Julia [Etcd](https://github.com/coreos/etcd) client implementation.

## Quickstart

```julia
julia> Pkg.add("Etcd")
julia> using Etcd
```

### Configure the Etcd server

The library defaults to Etcd server at 127.0.0.1:2379.


```julia
cli = Etcd.connect("127.0.0.1", 2379,"v2")
```

Or you can specify the server ip address and port number.

```julia
cli = Etcd.connect("172.17.42.1", 5001)
```

### Using Etcd Client

#### Get all machines in the cluster

```julia
julia> Etcd.connect("127.0.0.1", 2379, "v2")

julia> machines(cli)
```

#### Setting Key Values


```julia
cli = Etcd.connect("127.0.0.1", 2379, "v2")
```

Set a value on the `/foo/bar` key:

```julia
julia> set(cli, "/foo/bar", "Hello World")
```

Set a value on the `/foo/bar` key with a value that expires in 60 seconds:

```julia
julia> set(cli, "/foo/bar", "Hello World", ttl=60)
```

Note that the ttl value can be set with all the following commands by specifying `ttl=ttl_expiry_time_in_seconds`

Conditionally set a value on `/foo/bar` if the previous value was "Hello world". `test_and_set` is an alias for `compare_and_swap`.

```julia
julia> cas(cli, "/foo/bar", "Goodbye Cruel World", prev_value="Hello World")
```

You can also conditionally set a value based on the previous etcd index.
Conditionally set a value on `/foo/bar` if the previous etcd index was 1818:

```julia
julia> cas(cli, "/foo/bar"," Goodbye Cruel World", prev_index=1818)
```

Create a new key `/foo/boo`, only if the key did not previously exist:

```julia
julia> create(cli, "/foo/boo", "Hello World")
```

Create a new dir `/fooDir`, only if the directory did not previously exist:

```julia
julia> createdir(cli, "/fooDir")
```

Update an existing key `/foo/bar`, only if the key already existed:

```julia
julia> update(cli, "/foo/boo", "Merhaba")
```

You can also Create (`createdir`) or update (`updatedir`) a directory.

#### Retrieving key values

Get the current value for a single key in the local etcd node:

```julia
julia> get(cli,"/foo/bar")
```

Add `recursive=true` to recursively list sub-directories.

Check for existence of a key:

```julia
julia> exists(cli,"/foo/bar")
true
```

#### Deleting keys

Delete a key:

```julia
julia> createdir(cli, "/foo/qux")
julia> delete(cli, "/foo/boo")
```

Delete an empty directory:

```julia
julia> deletedir(cli, "/foo/qux")
```

Recursively delete a key and all child keys:

```julia
julia> get(cli, "/foo", recursive=true)

julia> deletedir(cli, "/foo", recursive=true)

julia> get(cli, "/foo", recursive=true)
```

Conditionally delete `/foo/bar` if the previous value was "Hello world":

```julia
julia> create(cli, "/foo/bar", "bar value")

julia> cad(cli, "/foo/bar", prev_value="bar value")
```

Conditionally delete `/foo/bar` if the previous etcd index was 1849:

```julia
julia>create(cli, "/foo/bar", "Hello World")

julia> cad(cli, "/foo/bar", prev_index=1849)
```

#### Watching for changes

Watch for only the next change on a key:

```julia
julia> watch(ev->println("I'm watching you:", ev), cli, "/foo/bar")
Task (queued) @0x00000000024b65f0
...
... next make some modification to "/foo/bar" key and the callback is then called:
...
I'm watching you:["action"=>"update","prevNode"=>["createdIndex"=>1851,"key"=>"/foo/bar","value"=>"Hello World","modifiedIndex"=>1851],"node"=>["createdIndex"=>1851,"key"=>"/foo/bar","value"=>"Who's watching the watchers","modifiedIndex"=>1852]]
```

You can also specify the following options:

- `recursive=true` to watch the key and all it's children.
- `wait_index` to watch starting with the provided index.

Continuously watch a key:

```julia
julia> Etcd.keep_watching(etcd,"/foo/bar",ev->println("I'll keep on watching you:",ev))
.... The callback will keep getting called for every change to the key
```

Watch conditionally, while passing a function which will terminate the watch when it evaluates to `true`, for example:

```julia
julia> Etcd.watch_until(etcd,"/foo",ev->println("I'll be watching you (only 3 times):",ev),begin let l = 0; ev->begin l += 1; if l > 2 true else false end end end end,recursive=true)
```

## The below documentation is out of date!

#### Getting Etcd stats

You can retrieve Etcd stats by specifying one of `store`, `self` or `leader`.

For example to get the `store` stats:

```julia
julia> Etcd.stats(etcd,"store")
["getsSuccess"=>193,"updateFail"=>88,"watchers"=>1,"setsSuccess"=>710,"setsFail"=>2869,"expireCount"=>460,"compareAndSwapSuccess"=>3,"getsFail"=>10,"deleteSuccess"=>8,"createFail"=>10,"createSuccess"=>25,"compareAndDeleteSuccess"=>3,"deleteFail"=>3,"compareAndSwapFail"=>1,"updateSuccess"=>386,"compareAndDeleteFail"=>0]
```

#### Leader/Election module

Set a leader for the cluster (notice the leading slash is omitted) by specifying a name and a ttl as follows:

```julia
julia> Etcd.set_leader(etcd,"my-cluster",name="leader-1",ttl=60)
"1853"
```

Get the leader of the cluster:

```julia
julia> Etcd.get_leader(etcd,"my-cluster")
"leader-1"
```

Deleting the leader:

```julia
julia> Etcd.delete_leader(etcd,"my-cluster",name="leader-1")
""
```

#### Locking module

The lock module can be used to provide a distributed lock for resources among multiple clients. Only one client can have access to the lock at a time, once the lock holder releases the lock the next client waiting for the lock can acquire it.

`lock_retrieve` gets the lock index of the lock. `lock_acquire` is used to acquire the lock and it will return the lock index.

```julia
... another client acquires the lock
$ curl -L http://127.0.0.1:4001/mod/v2/lock/mylock -XPOST -d ttl=100
1876
julia> Etcd.lock_retrieve(etcd,"mylock")
"1876"
julia> Etcd.lock_acquire(etcd,"mylock",ttl=100)
... blocks until ttl for lock expires or until lock is released ...
"1878"
```

You can also renew the lock:

```julia
julia> Etcd.lock_renew(etcd,"mylock",index=1885,ttl=60)
```

And release the lock:

```julia
julia> Etcd.lock_release(etcd,"mylock",index=1890)
```
