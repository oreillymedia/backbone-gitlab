Backbone for the GitLab API
==================================================

`backbone-gitlab` is an open-source JavaScript library built on Backbone.js, to be used in browsers to load data via the GitLab API.


Testing
-------

The library ships with a testing suite that makes requests to a fake [canned](https://github.com/sideshowcoder/canned) server. First you need to install the server globally:

```bash
sudo npm install -g canned
```

Then run this command from the root folder:

```bash
foreman start
```

You're now ready to open the test suite located in `test/index.html` in your browser.