# Packages
_ = require 'lodash'
_s = require 'underscore.string'
math = require 'mathjs'
iz = require 'iz'

# Private Helpers

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

# Results Class
# Used to create an object describing the result of the test.
class Result
  constructor: (@condition, @color, @message) ->

# Tests Class
# Keeps all the methods accessible by JSON assertions.
class Tests
  constructor: (@type, @negated, @warning) ->
    @run = @[type]

  result: (code, msg) ->
    if code is -1
      new Result 'fail', 'magenta',  "Test written incorrectly: " + msg
    else if code is 2
      new Result 'info', 'cyan',    "Info: " + msg
    else if code
      new Result 'pass', 'green',   "Test passed."
    else if code is 0 and @negated
      new Result 'pass', 'green',   "Test negated and passed."
    else if code is 0 and @warning
      new Result 'warn', 'yellow',  "Warning: " + msg
    else
      new Result 'fail', 'red',     "Test failed!"

  # Used for tests that use mathematical inequalities. Should be private.
  _inequalityTest: (expr, val) ->
    unless _.isString expr
      return @result -1, "Expression must be a string."

    unless search expr, ['<', '>', '<=', '>=', '==']
      return @result -1, "Expression must contain an inequality (<, >, <=, >=, or ==)."

    unless search expr, ['v ', ' v', 'val', 'value']
      return @result -1, "Expression must compare against a value (v, val, value)."

    @result math.eval(expr, makeVal(val)), expr

  # Check length of an array against an inequality expression.
  length: (obj, expr) ->
    if _.isArray obj
      @_inequalityTest expr, obj.length
    else
      @result -1, "Only arrays can be used with the length test."

  # Check number of keys in an object against an inequality expression.
  count: (obj, expr) ->
    if _.isObject obj
      @_inequalityTest expr, Object.keys(obj).length
    else
      @result -1, "Only objects can be used with the count test."

  # Prints the length of the supplied array as an info message.
  print_length_as: (obj, expr) ->
    if _.isArray obj
      @result 2, "There are #{obj.length} #{expr}"
    else
      @result -1, "Only arrays can be used with the length test."

  # Check existence of a truthy value.
  exists: (obj, key) ->
    unless _.isString key
      return @result -1, "Property name must be a string."

    if obj[key]
      @result 1
    else
      @result 0

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
      return @result -1, "Invalid JSON type was provided."

    @result _[types[type]](obj)

  # Contains the provided array of keys. Not recursive.
  containsKeys: (obj, keys) ->
    missingKeys = []

    for k in keys
      unless obj[k]
        missingKeys.push k

    if missingKeys.length
      return @result 0, "Couldn't find the following keys: " + missingKeys.join ', '

    @result 1

  # Checks against iz rules.
  rules: (obj, rules) ->
    iz.are(rules).validFor obj

module.exports = (type, negated, warning) ->
  new Tests type, negated, warning
