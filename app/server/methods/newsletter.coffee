Meteor.methods
  'subscribeToNewsletter': (email, lang) ->
    #weired setting by grundeinkommen: D, E, I
    language = lang.substring(0, 1).toUpperCase()
    try
      result = HTTP.post "https://us10.api.mailchimp.com/3.0/lists/#{Meteor.settings.mailchimp.list}/members/",
        auth: "anystring:#{Meteor.settings.mailchimp.apiKey}"
        data: 
          email_address: email
          status: 'pending'
          language: lang
          merge_fields:
            'LANGUAGE': language
      true
    catch error
      content = JSON.parse(error.response.content)
      status = error.response.statusCode
      console.log content
      throw new Meteor.Error("#{status} - #{content.detail}")
    return
