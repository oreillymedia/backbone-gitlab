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
  initialize: ->
    @sshkeys = new GitLab.SSHKeys()
)

# SSH Keys
# --------------------------------------------------------

GitLab.SSHKey = GitLab.Model.extend(
  backboneClass: "SSHKey"
)

GitLab.SSHKeys = GitLab.Collection.extend(
  backboneClass: "SSHKeys"
  url: -> "#{GitLab.url}/user/keys"
  model: GitLab.SSHKey
)

# Projects
# --------------------------------------------------------

GitLab.Project = GitLab.Model.extend(
  backboneClass: "Project"
  url: -> "#{GitLab.url}/projects/#{@id || @escaped_path()}"
  initialize: ->
    @branches = new GitLab.Branches([], project:@)
  escaped_path: ->
    return @get("path_with_namespace").replace("/", "%2F")
)

# Branches
# --------------------------------------------------------

GitLab.Branch = GitLab.Model.extend(
  backboneClass: "Branch"
)

GitLab.Branches = GitLab.Collection.extend(
  backboneClass: "Branches"
  url: -> "#{GitLab.url}/projects/#{@project.escaped_path()}/repository/branches"
  initialize: (models, options) ->
    @project = options.project
  model: GitLab.Branch
)

# Client
# --------------------------------------------------------

GitLab.Client = (token) ->
  
  @token  = token
  @user   = new GitLab.User()

  @project = (full_path) ->
    return new GitLab.Project(
      path: full_path.split("/")[1]
      path_with_namespace: full_path
    )

  return @