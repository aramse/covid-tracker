/* TODO
- add screenshot for social cards
- Adjust vertical scale to zoom/fitted curves
- Handle small multiples
- Add world plot on top ?
- Add ratio population ?
- Countries in separate menu with map ?
- add daily new cases as histograms ?
*/

d3.formatDefaultLocale({
  "decimal": ".",
  "thousands": " ",
  "grouping": [3],
  "currency": ["", ""],
});
d3.strFormat = d3.format(",d")
d3.formatShift = function(x) {
  if (!x) return "";
  return d3.format("+d")(x) + " day" + (Math.abs(x) > 1 ? "s": "");
}
d3.defaultColors = [
  "#9FA8DA", "#A5D6A7", "#CE93D8", "#FFE082",
  "#FFAB91", "#E0E0E0", "#40C4FF", "#F48FB1",
  "#FFCC80", "#64FFDA", "#B39DDB", "#E6EE9C",
  "#8C9EFF", "#EF9A9A", "#B0BEC5", "#9FA8DA",
  "#81D4FA", "#80CBC4", "#C5E1A5", "#FFF59D",
  "#BCAAA4", "#EA80FC", "#FF8A80", "#FFE57F"
];
d3.datize = function(d) {
  var dt = new Date(d);
  dt.setHours(0);
  return dt;
}

document.getElementById("corona").style.opacity = 1;
new Vue({
  el: "#corona",
  data: {
    lastUpdateStr: "",
    countries: [],
    defaultCountries: ["Italy", "Iran", "South Korea", "France", "Germany", "Spain", "United States"],
    countriesOrder: null,
    refCountry: null,
    refCountries: [],
    dates: [],
    values: null,
    cases: [
      {id: "confirmed",       selected: false,  total: 0},
      {id: "recovered",       selected: false,  total: 0},
      {id: "deceased",        selected: false,  total: 0},
      {id: "currently sick",  selected: false,  total: 0}
    ],
    logarithmic: false,
    multiples: false,
    resizing: null,
    hoverDate: "",
    extent: null,
    curExtent: null,
    hiddenLeft: 0,
    hiddenRight: 0,
    no_country_selected: [{
      name: "Please select at least one country",
      color: "grey",
      value: "",
      selected: true,
      inactive: true
    }],
    help: false
  },
  computed: {
    case: function() {
      return (this.cases.filter(function(c) { return c.selected; })[0] || {id: null}).id;
    },
    url: function() {
      return this.case +
        (this.logarithmic ? "&log" : "") +
        (this.multiples ? "&multiples" : "") +
        "&countries=" + this.countries
          .filter(function(a) { return a.selected; })
          .map(function(a) { return a.name; }).join(",") +
        (this.refCountry ? "&align=" + this.refCountry : "");
    },
    legend: function() {
      return this.countries.filter(function(a) { return a.selected; });
    },
    refCountrySelected: function() {
      return !!this.refCountry;
    },
    refCountriesSelection: function() {
      return this.refCountries.filter(function(c) {
        return c.selected;
      });
    }
  },
  watch: {
    url: function(newValue) {
      var ref = this.refCountry;
      if (ref && !this.legend.filter(function(c) {
        return c.name === ref;
      }).length) {
        this.refCountry = null;
        newValue = newValue.replace(/&align=.*$/, '');
      }
      window.location.hash = newValue;
    },
    case: function() { this.sortCountries(); },
    countriesOrder: function() { this.sortCountries(); },
    refCountry: function(newValue) {
      if (newValue) {
        var values = this.values,
          dates = this.dates,
          cas = this.case,
          refStart = null,
          refValues = values[newValue][cas];
        this.countries.forEach(function(c) {
          if (c.name === newValue) {
            c.shift = 0;
            c.shiftStr = "";
          } else {
            var shifts = [],
              curVal = null,
              lastVal = null;
            dates.forEach(function(d, i) {
              if (refValues[i] < 20) return;
              for (var j = 1; j < dates.length ; j++) {
                curVal = values[c.name][cas][j];
                if (curVal < refValues[i]) {
                  lastVal = curVal;
                  continue;
                }
                shifts.push(i - j - (refValues[i] - curVal)/(curVal - lastVal));
                break;
              }
            });
            c.shift = Math.round(d3.mean(shifts));
            c.shiftStr = d3.formatShift(c.shift);
          }
        });
      } else this.countries.forEach(function(c) {
        c.shift = 0;
        c.shiftStr = "";
      });
    }
  },
  mounted: function() {
    window.addEventListener("hashchange", this.readUrl);
    window.addEventListener("resize", this.onResize);
    this.download_data();
    setInterval(this.download_data, 3600000);
  },
  methods: {
    onResize: function() {
      if (this.resizing) return clearTimeout(this.resizing);
      this.resizing = setTimeout(this.resize, 50);
    },
    resize: function() {
      var menuH = window.innerHeight - (
        document.querySelector("nav").getBoundingClientRect().height +
        document.getElementById("controls").getBoundingClientRect().height +
        document.getElementById("lowermenu").getBoundingClientRect().height + 2);
      document.getElementById("countries").style.height = menuH + "px";
      this.draw();
      this.resizing = null;
    },
    readUrl: function(startup) {
      var el, options = {countries: []};
      window.location.hash.slice(1).split(/&/).forEach(function(opt) {
        el = decodeURIComponent(opt).split(/=/);
        if (el[0] === "countries")
          options.countries = el[1].split(/,/);
        else if (el[0] === "align")
          options.align = el[1];
        else options[el[0]] = true;
      });
      if (startup) {
        if (!options.countries.length)
          options.countries = this.defaultCountries;
        if (!options.confirmed && !options.recovered && !options.deceased && !options["currently sick"])
          options.confirmed = true;
      }
      this.logarithmic = !!options.log;
      this.multiples = !!options.multiples;
      this.cases.forEach(function(c) {
        c.selected = !!options[c.id];
      });
      this.countries.forEach(function(c) {
        c.selected = ~options.countries.indexOf(c.name);
      });
      this.refCountry = options.align || null;
      this.$nextTick(startup ? this.resize : this.draw);
    },
    download_data: function() {
      var cacheBypass = new Date().getTime();
      d3.json(
        "data/coronavirus-countries.json?" + cacheBypass,
        this.prepareData
      );
    },
    prepareData: function(data) {
      var cases = this.cases;
      cases.forEach(function(cas) {
        cas.total = 0;
      });
      this.countries = Object.keys(data.values)
        .map(function(c) {
          var maxVals = {},
            lastVals = {};
          cases.forEach(function(cas) {
            maxVals[cas.id] = d3.max(data.values[c][cas.id]);
            lastVals[cas.id] = data.values[c][cas.id][data.dates.length - 1];
            cas.total += lastVals[cas.id];
          });
          return {
            id: c.toLowerCase().replace(/[^a-z]/, ''),
            name: c,
            color: "",
            value: null,
            shift: 0,
            shiftStr: "",
            maxValues: maxVals,
            maxStr: "",
            lastValues: lastVals,
            lastStr: "",
            selected: false
          };
        });
      this.refCountries = this.countries.filter(function(c) {
        return c.maxValues['confirmed'] >= 500;
      }).sort(function(a, b) {
        return b.maxValues['confirmed'] - a.maxValues['confirmed'];
      });
      cases.forEach(function(cas) {
        cas.total = d3.strFormat(cas.total);
      });
      if (!this.countriesOrder) this.countriesOrder = "cases";
      this.values = data.values;
      this.dates = data.dates.map(d3.datize);
      this.extent = Math.round((this.dates[this.dates.length - 1] - this.dates[0]) / (1000*60*60*24));
      this.lastUpdateStr = new Date(data.last_update*1000).toUTCString();
      this.readUrl(true);
    },
    selectCase: function(newCase) {
      if (!this.multiples)
        this.cases.forEach(function(c) {
          c.selected = c.id === newCase;
        });
      else {

      }
    },
    sortCountries: function() {
      var cas = this.case,
        field = this.countriesOrder;
      this.countries.sort(function(a, b) {
        if (field === "cases" && a.lastValues[cas] !== b.lastValues[cas])
          return b.lastValues[cas] - a.lastValues[cas];
        else {
          if (b.name > a.name) return -1;
          if (a.name > b.name) return 1;
          return 0;
        }
      });
    },
    draw: function() {
      d3.select(".svg").selectAll("svg").remove();

      // Filter dates from zoom
      var hiddenLeft = this.hiddenLeft,
        hiddenRight = this.hiddenRight,
        zoomedDates = this.dates.slice(hiddenLeft, this.dates.length - hiddenRight).map(function(d) {
          return {
            date: d,
            legend: d3.timeFormat("%a %e %B %Y")(d)
          };
        }),
        start = zoomedDates[0].date,
        end = zoomedDates[zoomedDates.length - 1].date;
      this.curExtent = Math.round((end - start) / (1000*60*60*24));

      // Setup dimensions
      var values = this.values,
        dates = this.dates,
        cas = this.case,
        logarithmic = this.logarithmic,
        margin = {top: 20, right: 90, bottom: 25, left: 60},
        svgW = window.innerWidth - document.querySelector("aside").getBoundingClientRect().width,
        width = svgW - margin.left - margin.right,
        mainH = window.innerHeight - document.querySelector("nav").getBoundingClientRect().height - document.getElementById("legend").getBoundingClientRect().height,
        svgH = Math.max(140, mainH),
        height = svgH - margin.top - margin.bottom,
        xScale = d3.scaleTime().range([0, width]).domain([start, end]),
        xWidth = width / this.curExtent,
        xPosition = function(d) { return xScale(d3.max([start, d.date || d.data.date])) - xWidth/2; },
        maxValues = this.legend.map(function(c) { return c.maxValues[cas]; }),
        yMax = Math.max(0, d3.max(maxValues)),
        yScale = d3[logarithmic ? "scaleLog" : "scaleLinear"]().range([height, 0]).domain([logarithmic ? 1 : 0, yMax]);

      this.countries.forEach(function(c) {
        c.maxStr = d3.strFormat(c.maxValues[cas]);
        c.lastStr = d3.strFormat(c.lastValues[cas]);
      });
      this.legend.sort(function(a, b) {
        return b.maxValues[cas] - a.maxValues[cas];
      }).forEach(function(c, i) {
        c.color = d3.defaultColors[i % d3.defaultColors.length];
      })

      // Prepare svg
      var g = d3.select(".svg")
      .style("height", mainH+"px")
      .append("svg")
        .attr("width", svgW)
        .attr("height", svgH)
        .append("g")
          .attr("transform", "translate(" + margin.left + "," + margin.top + ")");

      // Draw series
      this.legend.forEach(function(c) {
        var shiftedDates = dates.slice(
          Math.max(hiddenLeft, c.shift),
          dates.length - Math.max(hiddenRight, -c.shift)
        ).map(function(d) {
          return {
            date: d,
            legend: d3.timeFormat("%a %e %B %Y")(d)
          };
        });
        g.append("path")
          .datum(shiftedDates)
          .attr("id", c.id)
          .attr("class", "line")
          .attr("fill", "none")
          .attr("stroke", c.color)
          .attr("stroke-linejoin", "round")
          .attr("stroke-linecap", "round")
          .attr("stroke-width", 2)
          .attr("d", d3.line()
            .x(function(d) { return xScale(d.date); })
            .y(function(d, i) {
              var idx = i + Math.max(0, hiddenLeft - c.shift);
              if (logarithmic && values[c.name][cas][idx] == 0)
                return yScale(1);
              return yScale(values[c.name][cas][idx]);
            })
          );
      });

      // Draw axis
      g.append("g")
        .attr("class", "axis axis--x")
        .attr("transform", "translate(0, " + (height) + ")")
        .call(d3.axisBottom(xScale).ticks(8, d3.timeFormat("%b %d")).tickSizeOuter(0));
      g.append("g")
        .attr("class", "axis axis--y")
        .attr("transform", "translate(" + (width) + ", 0)")
        .call(d3.axisRight(yScale).ticks(20, d3.strFormat).tickSizeOuter(0));

      // Draw tooltips surfaces
      g.append("g")
        .selectAll("rect.tooltip")
        .data(zoomedDates).enter().append("rect")
          .classed("tooltip", true)
          .attr("did", function(d, i) { return i; })
          .attr("x", xPosition)
          .attr("y", yScale.range()[1])
          .attr("width", xWidth)
          .attr("height", yScale.range()[0] - yScale.range()[1])
          .on("mouseover", this.hover)
          .on("mousemove", this.displayTooltip)
          .on("mouseleave", this.clearTooltip)
          .on("wheel", this.zoom)
          .on("dblclick", this.zoom);

      this.clearTooltip();

    },
    hover: function(d, i) {
      d3.selectAll('rect[did="' + i + '"]').style("fill-opacity", 0.25);
    },
    displayTooltip: function(d, i, rects) {
      var values = this.values,
        cas = this.case,
        hiddenLeft = this.hiddenLeft;
      this.hoverDate = d.legend;
      this.legend.forEach(function(c) {
        var val = values[c.name][cas][i + hiddenLeft - c.shift];
        if (val == undefined) c.value = "";
        else c.value = d3.strFormat(values[c.name][cas][i + hiddenLeft - c.shift]);
      });
      d3.select(".tooltipBox")
      .style("left", d3.event.pageX - 80 + "px")
      .style("top", d3.event.pageY - 50 + "px")
      .style("display", "block");
    },
    clearTooltip: function(d, i) {
      this.legend.forEach(function(l) {
        l.value = null;
      });
      d3.selectAll('rect[did="' + i + '"]').style("fill-opacity", 0);
      d3.select(".tooltipBox").style("display", "none");
    },
    zoom: function(d, i, rects) {
      var direction = (d3.event.deltaY && d3.event.deltaY > 0 ? -1 : 1),
        days = this.curExtent / 3,
        gauge = (i + 1) / rects.length,
        gaugeLeft = (gauge > 0.05 ? gauge : 0),
        gaugeRight = (gauge < 0.95 ? 1 - gauge : 0);
      if (direction == 1 && this.extent - this.hiddenLeft - this.hiddenRight < 15) return;
      this.clearTooltip();
      this.hiddenLeft += Math.floor(gaugeLeft * days * direction);
      this.hiddenRight += Math.floor(gaugeRight * days * direction);
      if (this.hiddenLeft < 0) this.hiddenLeft = 0;
      if (this.hiddenRight < 0) this.hiddenRight = 0;
      this.draw();
      this.displayTooltip(d, i, rects);
    },
    exportData: function() {
      var a = document.createElement('a');
      a.href = "data/coronavirus-countries.json";
      a.download = "coronavirus-countries.json";
      document.body.appendChild(a);
      a.click();
      document.body.removeChild(a);
    }
  }
});
