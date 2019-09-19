            var end = 0; 
            var start = 0; 
            var timeTaken = 1; 
            var oldTimeTaken = 2 ;
            
            var start = new Date().getTime(); 
            
            
            function getRandomColour() {
                
                var letters = 'o123456789ABCDEF'.split('');
                var colour = '#';
                for (var i = 0; i < 6; i++) {
                    colour += letters[Math.floor(Math.random() * 16)]; 
                }
                return colour;
                
            }
            
            function makeShapeAppear() {
                 
                if (oldTimeTaken >= timeTaken) {
                    oldTimeTaken = timeTaken;
                    document.getElementById("oldTimeTaken").innerHTML = timeTaken + "s"; 
                } else {
                    
                    document.getElementById("oldTimeTaken").innerHTML = oldTimeTaken + "s"; 
                }
                
                var top = Math.random() * 400; 
                var left = Math.random() * 400;  
                
                
                
                var width = (Math.random() * 200) + 100;  // this gives us a random number from 100 to 300 
                
                if (Math.random() > 0.5) {
                    document.getElementById("shape").style.borderRadius = "50%";
                } else {
                    
                    document.getElementById("shape").style.borderRadius = "0%";
                }
                
                document.getElementById("shape").style.backgroundColor = getRandomColour(); 
                 
                document.getElementById("shape").style.width =  width + "px";  
                
                document.getElementById("shape").style.height =  width + "px"; 
                
                document.getElementById("shape").style.top =  top + "px"; 
                
                document.getElementById("shape").style.left = left + "px";
            
                document.getElementById("shape").style.display = "block"; 
                
                start = new Date().getTime(); 
            } 
            
            function appearAfterDelay() {
                setTimeout(makeShapeAppear, Math.random()*3000);
            }
            
            
             
            appearAfterDelay(); 
          
            document.getElementById("shape").onclick = function() {
                document.getElementById("shape").style.display = "none"; 
                
                end = new Date().getTime();
                timeTaken = (end - start)/1000;  
                
               
                
                document.getElementById("timeTaken").innerHTML = timeTaken + "s"; 
                
                appearAfterDelay();  
                
            }
            
             
            