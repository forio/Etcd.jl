api_path = joinpath(dirname(@__FILE__), "api")

files = [
    "keys.jl",
    "leaders.jl",
    "machines.jl",
    "members.jl",
    "stats.jl",
    "watch.jl",
]

for file in files
    include(joinpath(api_path, file))
end
