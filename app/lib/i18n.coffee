#stupid work around english can't be deactivated in tap-i18n
#https://github.com/TAPevents/tap-i18n/issues/24#issuecomment-59798528
@LANGUAGES = ['de', 'fr', 'it'] 

I18NConf.configure
  defaultLanguage: 'de'
  languages: LANGUAGES
  autoConfLanguage: true


I18NConf.onLanguageChange (oldLang, newLang) ->
  TAPi18n.setLanguage(newLang)
