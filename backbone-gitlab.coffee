# GitLab
# --------------------------------------------------------

window.GitLab = {}
GitLab.url = null

# Extend Backbone.Sync
# --------------------------------------------------------

GitLab.sync = (method, model, options) ->
  extendedOptions = undefined
  extendedOptions = _.extend(
    beforeSend: (xhr) ->
      xhr.setRequestHeader "PRIVATE-TOKEN", GitLab.token if GitLab.token
  , options)
  Backbone.sync method, model, extendedOptions

GitLab.Model = Backbone.Model.extend(sync: GitLab.sync)
GitLab.Collection = Backbone.Collection.extend(sync: GitLab.sync)

# Users
# --------------------------------------------------------

GitLab.User = GitLab.Model.extend(
  backboneClass: "User"
  url: -> "#{GitLab.url}/user"
)

#GitLab.Users = GitLab.Collection.extend(
#  model: GitLab.User
#  url: ->
#    GitLab.url + "/users"
#)

# Client
# --------------------------------------------------------

GitLab.Client = (token) ->
  
  @token    = token

  @user = new GitLab.User()

  return @
    
  #{
  #  User: @Model.extend()
  #  Users: @Collection.extend()
  #  Project: @Model.extend()
  #  Projects: @Collection.extend()
  #}