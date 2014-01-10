Backbone for the GitLab API
==================================================

`backbone-gitlab` is an open-source JavaScript library built on Backbone.js, to be used in browsers to load data via the [GitLab API](http://api.gitlab.org/).

Compiling
-------

This library is written in Coffeescript, to compile run:

```bash
npm run build-js
```

If you wish to watch for changes, such as when writing new tests, you can run

```bash
npm run watch-js
```

Testing
-------

The library ships with a testing suite that makes requests to a fake [canned](https://github.com/sideshowcoder/canned) server. First you need to install the dependencies:

```bash
npm install
```

Then run this command from the root folder:

```bash
npm run test
```

This command will start up a canned server for stubbing tests and open a [test/index.html](https://github.com/oreillymedia/backbone-gitlab/blob/master/test/index.html) in the browser.


License
-------

[MIT](https://github.com/oreillymedia/backbone-gitlab/blob/master/LICENSE)