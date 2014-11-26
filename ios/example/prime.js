var n = 1;

var terminated = false; // for the cases of loops we need to check if the worker is terminated or not or it will keep running in the background

worker.addEventListener('terminated', function(){
	terminated = true;
});

// brute force prime number generator
function search() {
    n++;
    var found = true;
    for (var i=2;i<=Math.sqrt(n); i++) 
    {
        if (n % i == 0) 
        {
            found = false;
            break;
        }
    }
    // found prime, send a message and then go again
    if (found) worker.postMessage(n);
	
    !terminated && worker.nextTick(search); // check if the worker is terminated and if not go to nextTick
}

// start the search
search();

