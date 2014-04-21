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

      for sel, assertion of assertions
        conf =
          assert: assertion
          negated: no
          warning: no

        # Process expression for modifiers
        if sel.indexOf('! ') is 0
          conf.negated = yes
          conf.sel = sel.split('! ')[1]
        else if sel.indexOf('!') is 0
          conf.negated = yes
          conf.sel = sel.split('!')[1]
        else if sel.indexOf('? ') is 0
          conf.warning = yes
          conf.sel = sel.split('? ')[1]
        else if sel.indexOf('?') is 0
          conf.warning = yes
          conf.sel = sel.split('?')[1]
        else
          conf.sel = sel

        select.forEach conf.sel, json, (obj) ->

          for type, expr of assertion
            conf.obj = obj
            conf.type = type
            conf.expr = expr

            conf.test = tests type, conf.negated, conf.warning

            expectations.push conf

    # Helps for warning and dying later.
    warnings = 0
    failures = 0
    passes = 0

    # Run tests
    results = {}
    results[@target] = expectations.map (expect) ->
      {test, obj, expr} = expect
      expect.result = test.run obj, expr
      expect.result.prettyMessage = clc[expect.result.color](expect.result.message)
      delete expect.result.color

      if expect.result.condition is 'warn'
        warnings++
      else if expect.result.condition is 'fail'
        failures++
      else if expect.result.condition is 'pass'
        passes++

      expect

    # Output results
    for target in results[@target]
      grunt.log.writeln "Tested #{target.sel} using #{target.type} test for #{target.expr}: #{target.result.prettyMessage}"

    # Write results
    if grunt.file.exists @data.dest
      resultsFile = grunt.file.readJSON @data.dest
    else
      resultsFile = {}

    resultsFile[@target] = _.pluck(results[@target], 'result')
    grunt.file.write @data.dest, JSON.stringify(resultsFile, null, 2)

    grunt.log.writeln "Summary:"
    grunt.log.writeln clc.green "#{passes} tests passed."

    if warnings
      grunt.fail.warn "#{warnings} tests resulted in warnings."

    if failures
      grunt.fail.fatal "#{failures} tests failed."

    if passes is expectations.length
      grunt.log.writeln clc.green "All tests passed!"

    # Finish
    cb()
