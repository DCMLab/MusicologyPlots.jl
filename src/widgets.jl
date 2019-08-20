using WebIO, Widgets, JSExpr, Interact, AssetRegistry
using DigitalMusicology
using LightXML: XMLDocument

export pianorollwdg, veroviowdg, clear!, jumptonote!

notetodict(note::TimedNote, id=0) =
    Dict(:onset => onset(note),
         :offset => offset(note),
         :pitch => convert(Int,pitch(note)),
         :id => id)

dicttonote(dict) = TimedNote()

testnotes = [TimedNote(midip(0),0//1,1//1),
             TimedNote(midip(2),1//1,2//1),
             TimedNote(midip(4),2//1,3//1)]

jsdep(path...) = joinpath(@__DIR__, "..", "deps", path...)

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

    importjs = @js function (d3)
        @var pr = document.getElementById($id)
        pianoroll($id, d3, $jnotes[], $jhighlights[], $allowselect)
        pr.updateSelectedOut = function (selected)
            $jselected[] = Array.from(selected)
        end
    end
    
    onimport(scp, importjs)

    onjs(scp["jnotes"], @js ns -> document.getElementById($id).updateNotes(ns))
    onjs(scp["jhighlights"],
         @js hls -> document.getElementById($id).updateHighlights(hls, $zoomtohl))
    onjs(scp["jclear"], @js clr -> document.getElementById($id).clearSel())

    lay(w) = node(:div,
        scope(w),
        id=id,
        style=Dict("background" => "white")
    )

    wdg = Widget{:pianoroll}([:notes => onotes, :highlights => ohighlights, :selected => oselected, :clear => jclear];
                             output=oselected, scope=scp, layout=lay)
end

clear!(pr::Widget{:pianoroll}) = pr[:clear][] = nothing

"""
    veroviowdg(input; highlights=[], allowselect=false, format="xml")

Takes as `input` a string in a format understood by verovio (e.g., MusicXML or MEI).
Returns a widget that renders the input using verovio and allows to
control the input as well as highlighted and selected notes using
the `:input`, `:highlights`, and `:selected` kewords.

Both highlights and selections use note ids,
so it makes sense to first set the `xml:id` attributes of notes in the input XML structure,
then feed the XML to this function and use the assigned note ids
to identify notes in the verovio SVG with notes used elsewhere.
While `:selection` is a list of note ids, `:highlights` is a list of note groups,
where each group is displayed in a different color.

The widget includes page controls, but the visible page cannot be directly controlled from Julia.
Instead, one can force the widget to show a specific note using `jumpto!(wdg, "note-id")`.

The selection can be cleared using `clear!(wdg)`.
"""
veroviowdg(xml::XMLDocument; args...) = veroviowdg(string(xml); args...)
function veroviowdg(input; highlights=[], allowselect=false, format="xml")
    # using the fix for emscripten-based dependencies:
    scp = Scope(imports=[jsdep("verovio-toolkit.js"),
                         jsdep("d3.v4.min.js"),
                         jsdep("veroviowdg.js")],
                systemjs_options=Dict(
                    "meta" =>
                    # don't hardcode hash, lookup in AssetRegistry if possible
                    Dict(AssetRegistry.getkey(jsdep("verovio-toolkit.js")) =>
                         Dict("format" => "global"))))
    id = string("verovioScore", rand(UInt))

    # observables
    oinput = Observable(scp, "input", input)
    ohighlights = Observable(scp, "highlights", highlights)
    oselected = Observable(scp, "selected", [])
    ojumpto = Observable(scp, "jumpto", "")
    
    # js setup
    onimport(scp, @js function(vrv, d3, wdg)
                 @var score = document.getElementById($id)
                 @var tk = @new vrv.verovio.toolkit()
                 console.log(wdg);
                 veroviowdg($id, tk, d3, $input, $highlights, $allowselect, $format)
                 #console.log("test2");
                 score.updateSelectedOut = function (selected)
                     $oselected[] = Array.from(selected)
                 end
                 score.updateHighlightsOut = function (highlights)
                     $ohighlights[] = Array.from(highlights);
                 end
             end)

    # handlers
    onjs(scp["input"], @js ns -> document.getElementById($id).updateInput(ns))
    onjs(scp["highlights"], @js hls -> document.getElementById($id).updateHighlightsIn(hls))
    onjs(scp["selected"], @js sel -> document.getElementById($id).updateSelectedIn(sel))
    onjs(scp["jumpto"], @js note -> document.getElementById($id).jumpToNote(note))

    # layout and widget
    lay(w) = node(:div, scope(w), id=id)
    wdg = Widget{:verovio}([:input => oinput,
                            :highlights => ohighlights,
                            :selected => oselected,
                            :jumpto => ojumpto];
                           scope=scp, layout=lay)
end

clear!(vrv::Widget{:verovio}) = vrv[:selected][] = []
jumptonote!(vrv::Widget{:verovio}, note) = vrv[:jumpto][] = note
