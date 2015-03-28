// -----------------------------------------------------------------------------
//
//   Title  : ledpanel.js
//   COPYRIGHT (C) 2009 WebPHY
//    _       __     __    ____  __  ____  __  
//   | |     / /__  / /_  / __ \/ / / /\_\/_/  
//   | | /| / / _ \/ __ \/ /_/ / /_/ /  \__/   
//   | |/ |/ /  __/ /_/ / ____/ __  /   / /    
//   |__/|__/\___/_.___/_/   /_/ /_/   /_/  
//  
//   All rights reserved.
// In an associative array of 8 bit registers,
// toggle specified bit in specified address,
// update specified LED with specified on and off colors,
// and send as a command to the FPGA.
// usage: cmdtglled('0x6','0x20','svg_6','url(#gradred)','url(#gradreddrk)')
<script>
  // Create a new associative array.
  var myArray = new Array();
  function cmdtglled(addr,bit,ledname_str,color_on,color_off)
  {
    // Grey out until we get a response for this LED/button.
    document.getElementById(ledname_str).style.opacity="0.5";
    // If our index not yet stored, store it and set it to zero.
    if ( typeof myArray[addr] == 'undefined' ) {
      myArray[addr] = 0x00;
    }
    // Flip only specified bit, leaving the other 7 bits alone.
    myArray[addr] = myArray[addr] ^ bit;
    // ledname.style.fill=gray;
    // Add leading zero to the value if necessary 
    // (e.g. 0x9 becomes 0x09) and send write cmd to the FPGA.
    if(addr!=null){
      var m;
      if(myArray[addr]<16){m="0";}
      else{m="";}
      cmd('wr,'+addr+',0x'+m+myArray[addr].toString(16),cbIllumled); //register cb for leds 
      // Unflip
      myArray[addr] = myArray[addr] ^ bit;
    }
    
    // Call this function when (and if) cmd returns, and illuminate
    // LED to signify response.
    function cbIllumled(arg){
      var ledname = document.getElementById(ledname_str);
      // Ungrey, we got the response back.
      document.getElementById(ledname_str).style.opacity="1.0";
      // Reflip if it was successful, otherwise if the response timed out, keep LED the same color it was.
      if (arg!="timeout")
        myArray[addr] = myArray[addr] ^ bit;
        
      if ((myArray[addr] & bit) == bit){
        ledname.style.fill=color_on;
      }
      // Otherwise turn LED off.
      else
      {
        ledname.style.fill=color_off;
      }
      
    }

  }
</script>
