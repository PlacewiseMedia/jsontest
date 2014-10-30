# Packages
_ = require 'lodash'
_s = require 'underscore.string'
math = require 'mathjs'
iz = require 'iz'
validator = require 'validator'

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
    msg = msg or ''

    if code is -1
      new Result 'fail', 'magenta',  "Test written incorrectly: " + msg
    else if code is 2
      new Result 'info', 'cyan',    "Info: " + msg
    else if (code is 0 and @warning) or code is 3
      new Result 'warn', 'yellowBright',  "Warning: " + msg
    else if code is 1 and @negated
      new Result 'fail', 'red',   "Test negated and failed. " + msg
    else if code
      new Result 'pass', 'green',   "Test passed. " + msg
    else if code is 0 and @negated
      new Result 'pass', 'green',   "Test negated and passed. " + msg
    else
      new Result 'fail', 'red',     "Test failed! " + msg

  # Used for tests that use mathematical inequalities. Should be private.
  _inequalityTest: (expr, val) ->
    unless _.isString expr
      return @result -1, "Expression must be a string."

    unless search expr, ['<', '>', '<=', '>=', '==']
      return @result -1, "Expression must contain an inequality (<, >, <=, >=, or ==)."

    unless search expr, ['v ', ' v', 'val', 'value']
      return @result -1, "Expression must compare against a value (v, val, value)."

    @result math.eval(expr, makeVal(val)), "val = #{val}"

  # Check length of an array against an inequality expression.
  length: (obj, expr) ->
    if _.isArray obj
      @_inequalityTest expr, obj.length
    else
      @result -1, "Only arrays can be used with the length test. You provided: #{typeof expr}"

  # Check number of keys in an object against an inequality expression.
  count: (obj, expr) ->
    if _.isObject obj
      @_inequalityTest expr, Object.keys(obj).length
    else
      @result -1, "Only objects can be used with the count test. You provided: #{typeof expr}"

  # Prints the length of the supplied array as an info message.
  print_length_as: (obj, expr) ->
    if _.isArray obj
      @result 2, "There are #{obj.length} #{expr}"
    else
      @result -1, "Only arrays can be used with the length test. You provided: #{typeof expr}"

  # Check existence of a truthy value.
  exists: (obj, key) ->
    unless _.isString key
      return @result -1, "Property name must be a string. You provided: #{typeof key}"

    unless obj
      @result 0, "Nothing supplied to match against `#{key}`"
    else if obj[key]
      @result 1, "`#{key}` found, value was #{obj[key].toString().substr(0, 25)}"
    else if _.isNull obj[key]
      @result 3, "`#{key}` found, but value was null"
    else
      @result 0, "`#{key}` missing"

  exists_many: (obj, arr) ->
    results = []
    if _.isArray arr
      for item in arr
        results.push @exists obj, item
      results
    else
      @result -1, "Only arrays can be used with the exists_many test. What was found: #{typeof arr}"

  # Check JSON type against Lodash type detector.
  kind: (o, t) ->
    types =
      array:      _.isArray
      object:     _.isObject
      string:     _.isString
      number:     _.isNumber
      boolean:    _.isBoolean
      null:       _.isNull
      undefined:  _.isUndefined
      # aliases
      arr:        _.isArray
      obj:        _.isObject
      str:        _.isString
      num:        _.isNumber
      bool:       _.isBoolean
      undef:      _.isUndefined
      # additional validations
      date:       validator.isDate
      url:        validator.isURL
      email:      validator.isEmail
      phone:      validator.isPhone
      postal:     validator.isPostal
      int:        validator.isInt
      float:      validator.isFloat

    unless o
      return @result 0, "Nothing supplied to type as `#{t}`"
    else if _.isString t
      type = t
      obj = o
    else
      obj = o[t.key]
      type = t.val

    unless types[type]
      return @result -1, "Invalid validation type was provided."

    # special case to enable phone number extensions
    if (type is 'phone' and types[type](obj, yes)) or types[type](obj)
      @result 1, "Found #{obj} is #{type}"
    else
      @result 0, "Found #{obj} not #{type}"

  kind_many: (obj, arr) ->
    results = []
    if _.isArray arr
      for item in arr
        results.push @kind obj, item
      results
    else
      @result -1, "Only arrays can be used with the kind_many test. What was found: #{typeof arr}"

  # Contains the provided array of keys. Not recursive.
  containsKeys: (obj, keys) ->
    missingKeys = []

    for k in keys
      unless obj[k]
        missingKeys.push k

    if missingKeys.length
      return @result 0, "Couldn't find the following keys: " + missingKeys.join ', '

    @result 1

  contains: (val, obj) ->
    if _.isArray obj
      for item in obj
        str = item.toString()
        result = str.indexOf val
        if result > -1
          break
    else
      str = obj.toString()
      result = str.indexOf val

    if result > -1
      @result 1, "Found #{val}"
    else
      @result 0, "Couldn't find #{val}"

  # Checks against iz rules.
  rules: (obj, rules) ->
    iz.are(rules).validFor obj

module.exports = (type, negated, warning) ->
  new Tests type, negated, warning
