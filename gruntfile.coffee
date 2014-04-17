time = require 'time-grunt'

module.exports = (grunt) ->
  time grunt

  grunt.config.init
    jsontest:
      test_malls:
        src: 'testing/fixtures/mall.json'
        dest: 'testing/results/mall.json'
        assert: 'testing/test/mall.json'
      test_malls_test:
        src: 'testing/results/mall.json'
        dest: 'testing/test_test_results/mall.json'
        assert: 'testing/test_test/mall.json'
      test_malls_fail:
        src: 'testing/fixtures/mall.json'
        dest: 'testing/results/mall_fail.json'
        assert: 'testing/test/mall_fail.json'
      test_malls_fail_test:
        src: 'testing/results/mall_fail.json'
        dest: 'testing/test_test_results/mall_fail.json'
        assert: 'testing/test_test/mall_fail.json'

  grunt.loadNpmTasks task for task in [
    'jsontest'
  ]

  grunt.registerTask 'default', [
    'jsontest:test_malls'
    'jsontest:test_malls_fail'
  ]

  grunt.registerTask 'testtest', [
    'jsontest:test_malls_test'
    'jsontest:test_malls_fail_test'
  ]
