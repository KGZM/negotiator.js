# negotiator.js #

A small tool for proxying objects behind a wrapper that can inject parameters into their methods.

Requires underscore.

## Usage
Works in node or in the browser.


    negotiator = require('negotiator')
    negotiator(object, templateFunction)

## Example
    var x = someInstanceOfAClass;
    x.go = function(mission,speed,destination) {
      return [mission, speed, destination];
    }
    wrappedX = negotiator(x, function(speed, destination) {});
    wrappedX('fast','mars').go('victory') //['victory','fast','mars']

    wrappedY = negotiator(x, function(speed, destination, $context) {
      $context.speed = 'warp';
      $context.destination = 'mars';
    });
    wrappedY('fast','mars').go('victory') //['victory','warp','mars']


## Context for the templateFunction / default injectables
    $real       | the object being wrapped.
    $proxy      | the proxy being used by the wrapper.
    $wrapper    | a reference to the wrapper itself.
    $context    | a map of the paramaters to be injected
                | set by calling the wrapper.
                | from the above example ---
                | wrappedX.$context // contains default injectables
                | wrappedX('one','two').$context // defaults + { one: 1, two: 2 }
                | wrappedX.$context => // only default injectables again

## Caveats:
  Injected parameters need to be at the end of the parameter list
  they can't be intersperced with regular parameters, or put them at the
  beginning and then have regular access to normal parameters. 
  It's not possible to definitively tell from a method call and from a method 
  description what the caller's intent is, so I opted not to guess.
  
  All the proxies are baked into the proxy when you call negotiator(),
  so don't expect to add any methods to an object afterwards and have them
  appear on the proxy.

  Non-method properties are not proxied, the proxied object's state is
  encapsulated. However, you can set them via any of their own proxied methods 
  or even the template function itself, if you so desired.

Copyright (c) 2012 [Kobie Maitland]