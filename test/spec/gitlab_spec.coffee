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
#   model.fetch()
#   waitsFor(->
#     return model.id == 1
#   , "never loaded", 2000
#   )
#   runs(-> console.log "Done!")
#
# The AJAX helpers can of course be mixes with Jasmine's asynchronous helpers, as seen in the tests
# below.
#

# TODO

# /tree subfolders don't return full path to file in "name". Smart parse when 1) coming from tree (pass in file_path) 2) Created from beginning (pass in file_path). Then parse that into "name" without path

# enable tree.create(blobData) instead of just project.blob(path).save()

# path should be set inside project, not in gitlab.client
#expect(project.get("path")).toEqual("book")
#expect(project.get("path_with_namespace")).toEqual("runemadsen/book")
#expect(project.id).toBe(undefined)


# Things to tweak in GitLab API
#
# /blobs has "filepath" parameter, but /files has "file_path". /tree param is "path". Make them the same.
# /tree returns blobs with "name" parameter, which is "file_path" in /files
# Many resources live as ?params, not as objects in the URL. Filenames, etc should be resources in the route

ajaxTimeout = 1000
token = "abcdefg"
url = "http://127.0.0.1:5000"

describe("GitLab", ->

  gitlab = null
  project = null
  project2 = null

  beforeEach(->
    GitLab.url = url
    gitlab = new GitLab.Client(token)
    project = gitlab.project("owner/project")
    project2 = gitlab.project("runemadsen/book")
  )

  # Helpers
  # ----------------------------------------------------------------

  spyOnAjax = ->
    spyOn(Backbone, "ajax").andCallThrough()

  lastAjaxCall = ->
    Backbone.ajax.mostRecentCall

  lastAjaxCallData = ->
    d = Backbone.ajax.mostRecentCall.args[0].data || {}
    if _.isString(d) then JSON.parse(d) else d

  # GitLab.Client
  # ----------------------------------------------------------------

  describe("Client", ->

    it("saves token", ->
      expect(gitlab.token).toBe(token)
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
      it("should call correct URL", ->
        spyOnAjax()
        gitlab.user.fetch()
        expect(lastAjaxCall().args[0].type).toEqual("GET")
        expect(lastAjaxCall().args[0].url).toEqual(url + "/user")
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
      keys = new GitLab.SSHKeys()
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
    )
  )

  # GitLab.Branches
  # ----------------------------------------------------------------

  describe("Branches", ->

    branches = null
    beforeEach(-> branches = new GitLab.Branches([], project:project))

    describe("initialize()", ->
      it("should complain if no project is passed in options", ->
        expect(-> new GitLab.Branches()).toThrow(new Error("You have to initialize GitLab.Branches with a GitLab.Project model"));
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
  )

  # GitLab.Members
  # ----------------------------------------------------------------

  describe("Members", ->

    members = null
    beforeEach(-> members = new GitLab.Members([], project:project))

    describe("initialize()", ->
      it("should complain no project is passed in options", ->
        expect(-> new GitLab.Members()).toThrow(new Error("You have to initialize GitLab.Members with a GitLab.Project model"));
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
        members.create(name:"Rune Madsen")
        expect(lastAjaxCall().args[0].type).toEqual("POST")
        expect(lastAjaxCall().args[0].url).toEqual(url + "/projects/owner%2Fproject/members")
      )
    )
  )

  # GitLab.Tree
  # ----------------------------------------------------------------

  describe("Tree", ->

    describe("initialize()", ->
      it("should complain if no project is passed in options", ->
        expect(-> new GitLab.Tree()).toThrow(new Error("You have to initialize GitLab.Tree with a GitLab.Project model"));
      )
    )

    describe("fetch()", ->

      it("should call correct URL without a path", ->
        spyOnAjax()
        tree = new GitLab.Tree([]
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
        tree = new GitLab.Tree([]
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
        tree = new GitLab.Tree([]
        , 
          project:project
          path:"subfolder"
          branch:"slave"
        )
        tree.fetch()
        expect(lastAjaxCallData().path).toEqual("subfolder")
        expect(lastAjaxCallData().ref_name).toEqual("slave")
      )

      it("should parse trees and blobs", ->
        tree = new GitLab.Tree([], project:project)
        tree.fetch()
        waitsFor(->
          return tree.length > 0
        , "tree never loaded", ajaxTimeout
        )
        runs(->
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
        )
      )

      it("should give blobs in subfolders the correct file_path", ->
        tree = new GitLab.Tree([], project:project, path:"subfolder")
        tree.fetch()
        waitsFor(->
          return tree.length > 0
        , "tree never loaded", ajaxTimeout
        )
        runs(->
          blob = tree.first()
          expect(blob.get("name")).toEqual("SUBME.md")
          expect(blob.get("file_path")).toEqual("subfolder/SUBME.md")
        )
      )
    )
  )

  # GitLab.Blob
  # ----------------------------------------------------------------

  describe("Blob", ->
    
    masterBlob = null
    slaveBlob = null

    beforeEach(->
      masterBlob = new GitLab.Blob(
        file_path: "subfolder/master.txt"
      ,
        project: project
      )
      slaveBlob = new GitLab.Blob(
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
      expect(-> new GitLab.Blob()).toThrow(new Error("You have to initialize GitLab.Blob with a GitLab.Project model"))
    )

    describe("fetchContent()", ->

      it("should fetch the blob contents and merge with other data", ->
        spyOnAjax()
        masterBlob.fetchContent()
        waitsFor(->
          return masterBlob.get("content")
        , "blob content never loaded", ajaxTimeout
        )
        runs(->
          expect(lastAjaxCall().args[0].url).toEqual(url + "/projects/owner%2Fproject/repository/blobs/master")
          expect(lastAjaxCallData().filepath).toEqual("subfolder/master.txt")
          expect(masterBlob.get("content")).toEqual("Hello!")
          expect(masterBlob.get("name")).toEqual("master.txt")
          expect(masterBlob.get("file_path")).toEqual("subfolder/master.txt")
        )
      )
  
      it("should use branch if specified", ->
        spyOnAjax()
        slaveBlob.fetchContent()
        expect(lastAjaxCall().args[0].url).toEqual(url + "/projects/owner%2Fproject/repository/blobs/slave")
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
        expect(lastAjaxCall().args[0].url).toEqual(url + "/projects/owner%2Fproject/repository/files")
        expect(lastAjaxCall().args[0].type).toEqual("POST")
        expect(lastAjaxCallData().file_path).toEqual("subfolder/master.txt")
        expect(lastAjaxCallData().content).toEqual("New Content")
        expect(lastAjaxCallData().commit_message).toEqual("Created subfolder/master.txt")
        expect(lastAjaxCallData().branch_name).toEqual("master")
      )

      it("should make PUT if not isNew", ->
        loaded = false
        spyOnAjax() 
        masterBlob.set("content", "New Content")
        masterBlob.save({}, success: -> loaded = true)
        waitsFor(->
          return loaded
        , "blob was never created", ajaxTimeout
        )
        runs(->
          masterBlob.set("content", "Updated Content")
          masterBlob.save()
          expect(lastAjaxCall().args[0].url).toEqual(url + "/projects/owner%2Fproject/repository/files")
          expect(lastAjaxCall().args[0].type).toEqual("PUT")
          expect(lastAjaxCallData().file_path).toEqual("subfolder/master.txt")
          expect(lastAjaxCallData().content).toEqual("Updated Content")
          expect(lastAjaxCallData().commit_message).toEqual("Updated subfolder/master.txt")
          expect(lastAjaxCallData().branch_name).toEqual("master")
        )
      )
  
      it("should use branch and commit message", ->
        spyOnAjax()
        slaveBlob.set("content", "New Content")
        slaveBlob.save(
          commit_message: "BLABLA"
        )
        expect(lastAjaxCall().args[0].url).toEqual(url + "/projects/owner%2Fproject/repository/files")
        expect(lastAjaxCall().args[0].type).toEqual("POST")
        expect(lastAjaxCallData().file_path).toEqual("subfolder/slave.txt")
        expect(lastAjaxCallData().content).toEqual("New Content")
        expect(lastAjaxCallData().commit_message).toEqual("BLABLA")
        expect(lastAjaxCallData().branch_name).toEqual("slave")
      )
    )

    describe("destroy()", ->

    )

    describe("parse()", ->

      it("should parse object response from /files", ->
        loaded = false
        spyOnAjax()
        masterBlob.set("content", "Goodbye!")
        masterBlob.save({}, success: -> loaded = true)
        waitsFor(->
          return loaded
        , "blob was never created", ajaxTimeout
        )
        runs(->
          expect(masterBlob.get("content")).toEqual("Goodbye!")
        )
      )

      it("should parse string response from /blobs", ->
        loaded = false
        spyOnAjax()
        masterBlob.set("content", "Goodbye!")
        masterBlob.fetchContent(success: -> loaded = true)
        waitsFor(->
          return loaded
        , "blob content never loaded", ajaxTimeout
        )
        runs(->
          expect(masterBlob.get("content")).toEqual("Hello!")
        )
      )

    )
  ) 
)