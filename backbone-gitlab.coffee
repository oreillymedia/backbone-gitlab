# Client
# --------------------------------------------------------

GitLab = (url, token) ->

  root = @
  @url    = url
  @token  = token

  # Sync
  # --------------------------------------------------------

  @sync = (method, model, options) ->
    extendedOptions = undefined
    extendedOptions = _.extend(
      beforeSend: (xhr) ->
        xhr.setRequestHeader "PRIVATE-TOKEN", root.token if root.token
    , options)
    Backbone.sync method, model, extendedOptions

  @Model = Backbone.Model.extend(sync: @sync)
  @Collection = Backbone.Collection.extend(sync: @sync)

  # Users
  # --------------------------------------------------------

  @User = @Model.extend(
    backboneClass: "User"
    url: -> "#{root.url}/user"
    initialize: ->
      @sshkeys = new root.SSHKeys()
  )

  # SSH Keys
  # --------------------------------------------------------

  @SSHKey = @Model.extend(
    backboneClass: "SSHKey",
    initialize: ->
      @truncate()

    truncate: ->
      key = @get('key')
      key_arr = key.split(/\s/)

      if typeof key_arr is "object" and key_arr.length is 3
        truncated_hash = key_arr[1].substr(-20)
        @set "truncated_key", "...#{truncated_hash} #{key_arr[2]}"
      else
        @set "truncated_key", key
      true

  )

  @SSHKeys = @Collection.extend(
    backboneClass: "SSHKeys"
    url: -> "#{root.url}/user/keys"
    model: root.SSHKey
  )

  # Project
  # --------------------------------------------------------

  @Project = @Model.extend(
    backboneClass: "Project"
    url: -> "#{root.url}/projects/#{@id || @escaped_path()}"
    initialize: ->
      @branches = new root.Branches([], project:@)
      @members = new root.Members([], project:@)
      @on("change", @parsePath)
      @parse_path()
    tree: (path, branch) ->
      return new root.Tree([],
        project:@
        path: path
        branch: branch
      )
    blob: (path, branch) ->
      return new root.Blob(
        file_path: path
        name: _.last path.split("/")
      ,
        branch: branch
        project:@
      )
    compare: (from, to) ->
      return new root.Compare(
        null
      ,
        from: from
        to: to
        project:@
      )
    parse_path: ->
      if @get("path_with_namespace")
        split = @get("path_with_namespace").split("/")
        @set("path", _.last(split))
        @set("owner", { username: _.first(split) })
    escaped_path: ->
      return @get("path_with_namespace").replace("/", "%2F")
  )

  @Projects = @Collection.extend(
    model: root.Project
    url: ->
      if @scope?
        return "#{root.url}/groups/#{@scope}/projects"
      else
        return "#{root.url}/projects"
    group: (group) ->
        if group
          @scope = group
        else
          @scope = undefined
  )

  # Events
  # --------------------------------------------------------

  @Events = @Collection.extend(
    backboneClass: "Events"

    parameters: ->
      arr = []
      arr.push("page=#{@page}") if @page
      arr.push("per_page=#{@per_page}") if @per_page
      if arr.length > 0 then "?#{arr.join('&')}" else ""

    url: ->
      "#{root.url}/projects/#{@project.escaped_path()}/events#{@parameters()}"

    initialize: (models, options={}) ->
      if !options.project then throw "You have to initialize GitLab.Events with a GitLab.Project model"
      @project = options.project
      @per_page = options.per_page if options.per_page?
      @page = options.page if options.page?
  )

  # Commits
  # --------------------------------------------------------

  @Commit = @Model.extend(
    backboneClass: "Commit"
    urlRoot: ->
      "#{root.url}/projects/#{@project.escaped_path()}/repository/commits"

    initialize: (data,options) ->
      if !options.project? and !@collection?.project? then throw "You have to initialize GitLab.Commit with a GitLab.Project model"
      @project = options.project || @collection.project
  )

  @Commits = @Collection.extend(
    backboneClass: "Commits"
    model: root.Commit

    parameters: ->
      arr = []
      arr.push("ref_name=#{@ref_name}") if @ref_name
      arr.push("page=#{@page}") if @page
      arr.push("per_page=#{@per_page}") if @per_page
      if arr.length > 0 then "?#{arr.join('&')}" else ""

    url: ->
      base = "#{root.url}/projects/#{@project.escaped_path()}/repository/commits"

      base+@parameters()

    initialize: (models, options={}) ->
      if !options.project then throw "You have to initialize GitLab.Commits with a GitLab.Project model"
      @project = options.project
      @ref_name = options.ref_name if options.ref_name?
      @page = options.page if options.page?
      @per_page = options.per_page if options.per_page?
  )

  # Diff
  # --------------------------------------------------------

  @Diff = @Model.extend(
    backboneClass: "Diff"
    url: ->
      "#{root.url}/projects/#{@project.escaped_path()}/repository/commits/#{@commit.id}/diff"

    initialize: (data,options) ->
      if !options.project then throw "You have to initialize GitLab.Diff with a GitLab.Project model"
      if !options.commit then throw "You have to initialize GitLab.Diff with a GitLab.Commit model"
      @project = options.project
      @commit = options.commit
  )

  # Branches
  # --------------------------------------------------------

  @Branch = @Model.extend(
    backboneClass: "Branch"
    urlRoot: ->
      "#{root.url}/projects/#{@project.escaped_path()}/repository/branches"

    sync: (method, model, options) ->
      if method.toLowerCase() is 'create'
        options.url = "#{root.url}/projects/#{@project.escaped_path()}/repository/branches"
      else
        options.url = "#{root.url}/projects/#{@project.escaped_path()}/repository/branches/#{@get('name')}"

      root.sync(method, model, options)

    initialize: (data,options={}) ->
      if !@collection?.project? and !options.project then throw "You have to initialize Gitlab.Branch with a Gitlab.Project model"
      @project = if @collection?.project? then @collection.project else options.project

      if @get('branch_name')? and !@get('name')?
        @set('name', @get('branch_name'))

    destroy: (options={}) ->
      model = this;
      success = options.success;

      destroy = () ->
        model.trigger('destroy', model, model.collection, options)

      options.success = (resp) ->
        if (options.wait || model.isNew()) then destroy()
        if (success) then success(model, resp, options)
        if (!model.isNew()) then model.trigger('sync', model, resp, options)

      xhr = this.sync('delete', this, options);
      if (!options.wait) then destroy();
      return xhr;
  )

  @Branches = @Collection.extend(
    backboneClass: "Branches"
    model: root.Branch

    url: -> "#{root.url}/projects/#{@project.escaped_path()}/repository/branches"

    initialize: (models, options) ->
      options = options || {}
      if !options.project then throw "You have to initialize GitLab.Branches with a GitLab.Project model"
      @project = options.project
  )

  # Merge Requests
  # --------------------------------------------------------

  @MergeRequest = @Model.extend(
    backboneClass: "MergeRequest"
    urlRoot: ->
      "#{root.url}/projects/#{@project.escaped_path()}/merge_request"

    initialize: (model, options={}) ->
      if !options.project then throw "You have to initialize GitLab.MergeRequest with a GitLab.Project model"
      @project = options.project

    sync: (method, model, options) ->
      options = options || {}

      if method.toLowerCase() is "create"
        options.url = "#{root.url}/projects/#{@project.escaped_path()}/merge_requests"
      else if options.method?.toLowerCase() is "merge"
        options.method = "PUT"
        options.url = "#{root.url}/projects/#{@project.escaped_path()}/merge_request/#{@get('id')}/merge"

      root.sync.apply(this, arguments)

    # Public: this function will merge the merge request on Gitlab.
    #
    # options: {merge_commit_request: "String, optional", success: (model,xhr), error: (model,xhr)}
    #
    # returns nothing
    merge: (options={}) ->
      options.method = "merge"

      if options.commit_message?
        data =
          merge_commit_message: options.commit_message

      @save(data, options)

  )

  @MergeRequests = @Collection.extend(
    backboneClass: "MergeRequests"
    model: root.MergeRequest

    parameters: ->
      arr = []
      arr.push("page=#{@page}") if @page
      arr.push("per_page=#{@per_page}") if @per_page
      arr.push("state=#{@state}") if @state
      if arr.length > 0 then "?#{arr.join('&')}" else ""

    url: -> "#{root.url}/projects/#{@project.escaped_path()}/merge_requests#{@parameters()}"

    initialize: (models, options={}) ->
      if !options.project then throw "You have to initialize GitLab.MergeRequests with a GitLab.Project model"
      @project = options.project
      @page = options.page if options.page?
      @per_page = options.per_page if options.per_page?
      @state = options.state if options.state?

    # Custom fetch function. Used to add project info in fetch call.
    #
    # Returns nothing.
    fetch: (options={}) ->
      options.project = @project
      root.Collection.prototype.fetch.apply(this, [options])
  )


  # Members
  # --------------------------------------------------------

  @Member = @Model.extend(
    backboneClass: "Member"
  )

  @Members = @Collection.extend(
    backboneClass: "Members"
    url: ->
      if @project?
        "#{root.url}/projects/#{@project.escaped_path()}/members"
      else if @group?
        "#{root.url}/groups/#{@group.get('id')}/members"
    initialize: (models, options={}) ->
      if !options.project and !options.group then throw "You have to initialize GitLab.Members with a GitLab.Project model or Gitlab.Group model"
      @project = options.project if options.project?
      @group = options.group if options.group?
    model: root.Member

    create: (model, options) ->
      options = if options then _.clone(options) else {}

      if !_.has(model, "user_id")
        throw new Error "You must provide a user_id to add a member."
      if !_.has(model, "access_level")
        throw new Error "You must provide an access_level to add a member."

      if (!(model = this._prepareModel(model, options))) then return false
      if (!options.wait) then this.add(model, options)
      collection = this
      success = options.success
      options.success = (resp) ->
        if (options.wait) then collection.add(model, options)
        if (success) then success(model, resp, options)
      model.save(null, options)
      return model
  )

  # Groups
  # --------------------------------------------------------

  @Group = @Model.extend(
    backboneClass: "Group"
    url: -> "#{root.url}/groups/#{@id}" if @id
    initialize: ->
      @members = new root.Members([],{group:@})
  )

  @Groups = @Collection.extend(
    backboneClass: "Groups"
    url: -> "#{root.url}/groups"
    initialize: (models, options) ->
      options = options || {}
      @user = options.user
    model: root.Group
  )


  # Blob
  # --------------------------------------------------------

  @Blob = @Model.extend(

    backboneClass: "Blob"

    initialize: (data, options) ->
      options = options || {}
      if !options.project then throw "You have to initialize GitLab.Blob with a GitLab.Project model"
      @project = options.project
      @branch = options.branch || "master"
      @on("sync", -> @set("id", "fakeIDtoenablePUT"))
      @on("change", @parseFilePath)
      @parseFilePath()

    parseFilePath: (model, options) ->
      if @get("file_path")
        @set("name", _.last(@get("file_path").split("/")))

    sync: (method, model, options) ->
      options = options || {}
      baseURL = "#{root.url}/projects/#{@project.escaped_path()}/repository"
      if method.toLowerCase() == "read"
        options.url = "#{baseURL}/files?file_path=#{@get('file_path').replace('/','%2F')}&ref=#{@branch}"
      else
        options.url = "#{baseURL}/files"

      # Gitlab Delete requires parameters with DELETE which is not expected
      # behavoir with Backbone.
      if method.toLowerCase() is "delete"
        commit_message = @get('commit_message') || "Deleted #{@get('file_path')}"
        options.url = options.url + "?file_path=#{@get('file_path')}&branch_name=#{@branch}&commit_message='#{commit_message}'"

      root.sync.apply(this, arguments)

    toJSON: (opts=[]) ->
      defaults = {
        name: @get("name")
        file_path: @get("file_path")
        branch_name: @branch
        content: @get("content")
        commit_message: @get("commit_message") || @defaultCommitMessage()
        encoding: @get("encoding") || 'text'
      }

      # exit early if not provided with opts
      if typeof opts is "Array" and opts.length is 0 then return defaults

      # clone the attributes and add in backboneClass
      attrs = _.clone(@attributes)
      attrs.backboneClass = @backboneClass

      _.each opts, (opt) ->
        if _.has(attrs, opt) then defaults[opt] = attrs[opt]

      defaults

    defaultCommitMessage: ->
      if @isNew()
        "Created #{@get("file_path")}"
      else
        "Updated #{@get("file_path")}"

    parse: (response, options) ->
      if options.parse isnt false
        if response.encoding is "base64"
          response.content = Base64.decode(response.content.replace(/\n/g,''))
          response.encoding = "text"
      response
  )

  # Tree
  # --------------------------------------------------------

  @Tree = @Collection.extend(

    backboneClass: "Tree"
    model: root.Blob
    url: -> "#{root.url}/projects/#{@project.escaped_path()}/repository/tree"

    initialize: (models, options) ->
      options = options || {}
      if !options.project then throw "You have to initialize GitLab.Tree with a GitLab.Project model"
      @project = options.project
      @branch = options.branch || "master"
      @trees = []

      if options.path
        @path = options.path
        @name = _.last(options.path.split("/"))

    fetch: (options) ->
      options = options || {}
      options.data = options.data || {}
      options.data.path = @path if @path
      options.data.ref_name = @branch
      root.Collection.prototype.fetch.apply(this, [options])

    parse: (resp, xhr) ->

      # add trees to trees. we're loosing the tree data but the path here.
      _(resp).filter((obj) =>
        obj.type == "tree"
      ).map((obj) =>
        full_path = []
        full_path.push @path if @path
        full_path.push obj.name
        @trees.push(@project.tree(full_path.join("/"), @branch))
      )

      # add blobs to models. we're loosing the blob data but the path here.
      _(resp).filter((obj) =>
        obj.type == "blob"
      ).map((obj) =>
        full_path = []
        full_path.push @path if @path
        full_path.push obj.name
        @project.blob(full_path.join("/"), @branch)
      )
  )

  # Compare
  # --------------------------------------------------------

  @Compare = @Model.extend(

    url: -> "#{root.url}/projects/#{@project.escaped_path()}/repository/compare"

    backboneClass: "Compare"

    initialize: (data, options) ->
      options = options || {}
      if !options.project then throw "You have to initialize GitLab.Compare with a GitLab.Project model"
      if !options.to then throw "You have to initialize GitLab.Compare with a to options holding a Git reference"
      if !options.from then throw "You have to initialize GitLab.Compare with a from options holding a Git reference"
      @project = options.project
      @to = options.to
      @from = options.from

    fetch: (options) ->
      options = options || {}
      options.data = options.data || {}
      options.data.to = @to
      options.data.from = @from
      root.Collection.prototype.fetch.apply(this, [options])
  )

  # Initialize
  # --------------------------------------------------------

  @user   = new @User()

  @project = (full_path) ->
    return new @Project(
      path: full_path.split("/")[1]
      path_with_namespace: full_path
    )

  return @

window.GitLab = GitLab
