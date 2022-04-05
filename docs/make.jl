using VehicleRoutingSynPre
using Documenter

DocMeta.setdocmeta!(VehicleRoutingSynPre, :DocTestSetup, :(using VehicleRoutingSynPre); recursive=true)

makedocs(;
    modules=[VehicleRoutingSynPre],
    authors="Payakorn Saksuriya",
    repo="https://github.com/payakorn/VehicleRoutingSynPre.jl/blob/{commit}{path}#{line}",
    sitename="VehicleRoutingSynPre.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://payakorn.github.io/VehicleRoutingSynPre.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/payakorn/VehicleRoutingSynPre.jl",
    devbranch="master",
)
