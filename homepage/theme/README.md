### Ghost theme for Faer

This theme is based on [Attila](https://github.com/zutrinken/attila/)


## Development

Install [Ghost](https://www.ghost.org) via Docker 

`docker pull ghost`
`docker run -d --name faerGhost -p 8080:2368 ghost` makes Ghost available on http://localhost:8080

Install [Grunt](http://gruntjs.com/getting-started/):

	npm install -g grunt-cli

Install Grunt dependencies:

	npm install

Build Grunt project:

	grunt build

	This creates `faer-ghost-theme.zip`, upload this file as theme in Ghost.

## Copyright & License

Copyright (C) 2015-2017 Peter Amende - Released under the [MIT License](https://github.com/zutrinken/attila/blob/master/LICENSE).