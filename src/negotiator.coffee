###
negotiator.js

A small tool for proxying objects behind a wrapper that can inject
parameters into their methods.
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
  
  return this



# Build a context object from an arguments list.
utils.buildContextFromParams = (func, parameters) ->
  signature = utils.parameterNames func
  context = {}
  for key, value of parameters
    context[signature[key]] = value
  return context


# This is the circular wrapper that returns a version of itself with
# a set context.
utils.innerWrapper = (proxy, contextBuilder, parameters) ->
  wrapper = ->
    utils.innerWrapper(proxy,contextBuilder,arguments);

  wrapper.__context__ = 
    contextBuilder.apply(proxy, parameters) ?
    utils.buildContextFromParams contextBuilder, parameters
  wrapper.__proto__ = proxy;
  return wrapper

# Returns a function that wraps object.
# not intended to be called as a constructor
utils.makeWrapper = (real, contextBuilder) ->
  proxy = new utils.Proxy real
  
  return utils.innerWrapper proxy, contextBuilder, []

negotiator = utils.makeWrapper
negotiator.utils = utils;

if module
  module.exports = negotiator
else
  window.negotiator = negotiator

return