// -----------------------------------------------------------------------------
//
//   Title  : utils.js
//   COPYRIGHT (C) 2012 WebPHY
//    _       __     __    ____  __  ____  __  
//   | |     / /__  / /_  / __ \/ / / /\_\/_/  
//   | | /| / / _ \/ __ \/ /_/ / /_/ /  \__/   
//   | |/ |/ /  __/ /_/ / ____/ __  /   / /    
//   |__/|__/\___/_.___/_/   /_/ /_/   /_/  
//  
//   All rights reserved.
//
// -----------------------------------------------------------------------------


<script>
  // Add leading zeros to make 16bit value.
  function resizehex16(arg){
    if(arg<16){l="000";}
    else if(arg<256){l="00";}
    else if(arg<4096){l="0";}
    else{l="";}
    var x=l+arg.toString(16);
    return x.toUpperCase();
  }

  // Add leading zeros to make 16bit value.
  function resizehex32(arg){
    if(arg<16){l="0000000";}
    else if(arg<256){l="000000";}
    else if(arg<4096){l="00000";}
    else if(arg<65536){l="0000";}
    else if(arg<1048576){l="000";}
    else if(arg<16777216){l="00";}
    else if(arg<268435456){l="0";}
    else{l="";}
    var x=l+arg.toString(16);
    return x.toUpperCase();
  }
  
  function confirm(output_msg, title_msg,func_ok,func_cancel)
  {
    $("*").mouseup(); // force mouseup event on all elements
    $("<div></div>").html(output_msg).dialog({
      title: title_msg,
      resizable: false,
      show: { 
        effect: 'puff', 
        percent: 50,
        duration: 100
      },
      modal: true,
      position: "center",
      buttons: {
        "Ok": function() 
        {
          $( this ).dialog({
            hide: { 
              effect: ( "drop" ), 
              direction: 'down',
               duration: 300
            }
          });
          $( this ).dialog( "close" );
          func_ok();
        }
      }
    }).css("font-size", "15px");
  }
  
  var _gaq = _gaq || [];
  _gaq.push(['_setAccount', 'UA-52347519-1']);
  _gaq.push(['_trackPageview']);
  (function() {
    var ga = document.createElement('script'); ga.type = 'text/javascript'; ga.async = true;
    ga.src = ('https:' == document.location.protocol ? 'https://ssl' : 'http://www') + '.google-analytics.com/ga.js';
    var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(ga, s);
  })();
  
  // Enable JQuery tooltips
  $(function() {
    $( document ).tooltip();
    $( document ).tooltip( "option", "position", { my: "left+15 center", at: "right center" } );
    $( document ).tooltip({ show: { effect: "fade", duration: 200, delay: 800 } });
  });
  
</script>

// Style JQuery tooltips
<style>
  .ui-tooltip
  {
      background: #e6e68a;
      opacity: 0.95;
      font-size:9pt;
      font-weight:600;
      font-family:Calibri;
      background-color: #e6e68a;
      color:#000000;
      margin:0px;
      padding:0px;
  }
  
  // .ui-tooltip{
    // margin:0px;
    // padding:0px;
    // font-size:10pt;
    // border:1px solid blue;
    // background-color:yellow;
    // position: absolute;
    // z-index: 2;
  // }

</style>