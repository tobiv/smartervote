moment.locale 'en', calendar:
  lastDay: '[Yesterday]'
  sameDay: '[Today]'
  nextDay: '[Tomorrow]'
  lastWeek: '[last] dddd'
  nextWeek: 'LL'
  sameElse: 'LL'

moment.locale 'de', calendar:
  lastDay: '[Gestern]'
  sameDay: '[Heute]'
  nextDay: '[Morgen]'
  lastWeek: '[letzen] dddd'
  nextWeek: 'LL'
  sameElse: 'LL'

moment.locale 'fr', calendar:
  lastDay: '[Hier]'
  sameDay: "[Aujourd'hui]"
  nextDay: '[Demain]'
  lastWeek: 'dddd [dernier]'
  nextWeek: 'LL'
  sameElse: 'LL'

moment.locale 'it', calendar:
  lastDay: '[Ieri]'
  sameDay: '[Oggi]'
  nextDay: '[Domani]'
  lastWeek: ->
    switch @day()
      when 0
        return '[la scorsa] dddd'
      else
        return '[lo scorso] dddd'
  nextWeek: 'LL'
  sameElse: 'LL'
