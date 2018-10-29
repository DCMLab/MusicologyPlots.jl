function pianoroll(id, d3, notes, highlights, allowselect) {
    var pr = document.getElementById(id);
    var hovered = null;
    var selected = new Set();
    
    aspectRatio = 0.5;
    var margin = {top: 20, right: 30, bottom: 30, left: 40},
        width, height, iwidth, iheight;
    
    //console.log("scales");
    
    var xScale = d3.scaleLinear()
        .domain([d3.min(notes, n => n.onset),
                 d3.max(notes, n => n.offset)]);
    var x = xScale;
    
    var pitchext = d3.extent(notes, n => n.pitch);
    var y = d3.scaleBand()
        .padding(.1)
        .domain(d3.range(pitchext[0], pitchext[1]+1));

    var hlScale = d3.scaleOrdinal(d3.schemeCategory10);

    //console.log("canvas");
    d3.select(pr).select("canvas").remove();
    var canvas = d3.select(pr).append("canvas")
        .style("transform", "translate("+margin.left+"px,"+margin.top+"px)")
        .style("position", "absolute");
        
    var context = canvas.node().getContext("2d");
    
    //console.log("svg");
    d3.select(pr).select("svg").remove();
    var svg = d3.select(pr).append("svg");
    var gX, gY;

    var currentTrans = d3.zoomIdentity;
    var zoom = d3.zoom()
        .on("zoom", function () {
            currentTrans = d3.event.transform;
            zoompr();
        });
    canvas.call(zoom);
    
    function resize() {
        width = pr.getBoundingClientRect().width,
        height = width*aspectRatio,
        iwidth = width - margin.right - margin.left,
        iheight = height - margin.top - margin.bottom;

        xScale.range([0,iwidth]);
        y.rangeRound([iheight, 0]);
        canvas.attr("width", iwidth).attr("height", iheight);
        svg.select("g").remove();
        var g = svg.attr("width", width).attr("height", height)
          .append("g")
            .attr("transform", "translate("+margin.left+","+margin.top+")");
        gX = g.append("g")
            .attr("transform", "translate(0,"+iheight+")")
            .call(d3.axisBottom(x));
        gY = g.append("g")
            .call(d3.axisLeft(y));
    }
    d3.select(window).on("resize."+id, function() {
        resize();
        zoompr();
    });
    
    function cx(datax) {
        return Math.round(x(datax));
    }

    function cy(datay) {
        return Math.round(y(datay));
    }
    
    function drawNote(note) {
        context.fillRect(cx(note.onset), cy(note.pitch),
                         cx(note.offset)-cx(note.onset),
                         Math.round(y.bandwidth()));
    }

    function strokeNote(note) {
        context.strokeRect(cx(note.onset)+0.5, cy(note.pitch)+0.5,
                           cx(note.offset)-cx(note.onset)-1,
                           Math.round(y.bandwidth()-1));
    }
    
    function drawpr() {
        //console.log("drawpr");
        context.clearRect(0, 0, width, height);

        context.fillStyle = "lightgrey";
        notes.forEach(drawNote);

        highlights.forEach(function(highlight, i) {
            context.fillStyle = hlScale(i);
            highlight.forEach(drawNote);
        });

        context.strokeStyle = "black";
        context.setLineDash([]);
        selected.forEach(i => strokeNote(notes[i]));

        if (hovered !== null) {
            context.setLineDash([10,10]);
            strokeNote(hovered);
        }
    }

    function zoompr() {
        x = currentTrans.rescaleX(xScale);
        gX.call(d3.axisBottom(x));
        drawpr();
    }

    function zoomtohls() {
        var on = d3.min(highlights, hl => d3.min(hl, n => n.onset));
        var off = d3.max(highlights, hl => d3.max(hl, n => n.offset));
        
        if (on !== undefined && off !== undefined) {
            var trans = d3.zoomIdentity
                .scale(iwidth/xScale(off-on+2))
                .translate(-xScale(on-1));
            canvas.call(zoom.transform, trans);
        }
    }

    // selection
    if(allowselect) {
        
        canvas.on("mousemove", function() {
            var mouse = d3.mouse(this);
            var mx = mouse[0],
                my = mouse[1];
            
            hovered = null;
            var nearest = null, mindist = Infinity;
            notes.forEach(function(note) {
                var xon  = x(note.onset),
                    xoff = x(note.offset),
                    ytop = y(note.pitch),
                    ybot = ytop+y.bandwidth();
                if (mx >= xon && mx <= xoff && my >= ytop && my <= ybot) {
                    hovered = note;
                } else {
                    var xdist = Math.max(0, xon-mx, mx-xoff),
                        ydist = Math.max(0, ytop-my, my-ybot); 
                    var dist = Math.sqrt(xdist*xdist + ydist*ydist);
                    if (dist < 10 && dist < mindist) {
                        nearest = note;
                        mindist = dist;
                    }
                }
            });
            if (hovered === null) {
                hovered = nearest;
            }
            
            drawpr();
        });

        canvas.on("mouseout", function() {
            hovered = null;
            drawpr();
        });
        
        canvas.on("click", function() {
            if (hovered === null) {
                selected.clear();
            } else {
                var sel = notes.indexOf(hovered);
                console.log("clicked note: "+sel);
                if (selected.has(sel)) {
                    console.log("removing note "+sel);
                    selected.delete(sel);
                } else {
                    console.log("adding note "+sel);
                    selected.add(sel);
                }
            }
            drawpr();
            if (typeof pr.updateSelectedOut === "function") {
                pr.updateSelectedOut(selected);
            }
        });
    }

    resize();
    zoomtohls();
    drawpr();

    pr.updateNotes = function (newnotes) {
        notes = newnotes;
        highlights = [];

        xScale.domain([d3.min(notes, n => n.onset),
                           d3.max(notes, n => n.offset)]);
        x = xScale;
        gX.call(d3.axisBottom(x));
        
        var pitchext = d3.extent(notes, n => n.pitch);
        y.domain(d3.range(pitchext[0], pitchext[1]+1));
        gY.call(d3.axisLeft(y));

        canvas.call(zoom.transform, d3.zoomIdentity);
        
        drawpr();
    };

    pr.updateHighlights = function (newhls, zoomto) {
        highlights = newhls;
        if (zoomto) {
            zoomtohls();
        }
        drawpr();
    };

    pr.clearSel = function () {
        selected.clear();
        drawpr();
    };

    pr.updateSelectedIn = function (newsel) {
        selected = newsel;
        drawpr();
    };
}
