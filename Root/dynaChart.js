var chart;
window.onload = function(){
    chart = new CanvasJS.Chart("chartContainer", {
        title :{ text: document.getElementById("name").value },
        data: [{
            type: "area",
            dataPoints: []
        }],
        axisX: { valueFormatString : " " },
        axisY: { suffix: "" }
    });
    load()
}
function addData(xData, yData){
    var xVal = xData instanceof String ? parseFloat(xVal) : xData;
    var yVal = yData instanceof String ? parseFloat(yVal) : yData;
    var arr = chart.options.data[0].dataPoints
    arr.push({
        x: xVal === null ? (arr.length == 0 ? 0 : arr[arr.length -1].x + 1) : parseFloat(xVal),
        y: parseFloat(yVal)
    });
    if (arr.length > 60) { arr.shift(); }
}
function updateChart() {
    fetch("current", { method: "PUT", body: document.getElementById("command").value })
    fetch("exec", { method: "POST", body: "current" } )
    .then(res => res.json().then(data =>{
        if (data instanceof Array)
            data.forEach(element => addData(null, element));                        
        else
            addData(null, data)
        chart.render();
    }))
};
function peek() {
    fetch("current", { method: "PUT", body: document.getElementById("command").value })
    fetch("exec", { method: "POST", body: "current" } )
    .then(res => res.json().then(data => console.log("data: ", data)))
    .catch(reason => console.log("rejected: ", reason))
}
function start () {
    setInterval(updateChart, 2000);
}
function load() {
    fetch(document.getElementById("name").value).then(d=>d.text()).then(d=>document.getElementById("command").value = d)
}
function save() {
    fetch(document.getElementById("name").value, { method: "PUT", body: document.getElementById("command").value })
}