module MusicologyPlots

using DigitalMusicology
using Plots

export pianoroll, pianoroll!, connectednotes!, plotpolygram!, plotpolygrams

# using Plots

# Piano Roll
# ==========

function notes_to_segments(notes)
    xseg = Segments()
    yseg = Segments()
    for note in notes
        p = convert(Int, pitch(note))
        yl    = p - 0.5
        yu    = p + 0.5
        on    = onset(note)
        off   = offset(note)
        push!(xseg, on, off, off, on)
        push!(yseg, yl, yl, yu, yu)
    end
    xseg, yseg
end

function notes_to_shape(notes)
    xs, ys = notes_to_segments(notes)
    Shape(coords(xs), coords(ys))
end

notecenter(note) = (onset(note) + offset(note)) / 2

noteheight(note) = convert(Int, pitch(note))

# @recipe f(::Type{TimedNote}, v::TimedNote) =
#     notes_to_shape([v])


# """
#     pianoroll(onsets, offsets, pitches; kwargs...)

# Plots notes as a pianoroll using Plots.jl.
# """
# function pianoroll end

# """
#     pianoroll!(onsets, offsets, pitches; kwargs...)

# Plots notes as a pianoroll using Plots.jl.
# """
# function pianoroll! end

@userplot PianoRoll

# TODO: make the recipe work.
# What works is plotting shapes directly:
#   plot(map(note_to_shape, ons, offs, pitches), ...)
# but it does not work when used in a recipe:
@recipe function f(pr::PianoRoll)
    #ons, offs, pitches = pr.args
    #x := map(note_to_shape, ons, offs, pitches)
    notes = pr.args[1]
    xseg, yseg = notes_to_segments(notes)
    label = get(plotattributes, :label, "notes")
    hovers = get(plotattributes, :hover,
                 map(n -> "$(pitch(n)): $(onset(n)) - $(offset(n))", notes))
    
    @series begin
        x := coords(xseg)
        y := coords(yseg)
        seriestype := :shape
        label := label
        hover := false
        ()
    end

    @series begin
        x := map(notecenter, notes)
        y := map(noteheight, notes)
        markeralpha := 0
        markerstrokewidth := 0
        seriestype := :scatter
        label := label
        primary := false
        hover := hovers
        ()
    end
end

#function pianoroll(notes::AbstractVector{N}; kwargs...) where {P,T,N<:Note{P,T}}
#    plot(map(note_to_shape, notes); kwargs...)
#end

# function pianoroll(notes::AbstractVector{N}; kwargs...) where {P,T,N<:Note{P,T}}
#     xs, ys = notes_to_segments(notes)
#     plot(Shape(coords(xs), coords(ys)); kwargs...)
# end

# function pianoroll!(notes::AbstractVector{N}; kwargs...) where {P,T,N<:Note{P,T}}
#     plot!(map(note_to_shape, notes); kwargs...)
# end

function connectednotes!(notes::AbstractVector{N}; kwargs...) where {P,T,N<:Note{P,T}}
    Plots.plot!(map(n->(onset(n) + offset(n))/2, notes),
          map(n -> convert(Int, pitch(n)), notes),
          color="black", labels=nothing)
    Plots.plot!(map(MusicologyPlots.note_to_shape, notes); kwargs...)
end

function plotpolygram!(polygram; name="schema", kwargs...)
    plt = nothing
    for (i, stage) in enumerate(polygram)
        plt = connectednotes!(stage, label=string(name, " stage ", i), kwargs...)
    end
    plt
end

function plotpolygrams(notes, polygrams::Vector{Vector{N}}; kwargs...) where {N<:Note}
    plotpolygrams(notes, [polygrams]; kwargs...)
end

function plotpolygrams(notes, polygrams; margin=1, kwargs...)
    lower = minimum(onset(pgram[1][1]) for pgram in polygrams)
    upper = maximum(maximum(map(offset, pgram[end])) for pgram in polygrams)
    inrange(note) = onset(note) > lower-margin && offset(note) < upper+margin
    plt = pianoroll(filter(inrange, notes), label="notes", kwargs...)
    #plt = pianoroll(notes, label="notes", kwargs...)
    
    for (i, poly) in enumerate(polygrams)
        polynotes = vcat(poly...)
        plt = pianoroll!(polynotes; label=string("polygram ", i), kwargs...)
    end
    plt
end

include("vegalite_plots.jl");

end # module
