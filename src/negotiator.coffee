###
negotiator.coffee

A small tool for proxying objects behind a wrapper that can inject
parameters into their methods.

Usage:
  negotiator = require('negotiator')  --for node
  regular script tag for use in the browser.

  //negotiator(object, templateFunction)
  var x = someInstanceOfAClass;
  x.go = function(mission,speed,destination) {
    return [mission, speed, destination];
  }
  wrappedX = negotiator(x, function(speed, destination) {});
  wrappedX('fast','mars').go('victory') ==> ['victory','fast','mars']

  wrappedY = negotiator(x, function(speed, destination) {
    return {speed: 'warp', destination: destination}
  });
  wrappedY('fast','mars').go('victory') ==> ['victory','warp','mars']


Properties of the wrapper:
  __real__    : reference to the object being wrapped.
  __context__ : a map of the paramaters to be injected,
              : set by calling the wrapper.
              : from the above example ---
              : wrappedX.__context__ => {}
              : wrappedX('one','two').__context__ => { one: 1, two: 2 }
              : wrappedX.__context__ => still {}

Caveats:
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
###

# Extract parameter names from a function,
# position is given by position this array.
_ = require('underscore');
utils = {};
utils.parameterNames = (func) ->
  funcArgs = func.toString().split('(')[1].split(')')[0].split(',')
  k.trim() for k in funcArgs

# Inject parameters from a context object into a function.
# Passed parameters are supplied by the 'params' argument.
utils.injectAndApply =  (func, parameters, context, target) ->
  signature = utils.parameterNames func
  parameters = [] if _.isEmpty(parameters)
  for position, name of signature
    parameters[position] = context[name] if context[name]?
  func.apply target ? {}, parameters

# Constructor for proxy object.
utils.Proxy = (real) ->
  @__real__ = real

  self = this

  for key, method of real when typeof method is 'function'
    do (method, key) ->
      self[key] = ->
        utils.injectAndApply method, arguments, @__context__ ? {}, @__real__
  
  this

# Build a context object from an arguments list.
utils.buildContextFromParams = (func, parameters) ->
  signature = utils.parameterNames func
  context = {}
  for key, value of parameters
    context[signature[key]] = value
  context

# This is the circular wrapper that returns a version of itself with
# a set context.
utils.innerWrapper = (proxy, contextBuilder, parameters) ->
  wrapper = ->
    utils.innerWrapper(proxy,contextBuilder,arguments);

  wrapper.__context__ = 
    contextBuilder.apply(proxy, parameters) ?
    utils.buildContextFromParams contextBuilder, parameters
  wrapper.__proto__ = proxy;
  wrapper

# Returns a function that wraps object.
# not intended to be called as a constructor
utils.makeWrapper = (real, contextBuilder) ->
  proxy = new utils.Proxy real
  
  utils.innerWrapper proxy, contextBuilder, []

negotiator = utils.makeWrapper
negotiator.utils = utils;

if module
  module.exports = negotiator
else
  window.negotiator = negotiator

true