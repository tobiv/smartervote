Package.describe({
  name: 'patte:meteor-news',
  version: '0.0.1',
  summary: 'mini news feed for meteor',
  git: 'https://github.com/patte/meteor-news.git',
  documentation: 'README.md'
});

Package.onUse(function(api) {
  api.versionsFrom('1.2.1');
  api.use('ecmascript');
  api.use(['livedata', 'underscore', 'deps', 'templating', 'ui', 'blaze', 'ejson', 'reactive-var', 'jquery', 'less'], 'client');
  api.use(['coffeescript', 'check'], ['client', 'server']);

  api.use('iron:router@1.0.12', ['client', 'server']);
  api.use('tap:i18n@1.7.0', ['client', 'server']);

  api.use('cfs:standard-packages@0.5.9', ['client', 'server']);
  api.use('cfs:gridfs@0.0.33', ['client', 'server']);

  api.use('aldeed:autoform@5.8.1', ['client', 'server']);
  api.use('yogiben:autoform-file@0.4.2', ['client', 'server']);
  api.use('alanning:roles@1.2.14', ['client', 'server']);
  api.use('aldeed:collection2@2.8.0', ['client', 'server']);

  // Generated with: github.com/philcockfield/meteor-package-paths
  api.addFiles('shared/collections/news.coffee', ['client', 'server']);
  api.addFiles('shared/router.coffee', ['client', 'server']);
  api.addFiles('server/publications.coffee', 'server');
  api.addFiles('client/views/news/news_item.html', 'client');
  api.addFiles('client/views/news/news_admin.html', 'client');
  api.addFiles('client/views/news/news_item_edit.html', 'client');
  api.addFiles('client/views/news/news_admin.coffee', 'client');
  api.addFiles('client/views/news/news_item.coffee', 'client');
  api.addFiles('client/views/news/news_item_edit.coffee', 'client');
  api.addFiles('client/stylesheets/article.less', 'client');

});

Package.onTest(function(api) {
  api.use('ecmascript');
  api.use('tinytest');

  // Generated with: github.com/philcockfield/meteor-package-paths
  

});
