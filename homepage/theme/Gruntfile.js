module.exports = function (grunt) {
    'use strict';
    require('load-grunt-tasks')(grunt, {
        pattern: ['grunt-*']
    });

    grunt.initConfig({
        pkg: grunt.file.readJSON('package.json'),
        config: {
            'cssSrcDir': 'build/src/sass',
            'cssTargetDir': 'css',
            'jsSrcDir': 'build/src/js',
            'jsTargetDir': 'js'
        },
        copy: {
            dev: {
                files: [{
                    dest: 'build/assets/images/',
                    src: '**',
                    cwd: 'build/src/images/',
                    expand: true
                }, {
                    dest: 'build/assets/font/',
                    src: '*',
                    cwd: 'build/src/font/',
                    expand: true
                }]
            },
            dist: {
                files: [{
                    dest: 'build/assets/images/',
                    src: '**',
                    cwd: 'build/src/images/',
                    expand: true
                }, {
                    dest: 'build/assets/font/',
                    src: '*',
                    cwd: 'build/src/font/',
                    expand: true
                }]
            }
        },
        clean: {
            dev: ['dev'],
            dist: ['dist'],
            all: ['dev', 'dist']
        },
        sass: {
            dev: {
                options: {
                    includePaths: ['<%= config.cssSrcDir %>'],
                    sourceMaps: true
                },
                files: {
                    'build/assets/<%=  config.cssTargetDir %>/style.css': '<%=  config.cssSrcDir %>/style.scss',
                    'build/assets/<%=  config.cssTargetDir %>/main.css': '<%=  config.cssSrcDir %>/main.scss'
                }
            },
            dist: {
                options: {
                    outputStyle: 'compressed'
                },
                files: {
                    'build/assets/<%=  config.cssTargetDir %>/style.css': '<%=  config.cssSrcDir %>/style.scss',
                    'build/assets/<%=  config.cssTargetDir %>/main.css': '<%=  config.cssSrcDir %>/main.scss'
                }
            }
        },
        cssmin: {
            target: {
                files: [{
                    expand: true,
                    cwd: 'build/src/css',
                    src: ['*.css', '!*.min.css'],
                    dest: 'build/assets/css',
                    ext: '.css'
                }]
            }
        },
        postcss: {
            options: {
                map: true,
                processors: [
                    require('autoprefixer-core')({
                        browsers: ['last 2 versions']
                    })
                ]
            },
            dev: {
                src: 'build/assets/<%=  config.cssTargetDir %>/*.css'
            },
            dist: {
                src: 'build/assets/<%=  config.cssTargetDir %>/*.css'
            }
        },
        uglify: {
            js: {
                files: {
                    'build/assets/<%=  config.jsTargetDir %>/script.js': ['<%=  config.jsSrcDir %>/libs/jquery-*.js', '<%=  config.jsSrcDir %>/**/*.js']
                }
            }
        },
        compress: {
            dist: {
                options: {
                    archive: './faer-homepage-ghost-theme.zip',
                    mode: 'zip'
                },
                files: [{
                        src: ['build/**/**'],
                        dest: '/',
                        expand: true
                    },
                    {
                        src: ['./package.json'],
                        dest: '/build',
                        filter: 'isFile'
                    }
                ]
            }
        },
        watch: {
            css: {
                files: '<%=  config.cssSrcDir %>/**/*.scss',
                tasks: ['sass:dev', 'copy:dev', 'postcss:dev']
            }
        }
    });

    grunt.registerTask('build', [
        'sass:dist',
        'postcss:dist',
        'copy:dist',
        'cssmin',
        'uglify',
        'compress:dist'
    ]);
    grunt.registerTask('default', [
        'sass:dev',
        'postcss:dev',
        'copy:dev',
        'uglify',
        'watch'
    ]);
};