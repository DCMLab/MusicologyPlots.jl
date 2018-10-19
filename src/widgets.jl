using WebIO, Widgets, JSExpr, Interact
using DigitalMusicology

export pianorollwdg

notetodict(note::TimedNote) =
    Dict(:onset => onset(note),
         :offset => offset(note),
         :pitch => convert(Int,pitch(note)))

testnotes = [TimedNote(midi(0),0//1,1//1),
             TimedNote(midi(2),1//1,2//1),
             TimedNote(midi(4),2//1,3//1)]

function pianorollwdg(notes; highlights=[])
    scp = Scope(imports=["https://d3js.org/d3.v4.min.js",
                         joinpath(@__DIR__, "..", "deps", "pianoroll.js")])
    id = string("pianoroll", rand(UInt))

    onotes = Observable(notes)
    setobservable!(scp, "onotes", onotes)
    ohighlights = Observable{Vector{Vector}}(highlights)
    setobservable!(scp, "ohighlights", ohighlights)

    jnotes = map(onotes) do notes
        map(notetodict, notes)
    end
    setobservable!(scp, "jnotes", jnotes)
    jhighlights = map(ohighlights) do hls
        map(hl -> map(notetodict, hl), hls)
    end
    setobservable!(scp, "jhighlights", jhighlights)

    importjs = js"""function(d3) {
                 console.log("test");
                 console.log(d3);
                 var pr = document.getElementById($id);
                 pr.d3 = d3;
                 //pr.notes = $jnotes.val;
                 //pr.highlights = $jhighlights.val;
                 pianoroll($id, $jnotes.val, $jhighlights.val);
             }"""
    
    onimport(scp, importjs)

    on(print, ohighlights)
    on(print, jhighlights)

    #onjs(scp, "onotes", @js x -> console.log("Alloooo"))

    onjs(scp["jnotes"], @js ns -> document.getElementById($id).updateNotes(ns))
    onjs(scp["jhighlights"], @js hls -> document.getElementById($id).updateHighlights(hls))

    #onotes[] = notes

    lay(w) = node(:div,
        scope(w),
        id=id,
        style=Dict("width" => "90%", "background" => "white")
    )

    wdg = Widget([:notes => onotes, :highlights => ohighlights];
                 scope=scp, layout=lay)
end

# function testwdg()
#     scp = Scope(imports="https://d3js.org/d3.v3.min.js")
#     bt = button("Test")
#     setobservable!(scp, "bt", bt)
#     otest = Interact.@map &bt+1
#     setobservable!(scp, "otest", otest)

#     onimport(scp, @js x -> console.log("Hello"))

#     on(bt) do i
#         println("button clicked ($i)")
#     end
#     on(otest) do i
#         println("new value (otest): ", i)
#     end
#     onjs(scp["bt"], @js x -> console.log("Hi"))
#     onjs(scp["otest"], @js x -> console.log("Alloooo "+x))
#     WebIO.ensure_sync(scp, "otest")

#     #scp.dom = dom"div#foo"()
#     wdg = Widget{:test}([:otest => otest], scope=scp, output=otest)
#     @layout! wdg dom"div"(scope(_), bt)
#     #scp(dom"div"())
# end

# servepr() = webio_serve(page("/", r -> pianorollwdg(testnotes)))

# prscriptcanvas = js"""
# """;

# prscript = js"""function(notes) {
#     console.log("starting to parse")
#     notes = JSON.parse(notes);
#     console.log("finished parsing");
#     aspectRatio = 0.5;
#     var margin = {top: 20, right: 30, bottom: 30, left: 40},
#         width = d3.select('#pianoroll').node().getBoundingClientRect().width,
#         height = width*aspectRatio,
#         iwidth = width - margin.right - margin.left,
#         iheight = height - margin.top - margin.bottom;
#     // var noteheight = 10;

#     console.log("scales");
#     var x = d3.scale.linear()
#       .range([0,iwidth])
#       .domain([d3.min(notes, n => n.onset),
#                d3.max(notes, n => n.offset)]);
#     pitchext = d3.extent(notes, n => n.pitch);
#     var y = d3.scale.ordinal()
#       .rangeRoundBands([iheight, 0], .1)
#       .domain(d3.range(pitchext[0], pitchext[1]+1));

#     console.log("axes (objects)");
#     var xAxis = d3.svg.axis().scale(x).orient("bottom");
#     var yAxis = d3.svg.axis().scale(y).orient("left");

#     console.log("svg");
#     d3.select('#pianoroll').select("svg").remove();
#     var pr = d3.select('#pianoroll').append("svg")
#         .attr("width", width)
#         .attr("height", height)
#       .append("g")
#         .attr("transform", 'translate('+margin.left+','+margin.top+')');

#     console.log("notes");
#     var note = pr.selectAll("g")
#         .data(notes)
#       .enter()
#         .append("g");
#     note.append("rect")
#         .attr("width", d => x(d.offset-d.onset))
#         .attr("height", y.rangeBand())
#         .attr("x", d => x(d.onset))
#         .attr("y", d => y(d.pitch));

#     console.log("axes (draw)");
#     pr.append('g')
#         .attr("class", "x axis")
#         .attr("transform", 'translate(0,'+iheight+')')
#         .call(xAxis);
#     pr.append('g')
#         .attr("class", "y axis")
#         .call(yAxis);
# }""";
