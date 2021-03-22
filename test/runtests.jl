using Nutrinfo
using Test
using TestSetExtensions

using Nutrinfo

@testset ExtendedTestSet "Unitful Intervals - the bread and butter of nutritional information calculations" begin
    @test Interval(0,1)u"μg" + 1u"μg" == Interval(1,2)u"μg"
    @test                            Interval(0,1)u"μg" + 1u"mg"   != Interval(1,1.001)u"mg"
    @test round(u"μg",uconvert(u"μg",Interval(0,1)u"μg" + 1u"mg")) != Interval(1000,1001)u"mg"
    @test round(u"μg",uconvert(u"μg",Interval(0,1)u"μg" + 1u"mg")) == Interval(1000,1001)u"μg"
    @test                            Interval(0,1)u"μg" + 1u"mg"   != Interval(1000,1001)u"μg"
    @test             uconvert(u"μg",Interval(0,1)u"μg" + 1u"mg")  != Interval(1000,1001)u"μg"
end


@testset ExtendedTestSet "Custom Units" begin
    @test uconvert(u"kJ",1u"kcal") == 4.184u"kJ"
end

# Source: random myfitnesspal entries. Note: there is wild
# inaccuracy/variability in its crowd-sourced nutritional information
# - often due to lazy recording of serving sizes

FuerteAvocado100g = Dict{String,Any}(
    "Serving" => 100u"g",
    "Energy" => 160u"kcal",
    "Protein" => 2u"g",
    "Carbohydrates" => (26/3)u"g",
    "Fat" => (44/3)u"g"
)
FuerteAvocado = Dict{String,Any}(
    "Serving" => 150u"g",
    "Energy" => 240u"kcal",
    "Protein" => 3u"g",
    "Carbohydrates" => 13u"g",
    "Fat" => 22u"g"
)

Egg100g = Dict{String,Any}(
    "Serving" => 100u"g",
    "Energy" => 143u"kcal",
    "Protein" => 13u"g",
    "Carbohydrates" => 1u"g",
    "Fat" => 10u"g"
)
EggLarge = qty(50u"g",Egg100g)

SaskoLowGiBrownBread100g = Dict{String,Any}(
    "Serving" => 100u"g",
    "Energy" => 223u"kcal",
    "Protein" => 9u"g",
    "Carbohydrates" => 38u"g",
    "Fat" => 1u"g"
)
SaskoLowGiBrownBreadSlice = qty(55u"g",SaskoLowGiBrownBread100g)

BreakfastActual = [
    FuerteAvocado,
    scale(3,EggLarge),
    scale(2,SaskoLowGiBrownBreadSlice),
]
BreakfastExpected = Dict{String,Any}(
    "Serving" => FuerteAvocado["Serving"] + 3*EggLarge["Serving"] + 2*SaskoLowGiBrownBreadSlice["Serving"],
    "Energy" => FuerteAvocado["Energy"] + 3*EggLarge["Energy"] + 2*SaskoLowGiBrownBreadSlice["Energy"],
    "Protein" => FuerteAvocado["Protein"] + 3*EggLarge["Protein"] + 2*SaskoLowGiBrownBreadSlice["Protein"],
    "Carbohydrates" => FuerteAvocado["Carbohydrates"] + 3*EggLarge["Carbohydrates"] + 2*SaskoLowGiBrownBreadSlice["Carbohydrates"],
    "Fat" => FuerteAvocado["Fat"] + 3*EggLarge["Fat"] + 2*SaskoLowGiBrownBreadSlice["Fat"]
)
day20210310 = [
    BreakfastActual...,
]

@testset ExtendedTestSet "Prototype Food Log" begin
    @test qty(100u"g",FuerteAvocado)==FuerteAvocado100g
    @test combine(day20210310)["Serving"]==BreakfastExpected["Serving"]
    @test combine(day20210310)["Energy"]==BreakfastExpected["Energy"]
    @test combine(day20210310)["Protein"]==BreakfastExpected["Protein"]
    @test combine(day20210310)["Carbohydrates"]==BreakfastExpected["Carbohydrates"]
    @test combine(day20210310)["Fat"]==BreakfastExpected["Fat"]
    @test combine(day20210310) ≈ BreakfastExpected
end

@testset ExtendedTestSet "Unit parsing" begin
    @test parseUnit("1kcal")==u"4.184kJ"
    @test parseUnit("1g")==u"1000mg"
    @test parseUnit("1000mg")==u"1g"
end

@testset ExtendedTestSet "JSON comment stripping" begin
    log = JSON.parsefile("../data/log.json")
    strippedLog = JSON.parsefile("../data/log.nocomments.json");
    #@test log == stripCommentsFromLog(log)
    @test stripCommentsFromLog(log) == strippedLog

    nutrients = JSON.parsefile("../data/nutrients.json")
    strippedNutrients = JSON.parsefile("../data/nutrients.nocomments.json");
    #@test nutrients == stripCommentsFromNutrients(nutrients)
    @test stripCommentsFromNutrients(nutrients) == strippedNutrients
end

#=
    #typedlog = Dict{String,Union{String,Array{Any,1}}}(log);
    #print(Dict{String,Union{String,Array{Dict{String,String},1}}}(log))
    print("""

LOG
""")
    print(log)
    print("""

STRIPPEDLOG
""")
    print(strippedLog)

    log20210310 = log["<2021-03-10 Wed>"]
    print(log20210310)
    barelog20210310 = stripCommentsFromArrayOfDict(Array{Dict{String,Any},1}(log20210310))
    @test length(barelog20210310) == length(BreakfastActual)

    nutrients = JSON.parsefile("../data/nutrients.json")
    @test parseUnits(nutrients[barelog20210310[1]["of"]]) == BreakfastActual[1]

    @test qty(parseUnit(barelog20210310[1]["qty"]),parseUnits(nutrients[barelog20210310[1]["of"]])) == BreakfastActual[1]
    @test qty(parseUnit(barelog20210310[2]["qty"]),parseUnits(nutrients[barelog20210310[2]["of"]])) == BreakfastActual[2]
    @test qty(parseUnit(barelog20210310[3]["qty"]),parseUnits(nutrients[barelog20210310[3]["of"]])) == BreakfastActual[3]

    @test parseIngredient(barelog20210310[1],nutrients) == BreakfastActual[1]
    @test parseIngredient(barelog20210310[2],nutrients) == BreakfastActual[2]
    @test parseIngredient(barelog20210310[3],nutrients) == BreakfastActual[3]

    @test parseIngredients(barelog20210310,nutrients) ≈ combine(BreakfastActual)
=#
