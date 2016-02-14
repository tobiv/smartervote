Blog.config
  title: 'Debattenblog'
  syntaxHighlighting: true
  syntaxHighlightingTheme: 'github'
  pageSize: 100
  blogIndexTemplate: 'myBlogIndex'
  blogShowTemplate: 'myBlogPost'
  excerptFunction: (body) ->
    _.str.prune(body, 392)
  comments: 
    disqusShortname: 'bedingungslos'
  rss:
    title: 'bedingungslos.ch - Debattenblog'
    description: ''
