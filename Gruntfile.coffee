module.exports = (grunt) ->
  grunt.initConfig
    watch:
      files: ['index.js']
      tasks: ['shell:start']

    shell:
      start:
        command: 'npm run build && node ./bundle.js'

  grunt.loadNpmTasks 'grunt-contrib-watch'
  grunt.loadNpmTasks 'grunt-shell'

  grunt.registerTask 'default', ['watch']
