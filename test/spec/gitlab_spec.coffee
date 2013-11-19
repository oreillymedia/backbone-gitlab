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


  # GitLab.Client
  # ----------------------------------------------------------------

  describe("GitLab.Client", ->

    it("saves token", ->
      expect(gitlab.token).toBe(token)
    )

    describe("Associations", ->
      it("returns empty GitLab.User model on gitlab.user", ->
        expect(gitlab.user.backboneClass).toEqual("User")
      )
    )
  )

  # GitLab.User
  # ----------------------------------------------------------------

  describe("GitLab.User", ->

    describe("fetch()", ->
      it("should call correct URL", ->
        spyOnAjax()
        gitlab.user.fetch()
        expect(lastAjaxCall().args[0].type).toEqual("GET")
        expect(lastAjaxCall().args[0].url).toEqual(url + "/user")
      )
    )
  )
  















  # Assocsiations
  # ----------------------------------------------------------------

  describe("Associations", ->

    project = null

    beforeEach(->
      project = gitlab.project("runemadsen/book")
    )

    

    it("returns empty GitLab.Keys collection on user.sshkeys", ->
      keys = gitlab.user.sshkeys
      expect(keys.backboneClass).toEqual("SSHKeys")
      expect(keys.length).toBe(0)
    )

    it("returns empty GitLab.Project model on gitlab.project()", ->
      expect(project.backboneClass).toEqual("Project")
    )

    it("returns empty GitLab.Branches collection on project.branches", ->
      branches = project.branches
      expect(branches.backboneClass).toEqual("Branches")
      expect(branches.project).toEqual(project)
      expect(branches.length).toBe(0)
    )

    it("returns empty GitLab.Blob model on project.blob(path)", ->
      blob = project.blob("subfolder/file.txt")
      expect(blob.backboneClass).toEqual("Blob")
      expect(blob.project).toEqual(project)
      expect(blob.get("name")).toEqual("subfolder/file.txt")
    )

    it("returns empty GitLab.Blob model on project.blob(path, branch)", ->
      blob = project.blob("subfolder/file.txt", "slave")
      expect(blob.backboneClass).toEqual("Blob")
      expect(blob.project).toEqual(project)
      expect(blob.branch).toEqual("slave")
      expect(blob.get("name")).toEqual("subfolder/file.txt")
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

  # CHECK THAT ALL MODELS THAT REWUIRE BRANCHES FAIL WHEN NOT PASSED IN

  # KEYS!!!!

  # CHCK PROJECT URL!!!!!
  # expect(project.url()).toEqual(url + "/projects/runemadsen%2Fbook")
  
  # CHECK THAT PATH GETS SET INSIDE PROJECT MODEL, NOT FROM GITLAB.project() 
  #expect(project.get("path")).toEqual("book")
  #expect(project.get("path_with_namespace")).toEqual("runemadsen/book")
  #expect(project.id).toBe(undefined)

  # CHECK TREE URL
  # expect(tree.url()).toEqual(url + "/projects/owner%2Fproject/repository/tree?path=%2F&ref_name=master")
  # expect(tree.url()).toEqual(url + "/projects/owner%2Fproject/repository/tree?path=subfolder&ref_name=master")

  #it("should fill collection on fetch", ->
  #      expect(user.sshkeys.url()).toEqual(url + "/user/keys")
  #      user.sshkeys.fetch()
  #      waitsFor(-> 
  #        return user.sshkeys.length > 0
  #      , "ssh keys never loaded", ajaxTimeout
  #      )
  #      runs(->
  #        expect(user.sshkeys.length).toBe(2)
  #        expect(user.sshkeys.first().backboneClass).toEqual("SSHKey")
  #        expect(user.sshkeys.first().get("title")).toEqual("Public key")
  #      )
  #    )
#
  #    it("should create a new ssh key", ->
  #      user.sshkeys.create(key:"Something")
  #      waitsFor(-> 
  #        return user.sshkeys.length > 0 && user.sshkeys.first().get("title")
  #      , "ssh keys never created", ajaxTimeout
  #      )
  #      runs(->
  #        expect(user.sshkeys.length).toBe(1)
  #        expect(user.sshkeys.first().get("title")).toEqual("Public key")
  #      )
  #    )

  
#
  # GitLab.Blob
  # ----------------------------------------------------------------

  describe("GitLab.Blob", ->
    
    masterBlob = null
    slaveBlob = null

    beforeEach(->
      masterBlob = new GitLab.Blob(
        name: "subfolder/master.txt"
      ,
        project: project1
      )

      slaveBlob = new GitLab.Blob(
        name: "subfolder/slave.txt"
      ,
        project: project1
        branch: "slave"
      )
    )

    it("should fail if correct options are not given", ->
      expect(true).toBe(false)
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
          expect(lastAjaxCall().args[0].url).toEqual(url + "/projects/owner%2Fproject/repository/blobs/master?filepath=subfolder/master.txt")
          expect(masterBlob.get("content")).toEqual("Hello!")
          expect(masterBlob.get("name")).toEqual("subfolder/master.txt")
        )
      )
  
      it("should use branch if specified", ->
        spyOnAjax()
        slaveBlob.fetchContent()
        expect(lastAjaxCall().args[0].url).toEqual(url + "/projects/owner%2Fproject/repository/blobs/slave?filepath=subfolder/slave.txt")
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

      describe("CREATE", ->

        it("should use correct defaults", ->
          spyOnAjax() 
          masterBlob.set("content", "New Content")
          masterBlob.save()
          expect(lastAjaxCall().args[0].url).toEqual(url + "/projects/owner%2Fproject/repository/files")
          expect(lastAjaxCall().args[0].type).toEqual("POST")
          expect(JSON.parse(lastAjaxCall().args[0].data)).toEqual(
            file_name: "master.txt"
            file_path: "subfolder/"
            content: "New Content"
            commit_message: "Created subfolder/master.txt"
            branch_name: "master"
          )
        )
  
        it("should use branch and commit message if specified", ->
          spyOnAjax() 
          slaveBlob.set("content", "New Content")
          slaveBlob.save(
            commit_message: "Another Message"
          )
          expect(lastAjaxCall().args[0].url).toEqual(url + "/projects/owner%2Fproject/repository/files")
          expect(lastAjaxCall().args[0].type).toEqual("POST")
          expect(JSON.parse(lastAjaxCall().args[0].data)).toEqual(
            file_name: "slave.txt"
            file_path: "subfolder/"
            content: "New Content"
            commit_message: "Another Message"
            branch_name: "slave"
          )
        )
      )
  
      describe("UPDATE", ->
        # CHECK THAT MODEL fetchContent or tree() always gives back a blob model that calls update, not create!!!!
      )
    )
  )

  # gitlab.project
  # ----------------------------------------------------------------

  describe("gitlab.project", ->

    

    it("should fetch the project", ->
      project = gitlab.project("runemadsen/book") # override project to bypass canned folder thing
      project.fetch()
      waitsFor(-> 
        return project.id
      , "project never loaded", ajaxTimeout
      )
      runs(->
        expect(project.get("name")).toBe("Book")
      )
    )

    # gitlab.project.branches
    # ---------------------------------------------------------

    describe("gitlab.project.branches", ->

      it("should fill collection on fetch", ->
        expect(project.branches.url()).toEqual(url + "/projects/owner%2Fproject/repository/branches")
        project.branches.fetch()
        waitsFor(-> 
          return project.branches.length > 0
        , "ssh keys never loaded", ajaxTimeout
        )
        runs(->
          expect(project.branches.length).toBe(2)
          expect(project.branches.first().backboneClass).toEqual("Branch")
          expect(project.branches.first().get("name")).toEqual("master")
        )
      )

    )

    # gitlab.project.members
    # ---------------------------------------------------------

    describe("gitlab.project.members", ->

      it("should instantiate an empty GitLab.Members collection on GitLab.Project#initialize", ->
        expect(project.members.backboneClass).toEqual("Members")
        expect(project.members.length).toBe(0)
      )

      it("should fill collection on fetch", ->
        expect(project.members.url()).toEqual(url + "/projects/owner%2Fproject/members")
        project.members.fetch()
        waitsFor(-> 
          return project.members.length > 0
        , "members never loaded", ajaxTimeout
        )
        runs(->
          expect(project.members.length).toBe(3)
          expect(project.members.first().backboneClass).toEqual("Member")
          expect(project.members.first().get("name")).toEqual("Rune Madsen")
        )
      )

      it("should create a new member", ->
        project.members.create(name:"Rune Madsen")
        waitsFor(-> 
          return project.members.length > 0 && project.members.first().id
        , "member never created", ajaxTimeout
        )
        runs(->
          expect(project.members.length).toBe(1)
          expect(project.members.first().get("username")).toEqual("runemadsen")
        )
      )
    )

    # gitlab.project.tree
    # ---------------------------------------------------------

    describe("gitlab.project.tree", ->

      it("should fetch the tree and parse trees/blobs", ->
        tree = project.tree("/")
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
          
          # put trees in trees array
          expect(tree.trees.length).toBe(1)
          subfolder = tree.trees[0]
          expect(subfolder.backboneClass).toEqual("Tree")
          expect(subfolder.path).toEqual("assets")
          expect(subfolder.length).toBe(0)
          expect(subfolder.url()).toBe(url + "/projects/owner%2Fproject/repository/tree?path=assets&ref_name=master") 
        )
      )

      it("should use branch if specified", ->
        tree = project.tree("/", "slave")
        expect(tree.url()).toEqual(url + "/projects/owner%2Fproject/repository/tree?path=%2F&ref_name=slave")
        tree.fetch()
        waitsFor(->
          return tree.length > 0
        , "tree never loaded", ajaxTimeout
        )
        runs(->
          blob = tree.first()
          expect(blob.branch).toEqual("slave") 
          subfolder = tree.trees[0]
          expect(subfolder.url()).toBe(url + "/projects/owner%2Fproject/repository/tree?path=assets&ref_name=slave") 
        )
      )
    )

  )
)

# make sure that the trees api returns full path in blob names when listing a subfolder. Otherwise blob.get("name") logic is wrong.

# TEST RESPONSE JSON IS ACTUALLY PARSED IN PARSE. NOT RIGHT NOW.

# MAKE SURE ALL THE ?file_path is in data instead!!!

# Clean up where I check URL's. One place to check GitLab.Blob urls.... One place to check GitLab.Tree url. In its own tests