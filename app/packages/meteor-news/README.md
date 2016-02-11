meteor news
------------------
Experimental package for news feed.


Usage
-----
- provide a date sanitizer
```
Template.registerHelper 'dateSani', (date) ->
  moment(date).format("LLL")
```


Modify
------
The meteor folder structure has been used in this package and package.js is automatically generated with meteor-package-paths
```
npm install -g meteor-package-paths
```
