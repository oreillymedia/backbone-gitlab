window.GitLab = (host, token) ->
  @Model = Backbone.Model.extend()
  @Collection = Backbone.Collection.extend()

  settings =
    host: host
    token: token


  {
    User: @Model.extend()
    Users: @Collection.extend()
    Project: @Model.extend()
    Projects: @Collection.extend()
  }