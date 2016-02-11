Template.registerHelper "eq", (a,b) ->
  a is b

Template.registerHelper "dateSani", (date) ->
  return null if !date?
  moment(date)
    .locale(TAPi18n.getLanguage())
    .calendar(null, sameElse: "LLL")
