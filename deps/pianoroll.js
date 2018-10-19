function pianoroll(id, notes, highlights) {
    // if (typeof notes === "string") {
    //     notes = JSON.parse(notes);
    // }
    // if (typeof highlights === "string") {
    //     highlights = JSON.parse(highlights);
    // }
    var pr = document.getElementById(id);
    var d3 = pr.d3;
    // var notes = pr.notes;
    // var highlights = pr.highlights;
    
    aspectRatio = 0.5;
    var margin = {top: 20, right: 30, bottom: 30, left: 40},
        width = pr.getBoundingClientRect().width,
        height = width*aspectRatio,
        iwidth = width - margin.right - margin.left,
        iheight = height - margin.top - margin.bottom;
    // var noteheight = 10;

    console.log("scales");
    
    var xScaleOrig = d3.scaleLinear()
        .range([0,iwidth])
        .domain([d3.min(notes, n => n.onset),
                 d3.max(notes, n => n.offset)]);
    var xScale = xScaleOrig;
    
    var pitchext = d3.extent(notes, n => n.pitch);
    var yScale = d3.scaleBand()
        .rangeRound([iheight, 0]) //bottom?
        .padding(.1)
        .domain(d3.range(pitchext[0], pitchext[1]+1));

    var hlScale = d3.scaleOrdinal(d3.schemeCategory10);

    console.log("canvas");
    d3.select(pr).select("canvas").remove();
    var canvas = d3.select(pr).append("canvas")
        .attr("width", iwidth)
        .attr("height", iheight)
        .style("transform", "translate("+margin.left+"px,"+margin.top+"px)")
        .style("position", "absolute");
    
    console.log("svg");
    d3.select(pr).select("svg").remove();
    var svg = d3.select(pr).append("svg")
        .attr("width", width).attr("height", height)
        //.style("position", "absolute")
      .append("g")
        .attr("transform", "translate("+margin.left+","+margin.top+")");
    var gX = svg.append("g")
        .attr("transform", "translate(0,"+iheight+")")
        .call(d3.axisBottom(xScale));
    var gY = svg.append("g")
        .call(d3.axisLeft(yScale));
        
    //var noteSel = custom.selectAll('custom.rect');
    var context = canvas.node().getContext('2d');

    function drawNote(note) {
        context.fillRect(xScale(note.onset), yScale(note.pitch),
                         xScale(note.offset)-xScale(note.onset), yScale.bandwidth());
    }
    
    function drawpr() {
        console.log("drawpr");
        context.clearRect(0, 0, width, height);

        context.fillStyle = "grey";
        notes.forEach(drawNote);

        highlights.forEach(function(highlight, i) {
            context.fillStyle = hlScale(i);
            highlight.forEach(drawNote);
        });
    }

    // var quadTree = d3.geom.quadtree(notes);
    
    function onClick() {
        var mouse = d3.mouse(this);

        var xcl = xScale.invert(mouse[0]);
        var ycl = yScale.invert(mouse[1]);

        var closest = quadTree.find([xcl, ycl]);
        console.log("clicked on "+closest);
    }
    //canvas.on("click", onClick);

    function zoompr() {
        console.log(d3.event.transform);
        
        xScale = d3.event.transform.rescaleX(xScaleOrig);
        gX.call(d3.axisBottom(xScale));
        drawpr();
    }
    
    var zoomBehaviour = d3.zoom()
        //.x(xScale)
        //.scaleExtent([0.1,10])
        .on("zoom", zoompr);
    canvas.call(zoomBehaviour);
    
    drawpr();

    pr.updateNotes = function (newnotes) {
        notes = newnotes;
        highlights = [];

        xScaleOrig.domain([d3.min(notes, n => n.onset),
                           d3.max(notes, n => n.offset)]);
        xScale = xScaleOrig;
        gX.call(d3.axisBottom(xScale));
        
        var pitchext = d3.extent(notes, n => n.pitch);
        yScale.domain(d3.range(pitchext[0], pitchext[1]+1));
        gY.call(d3.axisLeft(yScale));

        drawpr();
    };

    pr.updateHighlights = function (newhls) {
        highlights = newhls;
        drawpr();
    };
}
