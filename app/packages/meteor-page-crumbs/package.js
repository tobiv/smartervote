Package.describe({
  name: 'patte:meteor-page-crumbs',
  version: '0.0.1',
  summary: 'mini inline CMS for meteor',
  git: 'https://github.com/patte/meteor-page-crumbs.git',
  documentation: 'README.md'
});

Package.onUse(function(api) {
  api.versionsFrom('1.2.1');
  api.use('ecmascript');
  api.use(['livedata', 'underscore', 'deps', 'templating', 'ui', 'blaze', 'ejson', 'reactive-var', 'reactive-dict', 'random', 'jquery', 'less'], 'client');
  api.use(['coffeescript', 'check'], ['client', 'server']);
  api.use('chuangbo:marked@0.3.5_1', 'client');
  api.use('jeremy:ghostdown@0.4.3', 'client');
  api.use('iron:router@1.0.12', ['client', 'server']);

  // Generated with: github.com/philcockfield/meteor-package-paths
  api.addFiles('shared/collections/_timestamp_hooks.coffee', ['client', 'server']);
  api.addFiles('shared/collections/crumbs.coffee', ['client', 'server']);
  api.addFiles('shared/collections/posts.coffee', ['client', 'server']);
  api.addFiles('shared/router.coffee', ['client', 'server']);
  api.addFiles('server/publications.coffee', 'server');
  api.addFiles('client/views/crumbs/crumb.html', 'client');
  api.addFiles('client/views/posts/post.html', 'client');
  api.addFiles('client/views/posts/posts.html', 'client');
  api.addFiles('client/stylesheets/lib/editor.less', 'client');
  api.addFiles('client/stylesheets/lib/ghostdown.less', 'client');
  api.addFiles('client/views/crumbs/crumb.coffee', 'client');
  api.addFiles('client/views/posts/post.coffee', 'client');
  api.addFiles('client/views/posts/posts.coffee', 'client');
  api.addFiles('client/lib/readmore.min.js', 'client');
  api.addFiles('client/stylesheets/crumbs.less', 'client');
  api.addFiles('client/stylesheets/posts.less', 'client');

});

Package.onTest(function(api) {
  api.use('ecmascript');
  api.use('tinytest');

  // Generated with: github.com/philcockfield/meteor-package-paths
  

});
