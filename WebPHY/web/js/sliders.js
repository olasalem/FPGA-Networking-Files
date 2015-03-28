// -----------------------------------------------------------------------------
//
//   Title  : sliders.js
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
    $('#slider2,#slider3').slider({
      orientation: "vertical",
      range: "min",
      value: 32768, 
      min: 0, 
      max: 65535
    });
    $("#slider3").bind('slide',function(event,ui){cmdslider("0x0",ui.value)});
    $("#slider2").bind('slide',function(event,ui){cmdslider("0x2",ui.value)});
    
    // Horizontal
    $('#slider0,#slider1').slider({
      orientation: "horizontal",
      range: "min",
      value: 32768, 
      min: 0, 
      max: 65535
    });
    $("#slider0").bind('slidestop',function(event,ui){cmdslider("0x0",ui.value)});
    $("#slider1").bind('slide',function(event,ui){cmdslider("0x0",ui.value)});

    });
</script>