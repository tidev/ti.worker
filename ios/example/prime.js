
var n = 1;

// brute force prime number generator
function search()
{
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
    worker.nextTick(search);
}

// start the search
search();

