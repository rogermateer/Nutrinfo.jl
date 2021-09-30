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

#= 

NutrientVector 'scale' operation:

Multiply a nutrient vector by a given scaling factor by multiplying
the qty and/or custom entries of each of its components by that
scaling factor.

=#

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

#= 

NutrientVector 'add' operation:

Add two nutrient vectors by collecting all of the components of both,
adding the 'qty' and/or 'custom' entries of any components with
matching 'of' entries.

=#

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

#= 

NutrientVector 'resolve' operation: (performed wrt a nutrientDatabase)

Recursively break down any components of a supplied nutrient vector
that have known decompositions (i.e., entries in the nutrientDatabase)
and keep collecting them all into an equivalent nutrient vector until
you reach one that is maximally resolved into its 'basis' vectors.

A 'basis' vector is one of two things.  It could be a genuine
primitive that doesn't have a further nutritionally meaningful
decomposition because it represents a single nutrient.  Or it could be
an ingredient or a meal or whatever other aggregate that could in
principle be nutritionally analysed but for which we in practice
either can't obtain such analysis or haven't yet included it into the
nutrientDatabase against which we are performing the resolution
operation.

Algorithm is as follows:

create a list of the names of all entries in the nutrientDatabase

while (there exists a component in the working nutrient vector that is in this list)
- remove this component from the working nutrient vector
- create a suitably scaled version from its definition in the nutrientDatabase
- add the resulting nutrient vector back to the working nutrient vector  
end

Question: How do you ensure that the algorithm terminates?  You could
easily have mutually recursive definitions...

Answer: As soon as a loop is detected, don't try to resolve the
component in question any further.  Simply regard it as a 'basis'
vector.

Question: How do you detect a loop?

Bear in mind that the definitions in the nutrientDatabase are
themselves allowed to be defined with components that are defined
elsewhere in the nutrientDatabase.  A practical example of where this
is useful is to express standardised meals in terms of their
ingredients (where many different meals could use some of the same
ingredients) and also to include the nutritional analyses of the
ingredients.  A daily log could then easily contain multiple meals
(some perhaps repeated) and/or multiple individual ingredients.  so
entries at different levels of the hierarchy could potentially have to
be resolved multiple times.

Answer: So we don't necessarily have a loop if we resolve a component
with the same name more than once.  But we do have a loop (I think)
iff the resolution of a given component leads directly to the same
component again needing to be resolved.  So perhaps we could maintain
a "call stack" of the components that are currently being resolved,
and call foul if we see we have to resolve a component that is
currently in the call stack.

Question: But when that happens, the attempt to resolve it is detected
to be spurious and should be unwound to regard its entire contribution
to the overall result as a single 'basis' vector, and not a 'basis'
vector plus its non-self-referencing components.  How to accomplish
that?

Answer: Perhaps a good way could be to perform a full lookahead at
each component resolution step to see whether any of its descendent
components end up being itself. If they do, just regard it as a basis
vector and move on.  If they don't, do the iteration of the while loop
in the pseudocode above.

So, revised algorithm is as follows:

create a list of the names of all entries in the nutrientDatabase

while (there exists a component in the working nutrient vector that is in this list
       AND DOESN'T RECURSIVELY RESOLVE TO ITSELF)
- remove this component from the working nutrient vector
- create a suitably scaled version from its definition in the nutrientDatabase
- add the resulting nutrient vector back to the working nutrient vector  
end

And the algorithm for detecting circular resolution is as follows:

SUGGESTION3: Find a Julia library that could have a ready built solution for you to use.
https://www.google.com/search?q=graph+algorithms+julia&oq=julia+graph+algortu&aqs=chrome.1.69i57j0i8i13i30.6338j0j7&sourceid=chrome&ie=UTF-8

eg https://github.com/JuliaGraphs/LightGraphs.jl
https://github.com/JuliaGraphs/LightGraphsExtras.jl
https://github.com/JuliaGraphs/JuliaGraphsTutorials
https://github.com/JuliaGraphs
https://juliagraphs.org/

SUGGESTION2: Follow up on https://stackoverflow.com/questions/261573/best-algorithm-for-detecting-cycles-in-a-directed-graph

SUGGESTION: Strongly consider a dynamic programming solution.

- Create a giant adjacency matrix of all pairs of entries in the
  nutrientDatabase, with all entries initially zero.

- If the definition of A 

# note the top level name of the component
# call the definition of this component the working nutrient vector
#
# while (there exists a component in the working nutrient vector that is in the list of entries in the nutrientDatabase)
# - if the name of this component is the name of the top level component, we have our smoking gun, return true
# - 
# end

=#

@testset ExtendedTestSet "'resolve' NutrientVector operation" begin
    
end
