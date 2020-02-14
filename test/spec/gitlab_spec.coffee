# GitLab Specs
#
# In these tests, results from the "test/canned" folder will be served as API responses.
# If you want to check that a specific URL was called, you can use the AJAX helpers:
#
#   spyOnAjax()
#   model.fetch()
#   expect(lastAjaxCall().args[0].type).toEqual("GET")
#   expect(lastAjaxCall().args[0].url).toEqual("www.runemadsen.com/user")
#
# Remember that the AJAX calls are actually being made, so to assert something on the response,
# you have to use Jasmine's asynchronous helpers:
#
#   model.fetch({success: ->
#     console.log("DONE!")
#     done()
#   })
#
# The AJAX helpers can of course be mixes with Jasmine's asynchronous helpers, as seen in the tests
# below.
#
# Things to tweak in GitLab API
#
# /blobs has "filepath" parameter, but /files has "file_path". /tree param is "path". Make them the same.
# /tree returns blobs with "name" parameter, which is "file_path" in /files
# Many resources live as ?params, not as objects in the URL. Filenames, etc should be resources in the route

ajaxTimeout = 1000
token = "abcdefg"
url = "http://127.0.0.1:4321"

describe("GitLab", ->

  gitlab = null
  project = null
  project2 = null

  beforeEach(->
    gitlab = new GitLab(url, token)
    project = gitlab.project("owner/project")
    project2 = gitlab.project("runemadsen/book")
  )

  # Custom Matchers
  # ----------------------------------------------------------------

  custom_matchers =
    toSetTokenHeader: (utils, customEqualityTesters) ->
      # Set actualName and actualValue to null and expect them to be set by backboneGitlab
      fakeXHR =
        actualName: null
        actualValue: null
        setRequestHeader: (actualName, actualValue) ->
          @actualName = actualName
          @actualValue = actualValue

      compare: (actual, expected) ->
        actual().args[0].beforeSend(fakeXHR)

        result = {}

        actualHeader = {}
        actualHeader[fakeXHR.actualName] = fakeXHR.actualValue

        result.pass = utils.equals(actualHeader, expected, customEqualityTesters)

        if result.pass
          result.message = "Expected " + JSON.stringify(actualHeader) + " not to be quite so goofy";
        else
          result.message = "Expected " + JSON.stringify(actualHeader) + " to be " + JSON.stringify(expected)

        result



  beforeEach(->
    jasmine.addMatchers(custom_matchers)
  )

  # Helpers
  # ----------------------------------------------------------------

  spyOnAjax = ->
    spyOn(Backbone, "ajax").and.callThrough()

  lastAjaxCall = ->
    Backbone.ajax.calls.mostRecent()

  lastAjaxCallData = ->
    d = Backbone.ajax.calls.mostRecent().args[0].data || {}
    if _.isString(d) then JSON.parse(d) else d

  # GitLab.Client
  # ----------------------------------------------------------------

  describe("Client", ->

    it("should initialize with token and url", ->
      expect(gitlab.token).toBe(token)
      expect(gitlab.url).toBe(url)
    )

    describe("Associations", ->
      it("returns empty GitLab.User model on gitlab.user", ->
        expect(gitlab.user.backboneClass).toEqual("User")
      )
      it("returns empty GitLab.Project model on gitlab.project(full_path)", ->
        expect(project2.backboneClass).toEqual("Project")
      )
    )
  )

  # GitLab.User
  # ----------------------------------------------------------------

  describe("User", ->

    describe("fetch()", ->
      it("should call correct URL", (done) ->
        spyOnAjax()
        gitlab.user.fetch({
          success: ->
            expect(lastAjaxCall().args[0].type).toEqual("GET")
            expect(lastAjaxCall().args[0].url).toEqual(url + "/user")
            expect(lastAjaxCall).toSetTokenHeader({"PRIVATE-TOKEN": token})
            done()
        })
      )
    )

    describe("Associations", ->
      it("returns empty GitLab.Keys collection on user.sshkeys", ->
        keys = gitlab.user.sshkeys
        expect(keys.backboneClass).toEqual("SSHKeys")
        expect(keys.length).toBe(0)
      )
    )
  )

  # GitLab.Keys
  # ----------------------------------------------------------------

  describe("SSHKeys", ->

    keys = null
    beforeEach(->
      keys = new gitlab.SSHKeys()
    )

    describe("fetch()", ->
      it("should call correct URL", ->
        spyOnAjax()
        keys.fetch()
        expect(lastAjaxCall().args[0].type).toEqual("GET")
        expect(lastAjaxCall().args[0].url).toEqual(url + "/user/keys")
      )
    )

    describe("create()", ->
      it("should call the correct URL", ->
        spyOnAjax()
        keys.create(key:"Something")
        expect(lastAjaxCall().args[0].type).toEqual("POST")
        expect(lastAjaxCall().args[0].url).toEqual(url + "/user/keys")
      )

      it("should set 'truncated_key' on initialize", ->
        keys.create(key:"ssh-rsa 1234567890123456789012345678901234567890 emailaddress")

        key = keys.last()

        expect(key.get("truncated_key")).toEqual("...12345678901234567890 emailaddress")
      )

      it("should set 'truncated_key' as 'key' if there aren't 3 spaces", ->
        key = keys.create(key:"something")
        expect(key.get('truncated_key')).toEqual("something")
      )
    )
  )

  # GitLab.Project
  # ----------------------------------------------------------------

  describe("Project", ->

    describe("initialize()", ->
      it("should parse path_with_namespace into path and owner", ->
        project = gitlab.project("runemadsen/book")
        expect(project.get("owner").username).toEqual("runemadsen")
        expect(project.get("path")).toEqual("book")
        expect(project.get("path_with_namespace")).toEqual("runemadsen/book")
      )
    )

    describe("fetch()", ->
      it("should call the correct URL", ->
        spyOnAjax()
        project = gitlab.project("runemadsen/book") # load any.get.json instead of subfolder index.get.json
        project.fetch()
        expect(lastAjaxCall().args[0].type).toEqual("GET")
        expect(lastAjaxCall().args[0].url).toEqual(url + "/projects/runemadsen%2Fbook")
      )
    )

    describe("Associations", ->

      it("returns empty GitLab.Branches collection on project.branches", ->
        branches = project.branches
        expect(branches.backboneClass).toEqual("Branches")
        expect(branches.project).toEqual(project)
        expect(branches.length).toBe(0)
      )

      it("returns empty GitLab.Members collection on project.members", ->
        expect(project.members.backboneClass).toEqual("Members")
      )

      it("returns empty GitLab.Blob model on project.blob(path)", ->
        blob = project.blob("subfolder/file.txt")
        expect(blob.backboneClass).toEqual("Blob")
        expect(blob.project).toEqual(project)
        expect(blob.get("name")).toEqual("file.txt")
        expect(blob.get("file_path")).toEqual("subfolder/file.txt")
      )

      it("returns empty GitLab.Blob model on project.blob(path, branch)", ->
        blob = project.blob("subfolder/file.txt", "slave")
        expect(blob.backboneClass).toEqual("Blob")
        expect(blob.project).toEqual(project)
        expect(blob.branch).toEqual("slave")
        expect(blob.get("name")).toEqual("file.txt")
        expect(blob.get("file_path")).toEqual("subfolder/file.txt")
      )

      it("returns empty GitLab.Tree model on project.tree(path)", ->
        tree = project.tree("/")
        expect(tree.backboneClass).toEqual("Tree")
        expect(tree.project).toEqual(project)
      )

      it("returns empty GitLab.Tree model on project.tree(path, branch)", ->
        tree = project.tree("/", "slave")
        expect(tree.backboneClass).toEqual("Tree")
        expect(tree.project).toEqual(project)
        expect(tree.branch).toEqual("slave")
      )

      it("returns empty GitLab.Compare model on project.compare(from, to)", ->
        compare = project.compare("sha1", "sha2")
        expect(compare.backboneClass).toEqual("Compare")
        expect(compare.project).toEqual(project)
        expect(compare.from).toEqual("sha1")
        expect(compare.to).toEqual("sha2")
      )
    )
  )

  # GitLab.Project
  # ----------------------------------------------------------------

  describe("Projects", ->
    describe("fetch", ->
      it "should call the correct URL", ->
        projects = new gitlab.Projects()
        spyOnAjax()
        projects.fetch()
        expect(lastAjaxCall().args[0].type).toEqual("GET")
        expect(lastAjaxCall().args[0].url).toEqual "#{url}/projects"
    )
  )

  # Gitlab.Events
  # ----------------------------------------------------------------
  describe("Events", ->
    describe("initialize", ->
      it("should throw error if no project is passed in options", ->
        expect(-> new gitlab.Events()).toThrow("You have to initialize GitLab.Events with a GitLab.Project model")
      )
    )

    describe("fetch", ->
      it("should call the correct URL with no parameters", ->
        events = new gitlab.Events(null,{project:project})
        spyOnAjax()
        events.fetch()
        expect(lastAjaxCall().args[0].type).toEqual("GET")
        expect(lastAjaxCall().args[0].url).toEqual "#{url}/projects/owner%2Fproject/events"
      )

      it("should call the correct URL with per_page parameter", ->
        events = new gitlab.Events(null,{project:project,per_page:40})
        spyOnAjax()
        events.fetch()
        expect(lastAjaxCall().args[0].type).toEqual("GET")
        expect(lastAjaxCall().args[0].url).toEqual "#{url}/projects/owner%2Fproject/events?per_page=40"
      )

      it("should call the correct URL with page parameter", ->
        events = new gitlab.Events(null,{project:project,page:2})
        spyOnAjax()
        events.fetch()
        expect(lastAjaxCall().args[0].type).toEqual("GET")
        expect(lastAjaxCall().args[0].url).toEqual "#{url}/projects/owner%2Fproject/events?page=2"
      )

      it("should call the correct URL with per_page and page parameter", ->
        events = new gitlab.Events(null,{project:project,per_page:40,page:2})
        spyOnAjax()
        events.fetch()
        expect(lastAjaxCall().args[0].type).toEqual("GET")
        expect(lastAjaxCall().args[0].url).toEqual "#{url}/projects/owner%2Fproject/events?page=2&per_page=40"
      )
    )
  )

  # Gitlab.Commits
  # ----------------------------------------------------------------

  describe("Commits", ->
    describe("fetch", ->
      it("should call the correct URL", ->
        commits = new gitlab.Commits([],{project:project})
        spyOnAjax()
        commits.fetch()
        expect(lastAjaxCall().args[0].type).toEqual("GET")
        expect(lastAjaxCall().args[0].url).toEqual "#{url}/projects/owner%2Fproject/repository/commits"
      )

      it("should call the correct URL with a ref_name", ->
        commits = new gitlab.Commits([],{project:project,ref_name:"slave"})
        spyOnAjax()
        commits.fetch()
        expect(lastAjaxCall().args[0].type).toEqual("GET")
        expect(lastAjaxCall().args[0].url).toEqual "#{url}/projects/owner%2Fproject/repository/commits?ref_name=slave"
      )

      it("should call the correct URL with page parameter", ->
        commits = new gitlab.Commits([],{project:project,page:2})
        spyOnAjax()
        commits.fetch()
        expect(lastAjaxCall().args[0].type).toEqual("GET")
        expect(lastAjaxCall().args[0].url).toEqual "#{url}/projects/owner%2Fproject/repository/commits?page=2"
      )

      it("should call the correct URL with per_page parameter", ->
        commits = new gitlab.Commits([],{project:project,per_page:40})
        spyOnAjax()
        commits.fetch()
        expect(lastAjaxCall().args[0].type).toEqual("GET")
        expect(lastAjaxCall().args[0].url).toEqual "#{url}/projects/owner%2Fproject/repository/commits?per_page=40"
      )

      it("should call the correct URL with all parameters", ->
        commits = new gitlab.Commits([],{
          project:project,
          ref_name:"slave",
          per_page:40,
          page: 2
        })
        spyOnAjax()
        commits.fetch()
        expect(lastAjaxCall().args[0].type).toEqual("GET")
        expect(lastAjaxCall().args[0].url).toEqual "#{url}/projects/owner%2Fproject/repository/commits?ref_name=slave&page=2&per_page=40"
      )
    )
  )

  # Gitlab.Diff
  # ----------------------------------------------------------------

  describe("Diff", ->
    describe("initialize", ->
      it("should throw error if no project is passed in options", ->
        commits = new gitlab.Commits([],{project:project})
        expect(-> new gitlab.Diff({},{commit: commits.first()})).toThrow("You have to initialize GitLab.Diff with a GitLab.Project model")
      )

      it("should throw error if no commit is passed in options", ->
        expect(-> new gitlab.Diff({},{project: project})).toThrow("You have to initialize GitLab.Diff with a GitLab.Commit model")
      )
    )

    describe("fetch", ->
      it("should call the correct URL", (done) ->
        commit = new gitlab.Commit({id:"12345"},{project:project})
        setTimeout((->
          diff = new gitlab.Diff({},{project: project, commit: commit})
          spyOnAjax()
          diff.fetch()
          expect(lastAjaxCall().args[0].type).toEqual("GET")
          expect(lastAjaxCall().args[0].url).toEqual "#{url}/projects/owner%2Fproject/repository/commits/12345/diff"
          done()
        ),60)
      )
    )
  )

  # GitLab.Branches
  # ----------------------------------------------------------------

  describe("Branch", ->
    describe("initialize()", ->
      it("should throw an error if no project is passed", ->
        expect(-> new gitlab.Branch()).toThrow("You have to initialize Gitlab.Branch with a Gitlab.Project model")
      )
    )
  )

  describe("Branches", ->

    branches = null
    beforeEach(-> branches = new gitlab.Branches([], project:project))

    describe("initialize()", ->
      it("should throw error if no project is passed in options", ->
        expect(-> new gitlab.Branches()).toThrow("You have to initialize GitLab.Branches with a GitLab.Project model");
      )
    )

    describe("fetch()", ->
      it("should call the correct URL", ->
        spyOnAjax()
        branches.fetch()
        expect(lastAjaxCall().args[0].type).toEqual("GET")
        expect(lastAjaxCall().args[0].url).toEqual(url + "/projects/owner%2Fproject/repository/branches")
      )
    )

    describe("create()", ->
      it("should call the correct URL", ->
        spyOnAjax()
        branches.create({branch:"new-branch",ref:"master"})
        expect(lastAjaxCall().args[0].type).toEqual("POST")
        expect(lastAjaxCall().args[0].url).toEqual(url + "/projects/owner%2Fproject/repository/branches")
      )
    )

    describe("destroy()", ->
      it("should call the correct URL", ->
        spyOnAjax()
        branch = new gitlab.Branch({branch: "branch-to-delete", ref:"master"},{project:project})

        branch.destroy()
        expect(lastAjaxCall().args[0].type).toEqual("DELETE")
        expect(lastAjaxCall().args[0].url).toEqual(url + "/projects/owner%2Fproject/repository/branches/branch-to-delete")
      )
    )
  )

  # GitLab.MergeRequest
  # ----------------------------------------------------------------

  describe("MergeRequest", ->
    describe("initialize()", ->
      it "should throw an error if no project is passed in options", ->
        expect(-> new gitlab.MergeRequest()).toThrow("You have to initialize GitLab.MergeRequest with a GitLab.Project model")
    )

    describe("fetch()", ->
      it "should call the correct URL", ->
        id = 1
        merge_request = new gitlab.MergeRequest({id:id}, project:project)
        spyOnAjax()
        merge_request.fetch()
        expect(lastAjaxCall().args[0].type).toEqual("GET")
        expect(lastAjaxCall().args[0].url).toEqual(url + "/projects/owner%2Fproject/merge_request/"+ id)
    )

    describe("save()", ->
      it("should call the correct URL when new", ->
        spyOnAjax()
        merge_request = new gitlab.MergeRequest({source_branch:"slave", target_branch:"master", title:"test"}, project:project)
        merge_request.save()
        expect(lastAjaxCall().args[0].type).toEqual("POST")
        expect(lastAjaxCall().args[0].url).toEqual(url + "/projects/owner%2Fproject/merge_requests")
      )

      it("should call the correct URL when modified", ->
        spyOnAjax()
        merge_request = new gitlab.MergeRequest({source_branch:"slave", target_branch:"master", title:"test", id:1}, project:project)
        merge_request.save()
        expect(lastAjaxCall().args[0].type).toEqual("PUT")
        expect(lastAjaxCall().args[0].url).toEqual(url + "/projects/owner%2Fproject/merge_request/1")
      )
    )

    describe("merge()", ->
      it("should call the correct url", ->
        spyOnAjax()
        merge_request = new gitlab.MergeRequest({id:1}, project:project)
        merge_request.merge()
        expect(lastAjaxCall().args[0].type).toEqual("PUT")
        expect(lastAjaxCall().args[0].url).toEqual(url+"/projects/owner%2Fproject/merge_request/1/merge")
      )

      it("should accept a commit message", ->
        spyOnAjax()
        merge_request = new gitlab.MergeRequest({id: 1}, project:project)
        merge_request.merge(commit_message:"This looks good, merging in")

        ajax_call =  lastAjaxCall().args[0]
        expect(ajax_call.type).toEqual("PUT")
        expect(ajax_call.url).toEqual(url+"/projects/owner%2Fproject/merge_request/1/merge")

        data = JSON.parse ajax_call.data
        expect(data.merge_commit_message).toEqual("This looks good, merging in")
      )

      it("should return 405 when the request won't merge", (done) ->
        spyOnAjax()

        # MergeRequest 2 is designed to throw a 405
        merge_request = new gitlab.MergeRequest({id: 2}, project:project)

        merge_request.merge
          error: (model, xhr) ->
            expect(xhr.status).toEqual(405)
            done()
      )

      it("should return 401 when the user is unauthorized to merge", (done) ->
        spyOnAjax()

        # MergeRequest 3 is designed to throw a 401
        merge_request = new gitlab.MergeRequest({id: 3}, project:project)

        merge_request.merge
          error: (model, xhr) ->
            expect(xhr.status).toEqual(401)
            done()
      )
    )
  )

  # Gitlab.MergeRequests
  # --------------------------------------------------------------------------
  describe("MergeRequests", ->
    describe("initialize()", ->
      it "should throw an error if no project is passed in options", ->
        expect(-> new gitlab.MergeRequests()).toThrow("You have to initialize GitLab.MergeRequests with a GitLab.Project model")
    )

    describe("fetch()", ->
      it("should call the correct URL", ->
        merge_requests = new gitlab.MergeRequests([], {project:project})
        spyOnAjax()
        merge_requests.fetch()
        expect(lastAjaxCall().args[0].type).toEqual("GET")
        expect(lastAjaxCall().args[0].url).toEqual(url + "/projects/owner%2Fproject/merge_requests")
      )

      it("should call the correct URL with per_page parameter", ->
        merge_requests = new gitlab.MergeRequests(null,{project:project,per_page:40})
        spyOnAjax()
        merge_requests.fetch()
        expect(lastAjaxCall().args[0].type).toEqual("GET")
        expect(lastAjaxCall().args[0].url).toEqual "#{url}/projects/owner%2Fproject/merge_requests?per_page=40"
      )

      it("should call the correct URL with page parameter", ->
        merge_requests = new gitlab.MergeRequests(null,{project:project,page:2})
        spyOnAjax()
        merge_requests.fetch()
        expect(lastAjaxCall().args[0].type).toEqual("GET")
        expect(lastAjaxCall().args[0].url).toEqual "#{url}/projects/owner%2Fproject/merge_requests?page=2"
      )

      it("should call the correct URL for opened requests", ->
        merge_requests = new gitlab.MergeRequests(null,{project:project,state:"opened"})
        spyOnAjax()
        merge_requests.fetch()
        expect(lastAjaxCall().args[0].type).toEqual("GET")
        expect(lastAjaxCall().args[0].url).toEqual "#{url}/projects/owner%2Fproject/merge_requests?state=opened"
      )

      it("should call the correct URL for closed requests", ->
        merge_requests = new gitlab.MergeRequests(null,{project:project,state:"closed"})
        spyOnAjax()
        merge_requests.fetch()
        expect(lastAjaxCall().args[0].type).toEqual("GET")
        expect(lastAjaxCall().args[0].url).toEqual "#{url}/projects/owner%2Fproject/merge_requests?state=closed"
      )

      it("should call the correct URL for merged requests", ->
        merge_requests = new gitlab.MergeRequests(null,{project:project,state:"merged"})
        spyOnAjax()
        merge_requests.fetch()
        expect(lastAjaxCall().args[0].type).toEqual("GET")
        expect(lastAjaxCall().args[0].url).toEqual "#{url}/projects/owner%2Fproject/merge_requests?state=merged"
      )

      it("should call the correct URL with per_page and page parameter", ->
        merge_requests = new gitlab.MergeRequests(null,{project:project,per_page:40,page:2})
        spyOnAjax()
        merge_requests.fetch()
        expect(lastAjaxCall().args[0].type).toEqual("GET")
        expect(lastAjaxCall().args[0].url).toEqual "#{url}/projects/owner%2Fproject/merge_requests?page=2&per_page=40"
      )
    )
  )

  # GitLab.Members
  # ----------------------------------------------------------------

  describe("Members", ->

    members = null
    beforeEach(-> members = new gitlab.Members([], project:project))

    describe("initialize()", ->
      it("should throw error if no project is passed in options", ->
        expect(-> new gitlab.Members()).toThrow("You have to initialize GitLab.Members with a GitLab.Project model or Gitlab.Group model")
      )
    )

    describe("fetch()", ->
      it("should call the correct URL", ->
        spyOnAjax()
        members.fetch()
        expect(lastAjaxCall().args[0].type).toEqual("GET")
        expect(lastAjaxCall().args[0].url).toEqual(url + "/projects/owner%2Fproject/members")
      )
    )

    describe("create()", ->
      it("should call the correct URL", ->
        spyOnAjax()
        members.create(user_id:1, access_level:40)
        expect(lastAjaxCall().args[0].type).toEqual("POST")
        expect(lastAjaxCall().args[0].url).toEqual(url + "/projects/owner%2Fproject/members")
      )

      it "should return an error is no access_level is provided", ->
        expect(-> members.create(user_id:1)).toThrow(new Error("You must provide an access_level to add a member."))

      it "should return an error is user_id is not provided", ->
        expect(-> members.create(access_level:40)).toThrow(new Error("You must provide a user_id to add a member."))
    )

    describe("destroy()", ->
      beforeEach(-> members.fetch())

      it "should call the correct URL", ->
        members.fetch
          success: ->
            spyOnAjax()
            member = members.first()
            member.destroy()
            ajaxArgs = lastAjaxCall().args[0]
            expect(ajaxArgs.type).toEqual("DELETE")
            expect(ajaxArgs.url).toEqual(url + "/projects/owner%2Fproject/members/1")
    )
  )

  # GitLab.Group
  # ----------------------------------------------------------------

  describe "Group", ->
    describe "fetch()", ->
      it "should get a single group, and be able to get the projects of the group", (done)->
        group = new gitlab.Group(id: 4)
        group.fetch
          success: ->
            expect(group.get("projects").length).toEqual(17)
            expect(group.get("projects")[0].name).toEqual("animal_theme")
            done()
          error: (err) ->
            throw new Error("ID Not Found")

  # GitLab.Groups
  # ----------------------------------------------------------------

  describe "Groups", ->
    describe "fetch()", ->
      it "should get a user's groups, and be able to fetch the members of that group", (done)->
        groups = new gitlab.Groups()
        groups.fetch
          success: ->
            expect(groups.length).toEqual(1)
            agroup = groups.get(1)
            agroup.members.fetch
              success: ->
                expect(agroup.members.length).toEqual(2)
                done()


  # GitLab.Tree
  # ----------------------------------------------------------------

  describe("Tree", ->

    describe("initialize()", ->
      it("should throw error if no project is passed in options", ->
        expect(-> new gitlab.Tree()).toThrow("You have to initialize GitLab.Tree with a GitLab.Project model")
      )
    )

    describe("fetch()", ->

      it("should call correct URL without a path", ->
        spyOnAjax()
        tree = new gitlab.Tree([]
        ,
          project:project
        )
        tree.fetch()
        expect(lastAjaxCall().args[0].type).toEqual("GET")
        expect(lastAjaxCall().args[0].url).toEqual(url + "/projects/owner%2Fproject/repository/tree")
        expect(lastAjaxCallData().path).toBe(undefined)
      )

      it("should call correct URL with a path", ->
        spyOnAjax()
        tree = new gitlab.Tree([]
        ,
          project:project
          path:"subfolder/subsubfolder"
        )
        tree.fetch()
        expect(lastAjaxCall().args[0].type).toEqual("GET")
        expect(lastAjaxCall().args[0].url).toEqual(url + "/projects/owner%2Fproject/repository/tree")
        expect(lastAjaxCallData().path).toEqual("subfolder/subsubfolder")
      )

      it("should call correct URL with branch and subfolder path", ->
        spyOnAjax()
        tree = new gitlab.Tree([]
        ,
          project:project
          path:"subfolder"
          branch:"slave"
        )
        tree.fetch()
        expect(lastAjaxCallData().path).toEqual("subfolder")
        expect(lastAjaxCallData().ref).toEqual("slave")
      )

      it("should override per_page default with maximum allowed value when not supplied", ->
        spyOnAjax()
        tree = new gitlab.Tree([]
        ,
          project:project
          path:"subfolder"
        )
        tree.fetch()
        expect(lastAjaxCallData().per_page).toEqual(100)
      )

      it("should call correct URL with supplied per_page parameter", ->
        spyOnAjax()
        tree = new gitlab.Tree([]
        ,
          project:project
          path:"subfolder"
          per_page: 60
        )
        tree.fetch()
        expect(lastAjaxCallData().per_page).toEqual(60)
      )

      it("should parse trees and blobs", (done) ->
        tree = new gitlab.Tree([], project:project)
        tree.fetch({
          success: ->
            # put blobs in models array
            expect(tree.length).toBe(1)
            blob = tree.first()
            expect(blob.backboneClass).toEqual("Blob")
            expect(blob.get("file_path")).toEqual("README.md")
            expect(blob.get("name")).toEqual("README.md")

            # put trees in trees array
            expect(tree.trees.length).toBe(1)
            subfolder = tree.trees[0]
            expect(subfolder.backboneClass).toEqual("Tree")
            expect(subfolder.path).toEqual("assets")
            expect(subfolder.length).toBe(0)
            done()
        })
      )

      it("should give blobs in subfolders the correct file_path", (done) ->
        tree = new gitlab.Tree([], project:project, path:"subfolder")
        tree.fetch({success: ->
          blob = tree.first()
          expect(blob.get("name")).toEqual("SUBME.md")
          expect(blob.get("file_path")).toEqual("subfolder/SUBME.md")
          done()
        })
      )

      it("should give trees in subfolders the correct path", (done) ->
        tree = new gitlab.Tree([], project:project, path:"subfolder")
        tree.fetch({
          success: ->
            subtree = tree.trees[0]
            expect(subtree.name).toEqual("subsubfolder")
            expect(subtree.path).toEqual("subfolder/subsubfolder")
            done()
        })
      )
    )
  )

  # GitLab.Blob
  # ----------------------------------------------------------------

  describe("Blob", ->

    masterBlob = null
    slaveBlob = null

    beforeEach(->
      masterBlob = new gitlab.Blob(
        file_path: "subfolder/master.txt"
      ,
        project: project
      )
      slaveBlob = new gitlab.Blob(
        file_path: "subfolder/slave.txt"
      ,
        project: project
        branch: "slave"
      )
    )

    it("should parse file_path attribute into name on initialize", ->
      expect(masterBlob.get("name")).toEqual("master.txt")
      expect(masterBlob.get("file_path")).toEqual("subfolder/master.txt")
    )

    it("should parse file_path attribute into name on change", ->
      masterBlob.set("file_path", "anotherfolder/another.txt")
      expect(masterBlob.get("name")).toEqual("another.txt")
      expect(masterBlob.get("file_path")).toEqual("anotherfolder/another.txt")
    )

    it("should fail if correct options are not given", ->
      expect(-> new gitlab.Blob()).toThrow("You have to initialize GitLab.Blob with a GitLab.Project model")
    )

    describe("fetch()", ->

      it("should fetch the blob contents and merge with other data", (done) ->
        spyOnAjax()
        masterBlob.fetch({success: ->
          expect(lastAjaxCall().args[0].url).toEqual(url + "/projects/owner%2Fproject/repository/files/subfolder%2Fmaster.txt?ref=master")
          expect(masterBlob.get("content")).toEqual("Hello!")
          expect(masterBlob.get("name")).toEqual("master.txt")
          expect(masterBlob.get("file_path")).toEqual("subfolder/master.txt")
          done()
        })
      )

      it("should fetch the blob contents correctly, even if the contents include unicode", (done) ->
        spyOnAjax()
        specialBlob = new gitlab.Blob(
          file_path: "subfolder/special.txt"
        ,
          project: project
        )
        specialBlob.fetch({success: ->
          expect(lastAjaxCall().args[0].url).toEqual(url + "/projects/owner%2Fproject/repository/files/subfolder%2Fspecial.txt?ref=master")
          expect(specialBlob.get("content")).toEqual("Oh ’Ello!")
          expect(specialBlob.get("name")).toEqual("special.txt")
          expect(specialBlob.get("file_path")).toEqual("subfolder/special.txt")
          done()
        })
      )
      # ZACH WORK ON THIS HERE
      # Simulates an image
      it("should fetch the blob contents correctly, and not parse/decode the contents if parse is false", (done) ->
        spyOnAjax()
        specialBlob = new gitlab.Blob(
          file_path: "subfolder/special.txt"
        ,
          project: project
        )
        specialBlob.fetch({parse: false, success: ->
          expect(lastAjaxCall().args[0].url).toEqual(url + "/projects/owner%2Fproject/repository/files/subfolder%2Fspecial.txt?ref=master")
          expect(specialBlob.get("content")).toEqual("T2gg4oCZRWxsbyE=\n")
          expect(specialBlob.get("name")).toEqual("special.txt")
          expect(specialBlob.get("encoding")).toEqual("base64")
          expect(specialBlob.get("file_path")).toEqual("subfolder/special.txt")
          done()
        })
      )

      it("should use branch if specified", ->
        spyOnAjax()
        slaveBlob.fetch()
        expect(lastAjaxCall().args[0].url).toEqual(url + "/projects/owner%2Fproject/repository/files/subfolder%2Fslave.txt?ref=slave")
      )
    )

    describe("defaultCommitMessage()", ->

      it("should give correct message when isNew", ->
        expect(masterBlob.defaultCommitMessage()).toEqual("Created subfolder/master.txt")
      )

      it("should give correct message when !isNew", ->
        masterBlob.set("id", 1)
        expect(masterBlob.defaultCommitMessage()).toEqual("Updated subfolder/master.txt")
      )
    )

    describe("save()", ->

      it("should make POST if isNew", ->
        spyOnAjax()
        masterBlob.set("content", "New Content")
        masterBlob.save()
        expect(lastAjaxCall().args[0].url).toEqual(url + "/projects/owner%2Fproject/repository/files/subfolder%2Fmaster.txt?branch=master")
        expect(lastAjaxCall().args[0].type).toEqual("POST")
        expect(lastAjaxCallData().file_path).toEqual("subfolder/master.txt")
        expect(lastAjaxCallData().content).toEqual("New Content")
        expect(lastAjaxCallData().commit_message).toEqual("Created subfolder/master.txt")
        expect(lastAjaxCallData().branch).toEqual("master")
      )

      it("should make PUT if not isNew", (done) ->
        spyOnAjax()
        masterBlob.set("content", "New Content")
        masterBlob.save({}, success: (res) ->
          masterBlob.attributes.id = "fake"
          masterBlob.set("content", "Updated Content")

          masterBlob.save(masterBlob.attributes, success: (updatedBlob) ->
            expect(lastAjaxCall().args[0].url).toEqual(url + "/projects/owner%2Fproject/repository/files/subfolder%2Fmaster.txt?branch=master")
            expect(lastAjaxCall().args[0].type).toEqual("PUT")
            expect(lastAjaxCallData().file_path).toEqual("subfolder/master.txt")
            expect(lastAjaxCallData().content).toEqual("Updated Content")
            expect(lastAjaxCallData().commit_message).toEqual("Updated subfolder/master.txt")
            expect(lastAjaxCallData().branch).toEqual("master")
            expect(lastAjaxCallData().encoding).toBeUndefined()

            done()
          )

        )

      )

      it("should include the correct encoding if specified", ->
        spyOnAjax()
        masterBlob.set("content", "iVBORw0KGgo")
        masterBlob.set("encoding", "base64")
        masterBlob.save()
        expect(lastAjaxCall().args[0].url).toEqual(url + "/projects/owner%2Fproject/repository/files/subfolder%2Fmaster.txt?branch=master")
        expect(lastAjaxCall().args[0].type).toEqual("POST")
        expect(lastAjaxCallData().content).toEqual("iVBORw0KGgo")
        expect(lastAjaxCallData().encoding).toEqual("base64")
      )

      it("should use branch and commit message", ->
        spyOnAjax()
        slaveBlob.set("content", "New Content")
        slaveBlob.save(
          commit_message: "BLABLA"
        )
        expect(lastAjaxCall().args[0].url).toEqual(url + "/projects/owner%2Fproject/repository/files/subfolder%2Fslave.txt?branch=slave")
        expect(lastAjaxCall().args[0].type).toEqual("POST")
        expect(lastAjaxCallData().file_path).toEqual("subfolder/slave.txt")
        expect(lastAjaxCallData().content).toEqual("New Content")
        expect(lastAjaxCallData().commit_message).toEqual("BLABLA")
        expect(lastAjaxCallData().branch).toEqual("slave")
      )
    )

    describe "destroy()", ->
      beforeEach ->
        spyOnAjax()
        masterBlob.set("content", "New Content")
        masterBlob.save()

      it "should call a POST method", ->
        masterBlob.destroy()
        expect(lastAjaxCall().args[0].type).toEqual("POST")

      it "should call the correct URL", ->
        masterBlob.destroy()
        expect(lastAjaxCall().args[0].url).toEqual("#{url}/projects/owner%2Fproject/repository/files/subfolder%2Fmaster.txt?branch=master")

      it "should call the request with `file_path`, `branch` and `commit_message` as parameters", ->
        masterBlob.destroy()
        parameters = JSON.parse lastAjaxCall().args[0].data
        expect(parameters["file_path"]).toBeDefined()
        expect(parameters["branch"]).toBeDefined()
        expect(parameters["commit_message"]).toBeDefined()

      it "should call the `file_path` parameter with the proper value", ->
        masterBlob.destroy()
        parameters = JSON.parse lastAjaxCall().args[0].data
        expect(parameters["file_path"]).toEqual("subfolder/master.txt")

      it "should set `commit_message` when a custom message is provided.", ->
        masterBlob.set("commit_message", "this file is getting deleted")
        masterBlob.save()
        masterBlob.destroy()
        parameters = JSON.parse lastAjaxCall().args[0].data
        expect(parameters["commit_message"]).toEqual("this file is getting deleted")

    describe "toJSON()", ->

      it "should return default attributes when called with no arguments", ->
        masterBlob.set "content", "Some file content"
        json = masterBlob.toJSON()
        expect(json.file_path).toEqual('subfolder/master.txt')
        expect(json.name).toEqual('master.txt')
        expect(json.branch).toEqual('master')
        expect(json.content).toEqual('Some file content')
        expect(json.encoding).toBeUndefined()
        expect(json.commit_message).toEqual('Created subfolder/master.txt')

      it "should return attributes of Blob as specified by arguments", ->
        json = masterBlob.toJSON(['name', 'backboneClass'])
        expect(json.name).toBeDefined()
        expect(json.backboneClass).toBeDefined()

      it "should not fail when asked for an attribute the Blob does not have", ->
        json = masterBlob.toJSON(['someObscureKeyOrSomething'])
        expect(json.someObscureKeyOrSomething).toBeUndefined()

    describe("parse()", ->

      it("should parse object response from /files", (done) ->
        spyOnAjax()
        masterBlob.set("content", "Goodbye!")
        masterBlob.save {}, success: ->
          expect(masterBlob.get("content")).toEqual("Goodbye!")
          done()
      )

      it("should parse string response from /blobs", (done) ->
        spyOnAjax()
        masterBlob.set("content", "Goodbye!")
        masterBlob.fetch success: ->
          expect(masterBlob.get("content")).toEqual("Hello!")
          done()
      )

    )
  )

  # Gitlab.Compare
  # ----------------------------------------------------------------

  describe("Compare", ->

    describe("initialize", ->

      it("should throw error if no from is passed in options", ->
        expect(-> new gitlab.Compare(null, {project:project, to:"sha2"})).toThrow("You have to initialize GitLab.Compare with a from options holding a Git reference")
      )

      it("should throw error if no to is passed in options", ->
        expect(-> new gitlab.Compare(null, {project:project, from:"sha1"})).toThrow("You have to initialize GitLab.Compare with a to options holding a Git reference")
      )

      it("should throw error if no project is passed in options", ->
        expect(-> new gitlab.Compare()).toThrow("You have to initialize GitLab.Compare with a GitLab.Project model")
      )
    )

    describe("fetch", ->

      it("should call the correct URL", ->
        compare = new gitlab.Compare(null, {project:project, from:"sha1", to:"sha2"})
        spyOnAjax()
        compare.fetch()
        expect(lastAjaxCall().args[0].type).toEqual("GET")
        expect(lastAjaxCall().args[0].url).toEqual "#{url}/projects/owner%2Fproject/repository/compare"
        expect(lastAjaxCallData().from).toEqual("sha1")
        expect(lastAjaxCallData().to).toEqual("sha2")
      )

    )
  )
)
