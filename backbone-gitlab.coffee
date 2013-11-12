# Variables
# --------------------------------------------------------

window.GitLab = {}
GitLab.url = null
GitLab.token = null
GitLab.version = "v3"

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

GitLab.User = GitLab.Model.extend()

GitLab.Users = GitLab.Collection.extend(
  model: GitLab.User
  url: ->
    GitLab.url + "/users"
)





#window.GitLab = (host, token) ->
#  @Model = Backbone.Model.extend()
#  @Collection = Backbone.Collection.extend()
#
#  settings =
#    host: host
#    token: token
#
#
#  {
#    User: @Model.extend()
#    Users: @Collection.extend()
#    Project: @Model.extend()
#    Projects: @Collection.extend()
#  }#