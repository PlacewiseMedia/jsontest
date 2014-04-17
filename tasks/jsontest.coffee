# Packages
_ = require 'lodash'
select = require 'JSONSelect'
clc = require 'cli-color'

# Libs
tests = require '../lib/tests'

module.exports = (grunt) ->
  grunt.registerMultiTask 'jsontest', 'Test JSON with CSS-style selectors', ->
    cb = @async()
    files = @filesSrc
    expectations = []

    # Assertions may be declared in a file location string, or explicitly within the gruntfile.
    if grunt.util.kindOf(@data.assert) is 'string'
      assertions = grunt.file.readJSON @data.assert
    else
      assertions = @data.assert

    # Config tests
    for file in files
      if grunt.file.exists file
        json = grunt.file.readJSON file
      else
        grunt.log.error "Could not find JSON file #{file}"
        continue

      for selector, assertion of assertions
        select.forEach selector, json, (obj) ->

          for type, expr of assertion
            expectations.push
              func: tests(type, obj, expr)
              obj: obj
              type: type
              expr: expr
              sel: selector
              assert: assertion

    # Run tests
    results = {}
    results[@target] = expectations.map (expect) ->
      {func, obj, expr} = expect
      expect.result = func(obj, expr)
      expect.result.prettyMessage = clc[expect.result.color](expect.result.message)
      delete expect.result.color
      expect

    # Output results
    for result in results[@target]
      grunt.log.writeln "Tested #{result.sel} using #{result.type} test for #{result.expr}: #{result.result.prettyMessage}"

    # Write results
    if grunt.file.exists @data.dest
      resultsFile = grunt.file.readJSON @data.dest
    else
      resultsFile = {}

    resultsFile[@target] = _.pluck(results[@target], 'result')
    grunt.file.write @data.dest, JSON.stringify(resultsFile, null, 2)

    # Finish
    cb()
