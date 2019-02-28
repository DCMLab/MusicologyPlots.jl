function veroviowdg(id, tk, d3, input, highlights, allowselect) {
    var scoreDom = document.getElementById(id);
    var score = d3.select(scoreDom);
    scoreDom.vrvtk = tk;
    scoreDom.d3 = d3;

    var selected = new Set();

    var hlScale = d3.scaleOrdinal(d3.schemeCategory10);
    var selColor = "firebrick";

    // render data
    function render(input) {
        var svg  = tk.renderData(input, {});
        score.selectAll("svg").remove();
        score.html(svg);

        if (allowselect) {
            // add glow filter
            var defs = score.select("svg").append("defs");
            var filter = defs.append("filter")
                .attr("id",id+"glow");
            filter.append("feFlood")
                .attr("result", "flood")
                .attr("flood-color", selColor);
            filter.append("feComposite")
                .attr("in", "flood")
                .attr("in2", "SourceGraphic")
                .attr("operator", "in")
                .attr("result", "mask");
            filter.append("feMorphology")
                .attr("in", "mask")
                .attr("operator", "dilate")
                .attr("radius", "2")
                .attr("result", "thickened");
            filter.append("feGaussianBlur")
                .attr("in", "thickened")
                .attr("stdDeviation","5")
                .attr("result","coloredBlur");
            var feMerge = filter.append("feMerge");
            feMerge.append("feMergeNode")
                .attr("in","colouredBlur");
            feMerge.append("feMergeNode")
                .attr("in","SourceGraphic");

            // register handlers
            score.selectAll(".note")
                .on("mouseover", function () {
                    d3.select(this).style("filter", "url(#"+id+"glow)");
                })
                .on("mouseout", function () {
                    d3.select(this).style("filter", null);
                })
                .on("click", function () {
                    var id = this.id;
                    if (selected.has(id)) {
                        selected.delete(id);
                    } else {
                        selected.add(id);
                    }
                    scoreDom.updateSelectedOut(selected);
                    markNotes(highlights, selected);
                });
        }
    }
    
    function markNotes(highlights, selected) {
        // clear
        score.selectAll(".note").attr("fill", null).attr("stroke", null);

        // highlights
        highlights.forEach(function (group, i) {
            var color = hlScale(i);
            group.forEach(function (note) {
                score.select("g#"+note).attr("fill", color).attr("stroke", color);
            });
        });

        // selection
        selected.forEach(function (note) {
            score.select("g#"+note).attr("fill", selColor).attr("stroke", selColor);
        });
    }
    
    render(input);
    markNotes(highlights, selected);
    
    // input and output
    scoreDom.updateInput = function (newinp) {
        input = newinp;
        highlights = [];
        selected = new Set();
        scoreDom.updateHighlightsOut([]);
        scoreDom.updateSelectedOut([]);
        render(input);
        //markNotes(highlights, selected);
    };

    scoreDom.updateHighlightsIn = function (newhls) {
        highlights = newhls;
        markNotes(highlights, selected);
    };

    scoreDom.updateSelectedIn = function (newsel) {
        selected = new Set(newsel);
        markNotes(highlights, selected);
    };
}
