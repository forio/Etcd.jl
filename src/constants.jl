# These are the official errors as specified in etcd
# https://github.com/coreos/etcd

const etcd_error_codes = Int[(const ECODE_KEY_NOT_FOUND    = 100),
                             (const ECODE_TEST_FAILED      = 101),
                             (const ECODE_NOT_FILE         = 102),
                             (const ECODE_NO_MORE_PEER     = 103),
                             (const ECODE_NOT_DIR          = 104),
                             (const ECODE_NODE_EXIST       = 105),
                             (const ECODE_KEY_IS_PRESERVED = 106),
                             (const ECODE_ROOT_R_ONLY      = 107),
                             (const ECODE_DIR_NOT_EMPTY    = 108),

                             (const ECODE_VALUE_REQUIRED          = 200),
                             (const ECODE_PREV_VALUE_REQUIRED     = 201),
                             (const ECODE_TTL_NA_N                = 202),
                             (const ECODE_INDEX_NA_N              = 203),
                             (const ECODE_VALUE_OR_TTL_REQUIRED   = 204),
                             (const ECODE_TIMEOUT_NA_N            = 205),
                             (const ECODE_NAME_REQUIRED           = 206),
                             (const ECODE_INDEX_OR_VALUE_REQUIRED = 207),
                             (const ECODE_INDEX_VALUE_MUTEX       = 208),
                             (const ECODE_INVALID_FIELD           = 209),

                             (const ECODE_RAFT_INTERNAL = 300),
                             (const ECODE_LEADER_ELECT  = 301),

                             (const ECODE_WATCHER_CLEARED     = 400),
                             (const ECODE_EVENT_INDEX_CLEARED = 401)]

const etcd_errors = {
    # command related errors
    ECODE_KEY_NOT_FOUND => "Key not found",
    ECODE_TEST_FAILED => "Compare failed", # test and set
    ECODE_NOT_FILE => "Not a file",
    ECODE_NO_MORE_PEER => "Reached the max number of peers in the cluster",
    ECODE_NOT_DIR => "Not a directory",
    ECODE_NODE_EXIST => "Key already exists", # create
    ECODE_ROOT_R_ONLY => "Root is read only",
    ECODE_KEY_IS_PRESERVED => "The prefix of given key is a keyword in etcd",
    ECODE_DIR_NOT_EMPTY => "Directory not empty",

    # Post form related errors
    ECODE_VALUE_REQUIRED => "Value is Required in POST form",
    ECODE_PREV_VALUE_REQUIRED => "PrevValue is Required in POST form",
    ECODE_TTL_NA_N => "The given TTL in POST form is not a number",
    ECODE_INDEX_NA_N => "The given index in POST form is not a number",
    ECODE_VALUE_OR_TTL_REQUIRED => "Value or TTL is required in POST form",
    ECODE_TIMEOUT_NA_N => "The given timeout in POST form is not a number",
    ECODE_NAME_REQUIRED => "Name is required in POST form",
    ECODE_INDEX_OR_VALUE_REQUIRED => "Index or value is required",
    ECODE_INDEX_VALUE_MUTEX => "Index and value cannot both be specified",
    ECODE_INVALID_FIELD => "Invalid field",

    # raft related errors
    ECODE_RAFT_INTERNAL => "Raft Internal Error",
    ECODE_LEADER_ELECT => "During Leader Election",

    # etcd related errors
    ECODE_WATCHER_CLEARED => "watcher is cleared due to etcd recovery",
    ECODE_EVENT_INDEX_CLEARED => "The event in requested index is outdated and cleared"
}
