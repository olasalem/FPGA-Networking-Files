// -----------------------------------------------------------------------------
//
//   Title  : sliderpanel.js
//   COPYRIGHT (C) 2009 WebPHY
//    _       __     __    ____  __  ____  __  
//   | |     / /__  / /_  / __ \/ / / /\_\/_/  
//   | | /| / / _ \/ __ \/ /_/ / /_/ /  \__/   
//   | |/ |/ /  __/ /_/ / ____/ __  /   / /    
//   |__/|__/\___/_.___/_/   /_/ /_/   /_/  
//  
// 16-bit sliders

<script>



  $(function() {
    // Vertical group
    $('#slider0,#slider1,#slider2,#slider3,#slider4,#slider5').slider({
      orientation: "vertical",
      range: "min",
      value: 32768, 
      min: 0, 
      max: 65535
    });
    $("#slider0").bind('slide',function(event,ui){cmdslider("0xc",ui.value)});
    $("#slider1").bind('slide',function(event,ui){cmdslider("0x2",ui.value)});
    $("#slider2").bind('slide',function(event,ui){cmdslider("0x4",ui.value)});
    $("#slider3").bind('slide',function(event,ui){cmdslider("0x6",ui.value)});
    $("#slider4").bind('slide',function(event,ui){cmdslider("0x8",ui.value)});
    $("#slider5").bind('slide',function(event,ui){cmdslider("0xa",ui.value)});
    // Horizontal group
    $('#slider6,#slider7').slider({
      orientation: "horizontal",
      range: "min",
            animate: true,
      value: 32768, 
      min: 0, 
      max: 65535
    });
    $("#slider6").bind('slide',function(event,ui){cmdslider("0x0",ui.value)});
    $("#slider7").bind('slide',function(event,ui){cmdslider("0xe",ui.value)});
  });
</script>