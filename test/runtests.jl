using Nutrinfo
using Test

using Nutrinfo

@testset "Unitful Intervals - the bread and butter of nutritional information calculations" begin
    @test Interval(0,1)u"μg" + 1u"μg" == Interval(1,2)u"μg"
    @test                            Interval(0,1)u"μg" + 1u"mg"   != Interval(1,1.001)u"mg"
    @test round(u"μg",uconvert(u"μg",Interval(0,1)u"μg" + 1u"mg")) != Interval(1000,1001)u"mg"
    @test round(u"μg",uconvert(u"μg",Interval(0,1)u"μg" + 1u"mg")) == Interval(1000,1001)u"μg"
    @test                            Interval(0,1)u"μg" + 1u"mg"   != Interval(1000,1001)u"μg"
    @test             uconvert(u"μg",Interval(0,1)u"μg" + 1u"mg")  != Interval(1000,1001)u"μg"
end

@testset "Custom Units" begin
    @test uconvert(u"kJ",1u"kcal") == 4.184u"kJ"
end

@testset "Prototype Food Log" begin
    # Source: random myfitnesspal entries. Note: there is wild
    # inaccuracy/variability in its crowd-sourced nutritional
    # information - often due to lazy recording of serving sizes

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

    @test qty(100u"g",FuerteAvocado)==FuerteAvocado100g
    
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
    Day = [
        BreakfastActual...,
    ]

    @test combine(Day)["Serving"]==BreakfastExpected["Serving"]
    @test combine(Day)["Energy"]==BreakfastExpected["Energy"]
    @test combine(Day)["Protein"]==BreakfastExpected["Protein"]
    @test combine(Day)["Carbohydrates"]==BreakfastExpected["Carbohydrates"]
    @test combine(Day)["Fat"]==BreakfastExpected["Fat"]

    @test combine(Day) ≈ BreakfastExpected

end
