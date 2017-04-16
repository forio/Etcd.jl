global const ETCD_DEPS_PATH = joinpath(dirname(dirname(@__FILE__)), "deps")
global const ETCD_SRC_PATH = if is_apple()
    joinpath(ETCD_DEPS_PATH, "etcd-v2.3.7-darwin-amd64.zip")
elseif is_linux()
    joinpath(ETCD_DEPS_PATH, "etcd-v2.3.7-linux-amd64.tar.gz")
end

global const ETCD_DEST_PATH = if is_apple()
    joinpath(ETCD_DEPS_PATH, "etcd-v2.3.7-darwin-amd64")
elseif is_linux()
    joinpath(ETCD_DEPS_PATH, "etcd-v2.3.7-linux-amd64")
end

global const ETCD_BIN = joinpath(ETCD_DEST_PATH, "etcd")

global const ETCD_DOWNLOAD_URI = if is_apple()
    "https://github.com/coreos/etcd/releases/download/v2.3.7/etcd-v2.3.7-darwin-amd64.zip"
elseif is_linux()
    "https://github.com/coreos/etcd/releases/download/v2.3.7/etcd-v2.3.7-linux-amd64.tar.gz"
else
    ""
end
