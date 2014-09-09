# Blank page
$("#"+id).empty() for id in ["func", "alias_graph", "l1_bar"]

# Helper function
abs = (z) -> (Math.abs(z[k]) for k in [0...z.length])

# Page
m = [20, 20, 20, 80] # margins
width = 400 - m[1] - m[3]
height = 300 - m[0] - m[2]
    
# Alias figure
N = 27  # number of points to evaluate
tmin = -2
tmax = 3
colors = ["red", "blue", "green"] # 1, t, t^2

# Alias quadratic f(t)
f_coeff = (k) -> [k, k/2, 1-k/2]
f = (t, k) -> f_coeff(k).dot([1, t, t*t])

# Function text
f_text = (k) ->
    p = f_coeff(k)
    a = (n) -> Math.round(100*p[n])/100
    s = (n) -> "<span style='color: #{colors[n]}'>#{a(n)}</span>"
    tr = (td1, td2) -> "<tr><td style='text-align:right;'>#{td1}</td><td>#{td2}</td><tr/>"
    """
    <table class='func'>
    #{tr "f(t) = ", s(0)}
    #{tr "+", s(1)+"t"}
    #{tr "+", s(2)+"t<sup>2</sup>"}
    </table>
    """
   
Bar = (k) ->
    @margin = top: 20, right: 30, bottom: 20, left: 50
    @width = 120 - @margin.left - @margin.right
    @height = 300 - @margin.top - @margin.bottom
    @stack = d3.layout.stack().values((d) -> d.values)
    @compute = (k) -> 
        b = (n, k) ->
            key: "Key_"+n,
            values: [{"x": 0, "y": abs(f_coeff(k))[n]}]
        @data = [b(2, k), b(1, k), b(0, k)]
        @keys = @data[0].values.map((item) -> item.x )
        @layers = @stack(@data)
    @compute(k)
    this

Alias = (k) ->         

    # Scale f & t to screen
    t_to_px = d3.scale.linear().domain([tmin, tmax]).range([0, width])
    f_to_px = d3.scale.linear().domain([0,5]).range([height, 0])
    n_to_t = d3.scale.linear().domain([0, N]).range([tmin, tmax])
    
    # Axes: horizontal (t); vertical (f)
    t_axis = d3.svg.axis()
        .scale(t_to_px)
        .ticks(6)
    f_axis = d3.svg.axis()
        .scale(f_to_px)
        .orient("left")
        .ticks(6)

    # N (t,f) points
    @f_data = (k) -> [0...N].map((d) -> {tn: n_to_t(d), fn: f(n_to_t(d), k)})
    fdata = @f_data(k)

    # (t,f) points to SVG    
    @f_svg = d3.svg.line()
        .x((d) -> t_to_px(d.tn))
        .y((d) -> f_to_px(d.fn))

    # Fixed samples
    f0 = [t_to_px(-1), f_to_px(f(-1, k))]
    f1 = [t_to_px(2), f_to_px(f(2, k))]
    samples = [f0, f1]

    # SVG
    
    @graph = d3.select("#alias_graph")
        .append("svg")  
        .attr("width", width + m[1] + m[3])
        .attr("height", height + m[0] + m[2])
        .append("g")
        .attr("transform", "translate(" + m[3] + "," + m[0] + ")")

    @graph.append("g")
        .attr("class", "axis")
        .attr("transform", "translate(0," + height + ")")
        .call(t_axis)
        
    @graph.append("g")
        .attr("class", "axis")
        .attr("transform", "translate(-25,0)")
        .call(f_axis)

    @graph.append("path")
        .attr("d", @f_svg(fdata))
        .attr("id","poly")

    @graph.selectAll("circle")
        .data(samples)
        .enter()
        .append("circle")
        .attr("cx", (d) -> d[0])
        .attr("cy", (d) -> d[1])
        .attr("r", 5)

    # Slider
    @compute = (k) ->
        fdata = @f_data(k)
        @graph.select("#poly")
            .transition()
            .attr("d", @f_svg(fdata))

    this

L1Bar = (bar) ->
 
    @svg = d3.select("#l1_bar").append("svg")
        .attr("width", bar.width + bar.margin.left + bar.margin.right)
        .attr("height", bar.height + bar.margin.top + bar.margin.bottom)
        .append("g")
        .attr("transform", 
            "translate(" + bar.margin.left + "," + bar.margin.top + ")")

    @layer = @svg.selectAll(".layer")
        .data(bar.layers)
        .enter()
        .append("g")
        .attr("class", "layer")
        .style("fill", (d, i) -> colors[2-i])

    @x = d3.scale.ordinal()
        .domain(bar.keys)
        .rangeRoundBands([0, bar.width], 0.08)
        
    @y = d3.scale.linear()
        .domain([0, 5])
        .range([bar.height, 0])

    x = @x
    y = @y

    @layer.selectAll("rect")
        .data((d) -> d.values)
        .enter()
        .append("rect")
        .attr("fill-opacity", 0.5)
        .attr("stroke", "#000")
        .attr("width", x.rangeBand())
        .attr("x", (d) -> d.x)
        .attr("y", (d) -> y(d.y0 + d.y))
        .attr("height", (d) -> y(d.y0) - y(d.y0 + d.y))

    t_axis = d3.svg.axis()
        .scale(x)
        .tickSize(0)
        .tickPadding(6)
        .orient("bottom")

    f_axis = d3.svg.axis()
        .scale(y)
        .ticks(6)
        .tickSize(0)
        .tickPadding(6)
        .orient("left")

    @svg.append("g")
        .attr("class", "axis")
        .call(f_axis)
            
    @compute = ->
        @layer = @svg.selectAll(".layer").data(bar.layers)
        y = @y
        @layer.selectAll("rect")
            .data((d) -> d.values)
            .attr("y", (d) -> y(d.y0 + d.y))
            .attr("height", (d) -> y(d.y0) - y(d.y0 + d.y))
    this

k = -1
bar = new Bar(k)
alias = new Alias(k)
l1Bar = new L1Bar(bar)
d3.select("#func").html(f_text(k))

computeAll = (k) ->
    alias.compute(k)
    bar.compute(k)
    l1Bar.compute()
    d3.select("#func").html(f_text(k))

animate = (from, to, time) ->
    start = new Date().getTime()
    run = ->
        step = Math.min(1, (new Date().getTime()-start)/time)
        k = from + step*(to-from)
        computeAll(k)
        $("#slider").val(k)
        if step is 1
            clearInterval(timer)
            # $("#slider").focus()        
    timer = setInterval (-> run()), 100

setTimeout (-> animate -0.9, 2.9, 3000), 2800

$("#slider").on "change", -> 
    k = parseFloat(d3.select("#slider").property("value"))
    computeAll(k)

d3.selectAll("#sparse1").on "click", -> 
    k = 0
    computeAll(k)
    $("#slider").val(k)
    $("#slider").focus()


