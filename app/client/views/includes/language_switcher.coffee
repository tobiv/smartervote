Template.languageSwitcher.helpers
  languageKeys: ->
    LANGUAGES

Template.languageSwitcher.events
  'click .languages span': (evt, tmpl) ->
    lang = @toString()
    href = window.location.href
    console.log href
    #workarround I18NConf crashing on language change on
    #excluded routes.
    if href? and href.indexOf('/blog') > -1
      I18NConf.setPersistedLanguage(lang)
      TAPi18n.setLanguage(lang)
      Router.go '/blog/tag/'+lang
      try
        I18NConf.setLanguage lang
      catch e
        console.log e
      I18NConf.languageDep.changed()
      return
    I18NConf.setLanguage lang
