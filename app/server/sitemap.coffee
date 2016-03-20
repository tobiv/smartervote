sitemaps.add '/sitemap.xml', ->
  pages = []
  LANGUAGES.forEach (lang) ->
    pages.push
      page: "/#{lang}/smartervote"
      #lastmod: new Date()
      changefreq: 'monthly'
    pages.push
      page: "/#{lang}/smartervote-content"
      #lastmod: new Date()
      changefreq: 'monthly'
  pages
