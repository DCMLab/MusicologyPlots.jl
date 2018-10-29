module MusicologyPlots

using DigitalMusicology
using VegaLite
using DataFrames

export pianoroll, plotpolygrams

function pianoroll(notes; color=nothing, width=800, height=400)
    notedf = DataFrame(pitch=map(note -> convert(Int, pitch(note)), notes),
                       onset=map(onset, notes),
                       offset=map(offset, notes))
    maxp = maximum(notedf[:pitch])
    minp = minimum(notedf[:pitch])
    if color==nothing
        notedf |>
            @vlplot(mark={typ=:rect,clip=true},
                    x = :onset,
                    x2 = :offset,
                    y = {
                        field=:pitch,
                        typ="ordinal",
                        scale={domain=collect(maxp:-1:minp)}
                    },
                    tooltip=:pitch,
                    selection={grid={typ=:interval, bind=:scales}},
                    width=width, height=height)
    else
        notedf |>
            @vlplot(mark={typ=:rect,clip=true},
                    x = :onset,
                    x2 = :offset,
                    y = {
                        field=:pitch,
                        typ="ordinal",
                        scale={domain=collect(maxp:-1:minp)}
                    },
                    color={value=color},
                    tooltip=:pitch,
                    selection={grid={typ=:interval, bind=:scales}},
                    width=wigth, height=height)
    end
end

flatten(v) = vcat(v...)

function plotpolygrams(notes, polys;
                       margin=1, width=800, height=400,
                       start=nothing, stop=nothing)
    #lower = minimum(onset(pgram[1][1]) for pgram in polygrams)
    #upper = maximum(maximum(map(offset, pgram[end])) for pgram in polygrams)
    #inrange(note) = onset(note) > lower-margin && offset(note) < upper+margin
    #bg = pianoroll(notes, color="#888888")
    flattened = map(flatten, polys)
    polynames = map(1:length(flattened)) do i
        fill(string("poly ", i), length(flattened[i]))
    end
    polynotes = flatten(flattened)
    allnotes = vcat(notes, polynotes)
    polydf = DataFrame(pitch=map(note -> convert(Int, pitch(note)), allnotes),
                       onset=map(onset, allnotes),
                       offset=map(offset, allnotes),
                       name=vcat(fill("notes", length(notes)), flatten(polynames)))

    maxp = maximum(polydf[:pitch])
    minp = minimum(polydf[:pitch])
    if start == nothing
        start = minimum(map(onset,polynotes)) - margin
    end
    if stop == nothing
        stop = maximum(map(onset,polynotes)) + margin
    end
    dom = [start, stop]

    polydf |>
        @vlplot(mark={typ=:rect,clip=true},
                x={field=:onset, scale={domain=dom}},
                x2=:offset,
                y={field=:pitch, typ="ordinal", scale={domain=collect(maxp:-1:minp)}},
                color={field=:name, scale={scheme="tableau20"}}, tooltip=:pitch,
                #selection={grid={typ=:interval, bind=:scales}},
                width=width, height=height)
end

include("widgets.jl")

end # module
