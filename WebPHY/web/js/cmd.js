// -----------------------------------------------------------------------------
//
//   Title  : cmd.js
//   COPYRIGHT (C) 2012 WebPHY
//    _       __     __    ____  __  ____  __  
//   | |     / /__  / /_  / __ \/ / / /\_\/_/  
//   | | /| / / _ \/ __ \/ /_/ / /_/ /  \__/   
//   | |/ |/ /  __/ /_/ / ____/ __  /   / /    
//   |__/|__/\___/_.___/_/   /_/ /_/   /_/  
//  
//   All rights reserved.
// -----------------------------------------------------------------------------

// Send command to the WebPHY DATABUS core and await response.
<style>
#disablingDiv
{
    // /* Do not display it on entry */
    display: none;
 
    // /* Display it on the layer with index 1001.
       // Make sure this is the highest z-index value
       // used by layers on that page */
    z-index:1001;
     
    // /* make it cover the whole screen */
    position: absolute;
    top: 0%;
    left: 0%;
    width: 100%;
    height: 100%;
 
    // /* make it white but fully transparent */
    background-color: white;
    opacity:.00;
    filter: alpha(opacity=00);
}
</style>

  <style>
  .ui-progressbar {
    position : relative;
    font-size : 7;
  }
  .progress-label {
    position : absolute;
    left: 50%;
    // text-align : center;
    font-size : 12;
    font-weight : bold;
    // text-shadow : 1px 1px 0 #fff;
  }
  </style>


<script>
  // event listener for page load
  document.addEventListener("DOMContentLoaded", function() {
    // hide the progress bar
    progbarvis('hidden');
  });
  
  // Print text to history window.
  function PrtHst(arg)
  {
    // Update history window with received data.
    du.value=arg;
    // Scroll history window to bottom (NOTE: does NOT work in IE).
    ua=window.navigator.userAgent
    msie=ua.indexOf("MSIE ")
    if(msie<=0)
    t2.scrollTop=t2.scrollHeight;
  }


  // Send command to the WebPHY DATABUS core and await response.
  function cmd(arg,mycallback,hist)
  {
  
    // confirm("Really send parameters to FPGA?","Confirm");
    // alert("hist = "+hist);
    
    sendingcmd=true;
    // Prevent user entry during cmd via invisible div layer
    document.getElementById('disablingDiv').style.display='block';
    // Re-format letter-case for the core.
    arg=arg.toUpperCase().replace(/X/g,"x");
    arg=arg.replace(/WR/g,"wr");
    arg=arg.replace(/RD/g,"rd");
    // Get rid of commas (needed in args for cmd() calls)
    arg=arg.replace(/,/g," ");
    // Add the string to the command history list.
    var command = arg;
    command_history[command_counter++] = command;
    history_counter = command_counter-1;
    // If hist is set to 1, disable writing to history window.
    if (hist != 1) {
      // Write the string to the command line box.
      el=document.getElementById("t1");
      el.value=arg;
    }
    // Set size of data to be read to last 0x val in the arg, presumed to be rd len.
    // This is used for the progress bar.
    gDnldsize=parseInt(arg.substring(arg.lastIndexOf("0x")));
    // Send the string to the FPGA core via HTTP POST.
    xhr=new XMLHttpRequest();
    // Add the download progress bar listener.
    xhr.addEventListener("progress", updateProgress, false);
    // If hist is set to 1, disable writing to history window.
    if (hist != 1) {
      // Put <cr> in front of wr and rd commands so they always go on new lines.
      var lstcmd=arg.replace(/wr/g,"\nwr");
      lstcmd=lstcmd.replace(/rd/g,"\nrd");
      // Concatenate onto end of existing history text.
      // Get js handle to text history box.
      du=document.getElementById("t2"); 
      rp=du.value+lstcmd;
    }
    // Register a callback for the response.
    xhr.onreadystatechange=function()
    {
      //alert('xhr.readyState= '+xhr.readyState);
      // When the HTML response is complete,
      // clearTimeout(xmlHttpTimeout);
      // var xmlHttpTimeout=setTimeout(ajaxTimeout,3000);
      if(xhr.readyState==4 && xhr.status==200)
      {
        clearTimeout(xmlHttpTimeout);
        xhr.onreadystatechange = null;
        sendingcmd=false;
        // Re-enable user entry
        document.getElementById('disablingDiv').style.display='none';

        // // Select (highlight) the text in the command line box
        // // so that typing will always focus on the command line.
        // poo=document.getElementById("t1");
        // poo.select();
        // If the string we sent was a rd command, append the returned data into
        // the history window.
        // indexOf returns the position of "rd" in "arg". If not found, it will return -1.
        if(arg.indexOf("rd") !== -1)
          confirm("rd commands are not supported in the demo version","Warning",null);
        // If hist is set to 1, disable writing to history window.
        if (hist != 1) {
          // Scroll history window to bottom (NOTE: does NOT work in IE).
          PrtHst(rp);
          // Call specified callback and pass returned data.
          mycallback('0x'+xhr.responseText);
        }
      }
    }
    // POST the command, with asynchronous callback!
    xhr.open("POST",arg,true);
    xhr.send();
      
    // Timeout on HTTP POSTs to WebPHY core, ungrey controls.
    // Don't set time out for reads (this is a hack, need to fix!)
    if(arg.indexOf("rd") == -1) 
      var xmlHttpTimeout=setTimeout(ajaxTimeout,3000);
    function ajaxTimeout(){
       xhr.abort();
       mycallback("timeout");
       PrtHst(rp+" - no response!");
       sendingcmd=false;
       // Re-enable user entry
       document.getElementById('disablingDiv').style.display='none';   
    }
    
    MAXDEMO = 100;
    if (command_counter == MAXDEMO / 2){
      
	
      // $( "#slider1" ).mouseup();
      $("*").mouseup(); // force mouseup event
      confirm("The demo version will stop functioning after 100 web transactions.  To resume, the FPGA must be reinitialized.","Warning",null);
    }
    // Need to use this for IE8 according to this: 
    // http://stackoverflow.com/questions/1018705/how-to-detect-timeout-on-an-ajax-xmlhttprequest-call-in-the-browser
    // var xmlHttp = new XMLHttpRequest();
    // xmlHttp.ontimeout = function(){
      // alert("request timed out");
    // }
  } 
 
  // Globals
  // command history vars
  command_history = []; 
  command_counter = -1;
  history_counter = -1;
  
  // sending cmd flag
  var sendingcmd=false;
    
  // 'rd' command progress bar
  var gDnldsize = 0;
  function updateProgress(evt)
  {
    // There are two bytes for each ASCII-coded binary byte.
    var percentComplete = (evt.loaded / (gDnldsize*2))*100;
    $('#progressbar').progressbar( "option", "value", percentComplete );
  }
  
  // Command line behavior
  function cmdline_keypress(e){
    var code=e.keyCode? e.keyCode : e.charCode
    gr=document.getElementById("t1");
    // When enter is hit, call cmd to send to FPGA.
    if(code == 13){
      cmd(gr.value)
    // When up or down is hit, traverse cmd history and display in cmd line.
    }else if(code == 38){
      if(history_counter>=0){
        gr.value = command_history[--history_counter];
      }
    }else if(code == 40){
      if(history_counter<command_counter-1){
        gr.value = command_history[++history_counter];
      }
    }
  }

  // If we're waiting for a HTTP response from a previous cmd, 
  // don't move the slider.  Otherwise let slider send command.
  function cmdslider(addr,data){
    if (!sendingcmd){
      cmd('wr,'+addr+',0x'+resizehex16(data)); 
    }
  }

  // Progress bar
  $(function() {
    $( "#progressbar" ).progressbar({
      value: 0,
      max: 100,
      change: function() {
        // Get the % val from progress bar, round it, and set progress-label css element assigned to progress bar with this val
        // to display it as an overlay on the progress bar.
        $( ".progress-label" ).text( Math.ceil($( "#progressbar" ).progressbar( "value" )) + "%" );
      }
    });
   // set color of progressbar (sets color of % text too :( )
   // $('#progressbar > div').css({background: '#729fcf'});
   // $('#progressbar').css({background: '#729fcf'});
  });
  
  // Hide/show progress bar (set 'visible' or 'hidden')
  function progbarvis(arg){
    // alert("trying to hide");
    document.getElementById('progressbar').style.visibility=arg;
  }

  // When page loads, hide progress bar.
  window.onload=progbarvis('hidden'); 
    
</script>
