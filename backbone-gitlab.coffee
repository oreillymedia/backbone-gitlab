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
    @members = new GitLab.Members([], project:@)
  tree: (path, branch) ->
    return new GitLab.Tree([], 
      project:@
      path: path
      branch: branch
    )
  blob: (path, branch) ->
    return new GitLab.Blob(
      name: path
    ,
      branch: branch
      project:@
    )
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

# Members
# --------------------------------------------------------

GitLab.Member = GitLab.Model.extend(
  backboneClass: "Member"
)

GitLab.Members = GitLab.Collection.extend(
  backboneClass: "Members"
  url: -> "#{GitLab.url}/projects/#{@project.escaped_path()}/members"
  initialize: (models, options) ->
    @project = options.project
  model: GitLab.Member
)

# Git Data
# --------------------------------------------------------

GitLab.Blob = GitLab.Model.extend(
  backboneClass: "Blob"
  url: -> 
    "#{GitLab.url}/projects/#{@project.escaped_path()}/repository/blobs/#{@branch || "master"}?filepath=#{@get("name")}"
  initialize: (data, options) ->
    @project = options.project
    @branch = options.branch || "master"
  fetchContent: (options) ->
    @fetch(
      _.extend(dataType:"html", options)
    )
  parse: (response, options) ->
    content: response
)

GitLab.Tree = GitLab.Collection.extend(
  backboneClass: "Tree"
  model: GitLab.Blob
  
  url: -> 
    params = 
      path: @path
      ref_name: @branch
    "#{GitLab.url}/projects/#{@project.escaped_path()}/repository/tree?#{$.param(params)}"
  
  initialize: (models, options) ->
    @project = options.project
    @path = options.path
    @branch = options.branch || "master"
    @trees = []
  
  parse: (resp, xhr) ->
    
    # add trees to trees. we're loosing the tree data but the path here.
    _(resp).filter((obj) =>
      obj.type == "tree"
    ).map((obj) => @trees.push(@project.tree(obj.name, @branch)))

    # add blobs to models. we're loosing the blob data but the path here.
    _(resp).filter((obj) =>
      obj.type == "blob"
    ).map((obj) => @project.blob(obj.name, @branch))
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