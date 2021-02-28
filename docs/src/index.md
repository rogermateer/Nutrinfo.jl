```@meta
CurrentModule = Nutrinfo
```

# Nutrinfo

Documentation for [Nutrinfo](https://github.com/rogermateer/Nutrinfo.jl).

```@index
```

```@autodocs
Modules = [Nutrinfo]
```

Nutrinfo.jl is a program for tracking energy and macronutrient consumption.

It takes as input two JSON files:

* A nutrient information database, which contains nutritional information about a collection of foodstuffs as an array of JSON objects. This JSON array is validated using https://github.com/fredo-dedup/JSONSchema.jl to ensure that the nutritional information fields are recognised by the program.
* A food diary, which contains information about the user's daily intake of foodstuffs over a period of time.

For now, it produces as output a daily summary of the total energy, macronutrient quantity and macronutrient ratio consumed.

(In future it could be extended to supply micronutrient quantity information and create plots.)

It makes use of https://github.com/JuliaIntervals/IntervalArithmetic.jl to deal with uncertainty in information about nutritional constituents and/or quantities of consumed foodstuffs.

It makes use of https://github.com/PainterQubits/Unitful.jl to deal with standard (energy, capacity, mass) as well as ad-hoc (approximate serving sizes) needs for appropriately processing the kinds of quantities we'll be dealing with.

