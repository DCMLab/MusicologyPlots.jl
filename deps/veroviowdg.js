function veroviowdg(id, tk, d3, input, highlights, allowselect, format) {
    var scoreDom = document.getElementById(id);
    var score = d3.select(scoreDom);
    scoreDom.vrvtk = tk;
    scoreDom.d3 = d3;

    var selected = new Set();

    var vrvOpts = {
        pageHeight: 1500,
        adjustPageHeight: true,
        noFooter: true,
        noHeader: true,
        format: format
    };
    tk.setOptions(vrvOpts);

    // render data
    var hlScale = d3.scaleOrdinal(d3.schemeCategory10);
    var selColor = "firebrick";
    
    function render(page) {
        var svg  = tk.renderToSVG(page);
        score.selectAll("div.scorecontainer").remove();
        score.append("div")
            .attr("class", "scorecontainer")
            .html(svg);

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

    // page turning
    var page = 1;
    
    function goToPage(p) {
        var pc = tk.getPageCount();
        if (p < 1 || p > pc)
            return;
        prev.attr("disabled", p == 1 ? true : null);
        next.attr("disabled", p == pc ? true : null);
        page = p;
        render(page);
        markNotes(highlights, selected);
    }
    
    // add buttons
    var prev = score.append("button");
    var next = score.append("button");
    prev.html("Previous Page")
        .attr("disabled", true)
        .on("click", function () {
            goToPage(page-1);
        });
    next.html("Next Page")
        .on("click", function () {
            goToPage(page+1);
        });

    if (allowselect) {
        score.append("button")
            .html("Clear Selection")
            .on("click", function () {
                selected = new Set();
                markNotes(highlights, selected);
            });
    }

    // add content
    tk.loadData(input, format);
    render(page);
    markNotes(highlights, selected);
    
    // input and output
    scoreDom.updateInput = function (newinp) {
        input = newinp;
        highlights = [];
        selected = new Set();
        page = 1;
        scoreDom.updateHighlightsOut([]);
        scoreDom.updateSelectedOut([]);
        tk.loadData(input);
        render(page);
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

    scoreDom.jumpToNote = function (note) {
        var pg = tk.getPageWithElement(note);
        goToPage(pg);
    };
}
