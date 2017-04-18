function install(force=true)
    if !isempty(ETCD_DOWNLOAD_URI)
        if !ispath(ETCD_SRC_PATH)
            download(ETCD_DOWNLOAD_URI, ETCD_SRC_PATH)
        end

        if !ispath(ETCD_DEST_PATH) || force
            try
                run(`tar -xzvf $ETCD_SRC_PATH -C $ETCD_DEPS_PATH`)
            catch
                rm(src_path, recursive=true)
            end
        end
    end
end

function start(timeout=-1)
    if !ispath(ETCD_DEST_PATH)
        install()
    end

    if timeout > 0
        if is_apple()
            return spawn(`gtimeout $timeout $ETCD_BIN`)
        else
            return spawn(`timeout $timeout $ETCD_BIN`)
        end
    else
        return spawn(`$ETCD_BIN`)
    end
end
