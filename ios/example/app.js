var window = Ti.UI.createWindow();
var view = Ti.UI.createView({
    backgroundColor:"white"
});

var label1 = Ti.UI.createLabel({
    text:"Calculating prime",
    width: Ti.UI.FILL,
    height:Ti.UI.FIT,
    textAlign:"center",
    color:"red",
    top:10
});

var label2 = Ti.UI.createLabel({
    text:"Calculating prime",
    width: Ti.UI.FILL,
    height:Ti.UI.FIT,
    textAlign:"center",
    color:"green",
    top:40
});

var label3 = Ti.UI.createLabel({
    text:"Calculating prime",
    width: Ti.UI.FILL,
    height:Ti.UI.FIT,
    textAlign:"center",
    color:"blue",
    top:70
});

var button = Ti.UI.createButton({
    title:"Terminate",
    width:Ti.UI.FIT,
    height:Ti.UI.FIT,
    top:100
});

window.add(view);
view.add(label1);
view.add(label2);
view.add(label3);
view.add(button);
window.open();

var worker = require("ti.worker");

/**
 * create threads
 */
var thread1 = worker.createWorker("prime.js");
thread1.addEventListener("message",function(event){
    label1.text = event.data;
});


var thread2 = worker.createWorker("prime.js");
thread2.addEventListener("message",function(event){
    label2.text = event.data;
});

var thread3 = worker.createWorker("prime.js");
thread3.addEventListener("message",function(event){
    label3.text = event.data;
});

thread1.addEventListener("terminated",function(){
   label1.text = "Terminated"; 
});

thread2.addEventListener("terminated",function(){
   label2.text = "Terminated"; 
});

thread3.addEventListener("terminated",function(){
   label3.text = "Terminated"; 
});

button.addEventListener("click",function(){
   thread1.terminate();
   thread2.terminate();
   thread3.terminate(); 
});

