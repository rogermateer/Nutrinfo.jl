using Nutrinfo
using Test
using TestSetExtensions

@testset ExtendedTestSet "Unitful Intervals - the bread and butter of nutritional information calculations" begin
    @test Interval(0,1)u"μg" + 1u"μg" == Interval(1,2)u"μg"
    @test                            Interval(0,1)u"μg" + 1u"mg"   != Interval(1,1.001)u"mg"
    @test round(u"μg",uconvert(u"μg",Interval(0,1)u"μg" + 1u"mg")) != Interval(1000,1001)u"mg"
    @test round(u"μg",uconvert(u"μg",Interval(0,1)u"μg" + 1u"mg")) == Interval(1000,1001)u"μg"
    @test                            Interval(0,1)u"μg" + 1u"mg"   != Interval(1000,1001)u"μg"
    @test             uconvert(u"μg",Interval(0,1)u"μg" + 1u"mg")  != Interval(1000,1001)u"μg"
end

@testset ExtendedTestSet "Unitful Interval parsing - I'm open to correction, but apparently this doesn't 'just work' out of the box" begin
    @test parseUnit("1μg") == 1u"μg"
    @test parseUnit("1 μg") == 1u"μg"
    @test parseUnit("[0,1]μg") == Interval(0,1)u"μg"
    @test parseUnit(" [ 0 , 1 ] μ g ") == Interval(0,1)u"μg"
end

@testset ExtendedTestSet "Custom Units" begin
    @test uconvert(u"kJ",1u"kcal") == 4.184u"kJ"
end

@testset ExtendedTestSet "'scale' NutrientVector operation" begin
    nvA = JSON3.read("""{
        "name":"A",
        "component":[
            { "qty":"10g", "of":"one" },
            { "qty":"15g", "of":"two" },
            { "#":"end" }
        ]
    }""", NutrientVector);
    nv2A = JSON3.read("""{
        "name":"2(A)",
        "component":[
            { "qty":"20g", "of":"one" },
            { "qty":"30g", "of":"two" },
            { "#":"end" }
        ]
    }""", NutrientVector);
    @test string(nv2A) == string(scale(2,nvA))

    nvB = JSON3.read("""{
        "name":"B",
        "component":[
            { "qty":"10g", "custom":"1unit", "of":"one" },
            { "qty":"15g", "custom":"3unit", "of":"two" },
            { "#":"end" }
        ]
    }""", NutrientVector);
    nv2B = JSON3.read("""{
        "name":"2.0(B)",
        "component":[
            { "qty":"20.0g", "custom":"2.0unit", "of":"one" },
            { "qty":"30.0g", "custom":"6.0unit", "of":"two" },
            { "#":"end" }
        ]
    }""", NutrientVector);
    @test string(nv2B) == string(scale(2.0,nvB))
end

@testset ExtendedTestSet "'add' Component operation" begin
    cA1 = JSON3.read("""{ "qty":"100J", "of":"Energy" }""",Component);
    cA2 = JSON3.read("""{ "qty":"3g", "of":"Protein" }""",Component);
    cA3 = JSON3.read("""{ "qty":"4g", "of":"Fat" }""",Component);
    cA4 = JSON3.read("""{ "#":"end" }""",Component);

    cB1 = JSON3.read("""{ "qty":"80J", "of":"Energy" }""",Component);
    cB2 = JSON3.read("""{ "qty":"2g", "of":"Carbs" }""",Component);
    cB3 = JSON3.read("""{ "qty":"7g", "of":"Fat" }""",Component);
    cB4 = JSON3.read("""{ "#":"end" }""",Component);

    cA1plusB1 = JSON3.read("""{ "qty":"180J", "of":"Energy" }""",Component);
    @test string(cA1plusB1) == string(add(cA1,cB1));

    # FIXME: what should we do when two Components aren't addable as a
    # Component?

    # println(add(cA2,cB2))

    # it could be a sensible option to upgrade the sum to the
    # NutrientVector that is the sum of the two NutrientVectors that
    # have only each of them as Components - which is just a
    # NutrientVector with both Components.

    cA3plusB3 = JSON3.read("""{ "qty":"11g", "of":"Fat" }""",Component);
    @test string(cA3plusB3) == string(add(cA3,cB3));
end

@testset ExtendedTestSet "'add' NutrientVector operation" begin
    nvA = JSON3.read("""{
        "name":"A",
        "component":[
            { "qty":"100J", "of":"Energy" },
            { "qty":"3g", "of":"Protein" },
            { "qty":"4g", "of":"Fat" },
            { "#":"end" }
        ]
    }""", NutrientVector);
    # println(componentNames(nvA))
    @test componentNames(nvA) == String["Energy","Protein","Fat"]
    nvB = JSON3.read("""{
        "name":"B",
        "component":[
            { "qty":"80J", "of":"Energy" },
            { "qty":"2g", "of":"Carbs" },
            { "qty":"7g", "of":"Fat" },
            { "#":"end" }
        ]
    }""", NutrientVector);
    @test componentNames(nvB) == String["Energy","Carbs","Fat"]
    nvAplusB = JSON3.read("""{
        "name":"(A)+(B)",
        "component":[
            { "qty":"180J", "of":"Energy" },
            { "qty":"11g", "of":"Fat" },
            { "qty":"3g", "of":"Protein" },
            { "qty":"2g", "of":"Carbs" },
            { "#":"end" }
        ]
    }""", NutrientVector);
    @test componentNames(nvAplusB) == String["Energy","Fat","Protein","Carbs"]
    # println(componentsNamed(nvAplusB,"Energy"));

    # It's a matter of preference whether you want to compare a struct array by...
    # ...mapping string over it, or...
    @test map(string,componentsNamed(nvAplusB,"Energy")) == map(string,Component[JSON3.read("""{ "qty":"180J", "of":"Energy" }""",Component)])
    # @test map(string,componentsNamed(nvAplusB,"Energy")) == map(string,Component[JSON3.read("""{ "qty":"181J", "of":"Energy" }""",Component)])

    # ...string'ifying it as a whole
    @test string(componentsNamed(nvAplusB,"Energy")) == string(Component[JSON3.read("""{ "qty":"180J", "of":"Energy" }""",Component)])
    # @test string(componentsNamed(nvAplusB,"Energy")) == string(Component[JSON3.read("""{ "qty":"181J", "of":"Energy" }""",Component)])

    # Both probably have pros and cons, so get more experience with them to decide.

    @test string(nvAplusB) == string(add(nvA,nvB));

end
