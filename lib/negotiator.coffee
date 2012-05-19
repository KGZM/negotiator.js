###
negotiator.js
 
A small tool for proxying objects behind a wrapper that can inject
parameters into their methods.
###


# Extract parameter names from a function,
# position is given by position this array.
if module
  _ = require('underscore');
else
  _ = window._

utils = {};

utils.parameterNames = (func) ->

  funcArgs = func.toString().split('(')[1].split(')')[0].split(',')

  return (k.trim() for k in funcArgs)


# Inject parameters from a context object into a function.
# Passed parameters are supplied by the 'params' argument.
utils.injectAndApply =(func, parameters, context, target) ->

  signature = utils.parameterNames func
  parameters = [] if _.isEmpty(parameters)

  for position, name of signature
    parameters[position] = context[name] if context[name]?

  parameters.length = signature.length;
  return func.apply target ? {}, parameters


# Constructor for proxy object.
utils.Proxy = (real) ->

  @$real = real
  self = this

  for key, method of real when typeof method is 'function'
    do (method, key) ->
      self[key] = ->
        utils.injectAndApply method, arguments, @$context ? {}, @$real
  
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
utils.innerWrapper = (proxy, templateFunction, parameters) ->
  wrapper = ->
    utils.innerWrapper(proxy,templateFunction,arguments);
    
  context = utils.buildContextFromParams templateFunction, parameters 
  context.$real = proxy.$real
  context.$wrapper = wrapper
  context.$proxy =  proxy
  context.$context = context;
  utils.injectAndApply templateFunction, parameters, context, proxy
  wrapper.$context = context;
  
  wrapper.__proto__ = proxy;

  return wrapper

# Returns a function that wraps object.
# not intended to be called as a constructor
utils.makeWrapper = (real, templateFunction) ->
  proxy = new utils.Proxy real
  
  return utils.innerWrapper proxy, templateFunction, []

negotiator = utils.makeWrapper
negotiator.utils = utils;

if module
  module.exports = negotiator
else
  window.negotiator = negotiator

return