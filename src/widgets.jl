using WebIO, Widgets, JSExpr, Interact
using DigitalMusicology

export pianorollwdg, clear!

notetodict(note::TimedNote, id=0) =
    Dict(:onset => onset(note),
         :offset => offset(note),
         :pitch => convert(Int,pitch(note)),
         :id => id)

dicttonote(dict) = TimedNote()

testnotes = [TimedNote(midi(0),0//1,1//1),
             TimedNote(midi(2),1//1,2//1),
             TimedNote(midi(4),2//1,3//1)]

"""
    pianorollwdg(notes; highlights=[])

Creates a widgets that shows `notes` in a pianoroll representation.
Optionally, groups of notes can be highlighted
by suppling an array of arrays of notes as `highlights`.
Notes and highlights can be changed and queried by accessing the
observables `:notes` and `:highlights` in the widget, e.g.

    pr[:notes][] = newnotes
"""
function pianorollwdg(notes; highlights=[], allowselect=false, zoomtohl=true)
    # https://d3js.org/d3.v4.min.js
    scp = Scope(imports=[joinpath(@__DIR__, "..", "deps", "d3.v4.min.js"),
                         joinpath(@__DIR__, "..", "deps", "pianoroll.js")])
    id = string("pianoroll", rand(UInt))

    onotes = Observable(scp, "onotes", notes)
    ohighlights = Observable{Vector{Vector}}(scp, "ohighlights", highlights)
    
    jnotes = map(onotes) do notes
        map(notetodict, notes, 1:length(notes))
    end
    setobservable!(scp, "jnotes", jnotes)
    jhighlights = map(ohighlights) do hls
        map(hl -> map(notetodict, hl), hls)
    end
    setobservable!(scp, "jhighlights", jhighlights)

    jselected = Observable(scp, "jselected", [])
    oselected = map(jselected) do sels
        map(sel -> notes[sel+1], sels)
    end

    jclear = Observable(scp, "jclear", nothing)
    
    #setobservable!(scp, "oselected", oselected)

    importjs = @js function (d3)
        @var pr = document.getElementById($id)
        pianoroll($id, d3, $jnotes[], $jhighlights[], $allowselect)
        pr.updateSelectedOut = function (selected)
            console.log(selected)
            $jselected[] = Array.from(selected)
        end
    end
    
    onimport(scp, importjs)

    #onjs(scp, "onotes", @js x -> console.log("Alloooo"))

    onjs(scp["jnotes"], @js ns -> document.getElementById($id).updateNotes(ns))
    onjs(scp["jhighlights"],
         @js hls -> document.getElementById($id).updateHighlights(hls, $zoomtohl))
    onjs(scp["jclear"], @js clr -> document.getElementById($id).clearSel())

    #onotes[] = notes

    lay(w) = node(:div,
        scope(w),
        id=id,
        style=Dict("background" => "white")
    )

    wdg = Widget{:pianoroll}([:notes => onotes, :highlights => ohighlights, :selected => oselected, :clear => jclear];
                             output=oselected, scope=scp, layout=lay)
end

clear!(pr::Widget{:pianoroll}) = pr[:clear][] = nothing

# TODO
function veroviowdg(input)
    # using the fix for emscripten-based dependencies:
    scp = Scope(imports=["https://www.verovio.org/javascript/develop/verovio-toolkit.js"],
                systemjs_options=Dict(
                    "meta" =>
                    Dict("https://www.verovio.org/javascript/develop/verovio-toolkit.js" =>
                         Dict("format" => "global"))))
    id = string("verovioScore", rand(UInt))

    onimport(scp, js"""function(vrv) {
        score = document.getElementById($id);
        score.verovio = vrv;
    }""")
    
    lay(w) = node(:div, scope(w), id=id)
    wdg = Widget([]; scope=scp, layout=lay)
end
