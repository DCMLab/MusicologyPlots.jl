module VegaPlots

using DigitalMusicology
using VegaLite
using DataFrames

export pianoroll, plotpolygrams

function pianoroll(notes; color=nothing, width=800, height=400)
    notedf = DataFrame(pitch=map(Int ∘ pitch, notes),
                       onset=map(onset, notes),
                       offset=map(offset, notes))
    maxp = maximum(notedf[:pitch])
    minp = minimum(notedf[:pitch])
    if color==nothing
        notedf |>
            @vlplot(mark=:rect,
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
            @vlplot(mark=:rect,
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
                       margin=2, width=800, height=400,
                       start=nothing, stop=nothing)
    #lower = minimum(onset(pgram[1][1]) for pgram in polygrams)
    #upper = maximum(maximum(map(offset, pgram[end])) for pgram in polygrams)
    #inrange(note) = onset(note) > lower-margin && offset(note) < upper+margin
    #bg = pianoroll(notes, color="#888888")
    flattened = map(flatten, polys)
    polynames = map(1:length(flattened)) do i
        fill(string("poly ", i), length(flattened[i]))
    end
    polynotes = vcat(notes, flatten(flattened))
    polydf = DataFrame(pitch=map(Int ∘ pitch, polynotes),
                       onset=map(onset, polynotes),
                       offset=map(offset, polynotes),
                       name=vcat(fill("notes", length(notes)), flatten(polynames)))

    maxp = maximum(polydf[:pitch])
    minp = minimum(polydf[:pitch])
    if start == nothing
        start = minimum(polydf[:onset])
    end
    if stop == nothing
        stop = maximum(polydf[:offset])
    end
    dom = [start, stop]

    polydf |>
        @vlplot(mark=:rect,
                x={field=:onset, scale={domain=dom}},
                x2=:offset,
                y={field=:pitch, typ="ordinal", scale={domain=collect(maxp:-1:minp)}},
                color={field=:name, scale={scheme="tableau20"}}, tooltip=:pitch,
                selection={grid={typ=:interval, bind=:scales}},
                width=width, height=height)
    
    # fg = @vlplot(mark=:rect,
    #              transform=[{filter="datum.name != 'notes'"}],
    #              x={field=:onset, scale={domain=dom}},
    #              x2=:offset,
    #              y={field=:pitch, typ="ordinal", scale={domain=collect(maxp:-1:minp)}},
    #              color={field=:name, scale={scheme="tableau10"}}, tooltip=:pitch,
    #              selection={grid={typ=:interval, bind=:scales}},
    #              width=width, height=height)
    # bg = @vlplot(mark=:rect,
    #              transform=[{filter="datum.name != 'notes'"}],
    #              x={field=:onset, scale={domain=dom}},
    #              x2=:offset,
    #              y={field=:pitch, typ="ordinal", scale={domain=collect(maxp:-1:minp)}},
    #              color={value="#888888"}, tooltip=:pitch,
    #              selection={grid={typ=:interval, bind=:scales}},
    #              width=width, height=height
    #              )

    # polydf |> (bg + fg)
end

end #module
