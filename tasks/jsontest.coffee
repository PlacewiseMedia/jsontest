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
            exists_many: assertion.map (a) ->
              a.match(/\S+/g)[0]
            kind_many: assertion.reduce( (prev, curr) ->
              spl = curr.match /\S+/g
              if spl[1]
                prev.push
                  key: spl[0]
                  val: spl[1]
              prev
            , [])
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
          grunt.log.writeln clc.yellowBright "Selector #{conf.sel} didn't find any matches in #{@target}. No test made."

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
            c.test.sel = conf.sel

            expectations.push c

    # Expand multis
    many_expectations = []

    for expect in expectations
      { test, obj, expr } = expect
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
      { test, obj, expr, result } = expect

      result.prettyMessage = clc[result.color](result.message)
      result.messages = [result.prettyMessage]
      result.message_counts = [1]

      delete result.color

      if _.isObject expr
        expect.expr = expr.key

      expect.result = result

      expect

    # De-Duplicate
    record = _.clone results[@target], yes

    first = results[@target].shift()
    first.hashes = ["#{first.test.sel} #{first.test.type}"]
    first.exprs = [first.expr]

    deduped = {}
    deduped[@target] = _.reduce(results[@target], (prev, curr) ->
      last = _.last prev
      hash = "#{curr.test.sel} #{curr.test.type}"

      if last.hashes.indexOf(hash) is -1
        curr.result.messages = [curr.result.prettyMessage]
        curr.exprs = [curr.expr]
        curr.hashes = last.hashes.concat hash
        prev.push curr
      else
        msg_index = last.result.messages.indexOf curr.result.prettyMessage

        if msg_index is -1
          last.result.messages.push curr.result.prettyMessage
          last.exprs.push curr.expr
          last.result.message_counts.push 1
        else
          last.result.message_counts[msg_index]++

        prev[prev.length - 1] = last
      prev
    [first])

    # Output results
    grunt.verbose.writeln clc.bold "\nTesting #{@target}\n"
    for target in deduped[@target]
      if target.result.condition is 'info'
        grunt.verbose.writeln '\t' + target.result.prettyMessage
      else
        grunt.verbose.writeln "Tested #{target.sel} using #{target.type} test."

        for message, message_index in target.result.messages
          if target.result.message_counts[message_index] > 1
            grunt.verbose.writeln "\t#{target.result.message_counts[message_index]} similar results for #{target.exprs[message_index]}: #{message}"
          else
            grunt.verbose.writeln "\tResults for #{target.exprs[message_index]}: #{message}"

    # Write results
    if @data.dest
      if grunt.file.exists @data.dest
        filtered = grunt.file.readJSON @data.dest
      else
        filtered = {}

      filtered[@target] = _.map record, (item) ->
        type: item.test.type
        selector: item.test.sel
        expression: item.expr
        condition: item.result.condition
        message: item.result.message

      grunt.file.write @data.dest, JSON.stringify(filtered, null, 2)

    # Display results
    reduce_condition = (condition) ->
      _.reduce record, (prev, curr) ->
        if curr.result.condition is condition
          prev++
        prev
      , 0

    passes = reduce_condition 'pass'
    failures = reduce_condition 'fail'
    warnings = reduce_condition 'warn'

    grunt.log.writeln "\nSummary:"
    grunt.log.writeln clc.greenBright "#{passes} tests passed."

    if warnings
      grunt.log.writeln clc.yellowBright "#{warnings} tests resulted in warnings."

    if failures
      grunt.log.writeln clc.redBright "#{failures} tests failed."

    length = _.filter(record, (obj) -> obj.result.condition isnt 'info').length
    if passes is length
      grunt.log.writeln clc.greenBright "All #{@target} tests passed!"
    else
      grunt.log.writeln clc.yellowBright "#{passes} of #{length} #{@target} tests passed."

    # Finish
    cb()
