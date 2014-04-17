# Packages
_ = require 'lodash'
_s = require 'underscore.string'
math = require('mathjs')()
iz = require 'iz'

# Type Helpers

# Used to create an object describing the result of the test.
result = (code, msg) ->
  results = {}

  if code is -1
    results.message = "Test written incorrectly. " + msg
    results.condition = 'fail'
    results.color = 'orange'
  else if code
    results.condition = 'pass'
    results.message = "Test passed."
    results.color = 'green'
  else
    results.condition = 'fail'
    results.message = "Test failed."
    results.color = 'red'

  results

# Used to provide multiple options for a test-writer to use in a Math.js expression.
makeVal = (val) ->
  v: val
  val: val
  value: val

# Used to search through a single string multiple times using an array of strings.
search = (str, arr) ->
  for term in arr
    if str.indexOf term >= 0
      return yes
  no

# Used for tests that use mathematical inequalities.
inequalityTest = (expr, val) ->
  unless _.isString expr
    return result -1, "Expression must be a string."

  unless search expr, ['<', '>', '<=', '>=', '==']
    return result -1, "Expression must contain an inequality (<, >, <=, >=, or ==)."

  unless search expr, ['v ', ' v', 'val', 'value']
    return result -1, "Expression must compare against a value (v, val, value)."

  result math.eval expr, makeVal(val)

# Library
library =
  # Check length of an array against an inequality expression.
  length: (obj, expr) ->
    if _.isArray obj
      inequalityTest expr, obj.length
    else
      result -1, "Only arrays can be used with the length test."

  # Check number of keys in an object against an inequality expression.
  count: (obj, expr) ->
    if _.isObject obj
      inequalityTest expr, Object.keys(obj).length
    else
      result -1, "Only objects can be used with the count test."

  # Check existence of a truthy value.
  exists: (obj, key) ->
    unless _.isString key
      return result -1, "Property name must be a string."

    if obj[key]
      result 1
    else
      result 0

  # Check JSON type against Grunt's own type detector.
  kind: (obj, type) ->
    types =
      array:      'isArray'
      object:     'isObject'
      string:     'isString'
      number:     'isNumber'
      boolean:    'isBoolean'
      null:       'isNull'
      undefined:  'isUndefined'

    unless types[type]
      return result -1, "Invalid JSON type was provided."

    return result _[types[type]](obj)

  contains: ->

  checkAgainstMany: ->
    result -1, 'Unimplemented!'

  rules: (obj, rules) ->
    iz.are(rules).validFor obj

  isPhoneNumber: ->
    result -1, 'Unimplemented!'

  isURL: ->
    result -1, 'Unimplemented!'

  isEmailAddress: ->
    result -1, 'Unimplemented!'

module.exports = (type) ->
  library[type]
