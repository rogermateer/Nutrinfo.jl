using Documenter
using Nutrinfo

makedocs(
    sitename = "Nutrinfo",
    format = Documenter.HTML(),
    modules = [Nutrinfo]
)

# Documenter can also automatically deploy documentation to gh-pages.
# See "Hosting Documentation" and deploydocs() in the Documenter manual
# for more information.
#=deploydocs(
    repo = "<repository url>"
)=#
