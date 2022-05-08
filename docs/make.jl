using Nutrinfo
using Documenter

DocMeta.setdocmeta!(Nutrinfo, :DocTestSetup, :(using Nutrinfo); recursive=true)

makedocs(;
    modules=[Nutrinfo],
    authors="Roger Mateer <rogermateer@gmail.com> and contributors",
    repo="https://github.com/rogermateer/Nutrinfo.jl/blob/{commit}{path}#{line}",
    sitename="Nutrinfo.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://rogermateer.github.io/Nutrinfo.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/rogermateer/Nutrinfo.jl",
    devbranch="main",
)
