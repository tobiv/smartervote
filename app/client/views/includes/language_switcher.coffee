Template.languageSwitcher.helpers
  languageKeys: ->
    LANGUAGES

Template.languageSwitcher.events
  'click .languages span': (evt, tmpl) ->
    I18NConf.setLanguage @toString()
