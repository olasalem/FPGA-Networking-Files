// -----------------------------------------------------------------------------
//
//   Title  : webupdate.js
//   COPYRIGHT (C) 2009 WebPHY
//    _       __     __    ____  __  ____  __  
//   | |     / /__  / /_  / __ \/ / / /\_\/_/  
//   | | /| / / _ \/ __ \/ /_/ / /_/ /  \__/   
//   | |/ |/ /  __/ /_/ / ____/ __  /   / /    
//   |__/|__/\___/_.___/_/   /_/ /_/   /_/  
//  
//   All rights reserved.
//
// -----------------------------------------------------------------------------

// Upload the file pointed to by webupld "browse" dialog

<script>
  
  function DoWebUpdate(){
    var fd = new FormData();
    fd.append("webupld", document.getElementById('webupld').files[0]);
    var xhr = new XMLHttpRequest();
    xhr.open("POST", "");
    document.getElementById("btnupld").childNodes[0].nodeValue="Uploading...";
    xhr.send(fd);
    xhr.onreadystatechange=function()
    {
      // Chrome seems to have issues without this...
      document.location.reload();
      if(xhr.readyState==4 && xhr.status==200)
      {
        document.getElementById("btnupld").childNodes[0].nodeValue="Refreshing...";
        document.location.reload();
      }
    }
  }
 
</script>
