negotiator = require('negotiator');
_ = require('underscore');
assert = require('assert');
var testcount = 0;
var verbose = 0;
function test(actual, expected, message) {
  var pass = _.isEqual(actual,expected);
  console.log("TEST ", ++testcount, ":", pass ? "PASSED" : "FAILED", " >> ", message);
  if(!pass || verbose) {
    console.log("  Actual: ", actual)
    console.log("  Wanted:", expected)
  }
  assert.ok(pass, message)
}

var f1 = function(name, size, toughness, T) {
  return [name, size, toughness, T];
}

var i1 = {T: 5};
var i2 = {T: 3, size: 2}
test(negotiator.utils.parameterNames(f1),['name', 'size', 'toughness', 'T'],
  "Should get the same args out.")
test(negotiator.utils.injectAndApply(f1, [], i1),[undefined, undefined, undefined, 5],
  "Should place undefined for args not in original call.")
test(negotiator.utils.injectAndApply(f1, [], i2),[undefined, 2, undefined, 3],
  "Should place undefined for args not in original call.")
test(negotiator.utils.injectAndApply(f1, ['god'], i2),['god', 2, undefined, 3],
  "Real parameters should show through.")
test(negotiator.utils.injectAndApply(f1, ['god', 7], i2),['god', 2, undefined, 3],
  "Injected parameters should override real parameters.")
test(negotiator.utils.injectAndApply(f1, ['god', 7,'very'], i2),['god', 2, 'very', 3],
  "Injected parameters should override real parameters.")

blorg = {mission: 'tobeawesome'};
blorg.f2 = function(trouble, T, speed) {
  return this.mission;
}

blorg.f3 = function(trouble, T, speed) {
  return [trouble, T, speed];
}
pBlorg = new negotiator.utils.Proxy(blorg);

test(pBlorg.f2(), blorg.f2(),
  "Proxied function should access the real values properly.")
test(pBlorg.f3(1, 2, 3), [1,2,3],
  "Proxied arguments should be available.")
test(negotiator.utils.buildContextFromParams(blorg.f2, [5,3,7]), {trouble: 5, T: 3, speed: 7},
  "Context should be populated from method signature.")

var template = function(one) {
}
test(negotiator.utils.buildContextFromParams(template, [1]), {one: 1},
  "Context built from contextBuilder signature and supplied paramters.");
blorg.f4 = function(one) {
  return one;
}

wBlorg = negotiator(blorg, template);
test(wBlorg(5).$context.one, 5,
  "Function context should be set from template.");
test(wBlorg(5).f4(), wBlorg(5).$context.one, 
  "Context variables should visible within wrapped methods.");
var template2 = function(one, two, $context) {
  $context.one = one;
  $context.two = 9;
}
blorg.f5 = function(one, two) {
  return [one, two];
}
w2 = negotiator(blorg, template2);
test(w2(5,7).f5(), [5,9], 
  "Contextbuilder overrides defaults.")

blorg.f6 = function(one,two) {
  return [one,two]
}
var template3 = function(two) {};
var w3 = negotiator(blorg,template3);
test(w3(9).f6(1), [1,9],
  "Injection should take place with injectable in last position");