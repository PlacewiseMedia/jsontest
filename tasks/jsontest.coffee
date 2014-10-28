# Packages
_ = require 'lodash'
select = require 'JSONSelect'
clc = require 'cli-color'
path = require 'path'

# Libs
tests = require '../lib/tests'

module.exports = (grunt) ->
  grunt.registerMultiTask 'jsontest', 'Test JSON with CSS-style selectors', ->
    cb = @async()
    files = @filesSrc
    expectations = []

    # Assertions may be declared in a file location string, or explicitly within the gruntfile.
    if grunt.util.kindOf(@data.assert) is 'string'
      if path.extname(@data.assert) is '.json'
        assertions = grunt.file.readJSON @data.assert
      if path.extname(@data.assert) is '.yaml'
        assertions = grunt.file.readYAML @data.assert
    else
      assertions = @data.assert

    # Config tests
    for file in files
      if grunt.file.exists file
        if path.extname(file) is '.json'
          json = grunt.file.readJSON file
        else if path.extname(file) is '.yaml'
          json = grunt.file.readYAML file
        else
          grunt.log.error "Could not find file #{file}"
      else
        grunt.log.error "Could not find JSON file #{file}"
        continue

      for sel, assertion of assertions
        if _.isArray assertion
          assertion =
            exists_many: assertion

        else if _.isString assertion
          assertion =
            length: 'val > 0'
            print_length_as: assertion

        conf =
          assert: assertion
          negated: no
          warning: no
          file: file

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

        selector = select.compile conf.sel

        matches = selector.match json

        unless matches.length
          grunt.fail.warn "Selector #{conf.sel} didn't find any matches in #{file}."

        selector.forEach json, (obj) ->
          for type, expr of assertion
            # Process any selectors within an assertion, as well. Uses lexic pattern from qonsumer.
            lexics = expr.toString().match /\(.*?\)/g
            if lexics
              for lexic in lexics
                expr_matches = select.match lexic.substring(1, lexic.length - 1), obj
                expr = expr.replace lexic, expr_matches[0] # Hardcoded, always use first result.

            c = _.clone conf
            c.obj = obj
            c.type = type
            c.expr = expr
            c.length = matches.length

            c.test = tests type, c.negated, c.warning

            expectations.push c

    # Helps for warning and dying later.
    warnings = 0
    failures = 0
    passes = 0

    # Expand multis
    many_expectations = []

    for expect in expectations
      {test, obj, expr} = expect
      results = test.run obj, expr

      if _.isArray results
        for result, i in results
          e = _.clone expect
          e.expr = expr[i]
          e.result = result
          many_expectations.push e
      else
        expect.result = results
        many_expectations.push expect

    # Run tests
    results = {}
    results[@target] = many_expectations.map (expect) ->
      {test, obj, expr, result} = expect
      result.prettyMessage = clc[result.color](result.message)
      delete result.color

      if result.condition is 'warn'
        warnings++
      else if result.condition is 'fail'
        failures++
      else if result.condition is 'pass'
        passes++

      expect

    # Output results
    for target in results[@target]
      if target.result.condition is 'info'
        grunt.log.writeln target.result.prettyMessage
      else
        grunt.log.writeln "Found #{target.length}. Tested #{target.sel} in #{target.file} using #{target.type} test for #{target.expr}: #{target.result.prettyMessage}."

    # Write results
    if @data.dest

      if grunt.file.exists @data.dest
        if path.extname(@data.dest) is '.json'
          resultsFile = grunt.file.readJSON @data.dest
        if path.extname(@data.dest) is '.yaml'
          resultsFile = grunt.file.readYAML @data.dest
      else
        resultsFile = {}

      resultsFile[@target] = _.pluck(results[@target], 'result')
      grunt.file.write @data.dest, JSON.stringify(resultsFile, null, 2)

    # Display results
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
