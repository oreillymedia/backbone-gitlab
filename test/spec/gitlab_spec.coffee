ajaxTimeout = 3000
token = "abcdefg"
url = "http://127.0.0.1:5000"

describe("GitLab", ->

  gitlab = null
  user = null

  beforeEach(->
    GitLab.url = url
    gitlab = new GitLab.Client(token)
    user = gitlab.user
  )

  # GitLab
  # ----------------------------------------------------------------

  it("should instantiate a new GitLab client", ->
    expect(gitlab.token).toBe(token)
  )

  # gitlab.user
  # ----------------------------------------------------------------

  describe("gitlab.user", ->
    
    it("should return empty model", ->
      expect(gitlab.user.backboneClass).toEqual("User")
    )

    it("should fill empty model on fetch", ->
      expect(user.url()).toEqual(url + "/user")
      user.fetch()
      waitsFor(-> 
        return user.id == 1
      , "user never loaded", ajaxTimeout
      )
      runs(->
        expect(user.get("username")).toEqual("runemadsen")
      )
    )

    # gitlab.user.keys
    # ---------------------------------------------------------

    describe("gitlab.user.keys", ->

      it("should instantiate an empty GitLab.Keys collection on GitLab.User#initialize", ->
        expect(user.sshkeys.backboneClass).toEqual("SSHKeys")
        expect(user.sshkeys.length).toBe(0)
      )

      it("should fill collection on fetch", ->
        expect(user.sshkeys.url()).toEqual(url + "/user/keys")
        user.sshkeys.fetch()
        waitsFor(-> 
          return user.sshkeys.length > 0
        , "ssh keys never loaded", ajaxTimeout
        )
        runs(->
          expect(user.sshkeys.length).toBe(2)
          expect(user.sshkeys.first().backboneClass).toEqual("SSHKey")
          expect(user.sshkeys.first().get("title")).toEqual("Public key")
        )
      )

      it("should create a new ssh key", ->
        user.sshkeys.create(key:"Something")
        waitsFor(-> 
          return user.sshkeys.length > 0 && user.sshkeys.first().get("title")
        , "ssh keys never created", ajaxTimeout
        )
        runs(->
          expect(user.sshkeys.length).toBe(1)
          expect(user.sshkeys.first().get("title")).toEqual("Public key")
        )
      )
    )
  )

  # gitlab.project
  # ----------------------------------------------------------------

  describe("gitlab.project", ->

    it("should return empty project model", ->
      project = gitlab.project("runemadsen/book")
      expect(project.get("path")).toEqual("book")
      expect(project.get("path_with_namespace")).toEqual("runemadsen/book")
      expect(project.id).toBe(undefined)
      expect(project.url()).toEqual(url + "/projects/runemadsen%2Fbook")
    )

    it("should fetch the project", ->
      project = gitlab.project("runemadsen/book")
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

      project = null

      beforeEach(-> 
        # using another repo name to bypass limitations of canned
        # if we create a folder with runemadsen name, it doesn't fetch any.get.json
        project = gitlab.project("owner/project") 
      )

      it("should instantiate an empty GitLab.Branches collection on GitLab.Project#initialize", ->
        expect(project.branches.backboneClass).toEqual("Branches")
        expect(project.branches.length).toBe(0)
      )

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
  )
)
 
# an empty GitLab.Branches collection is created on GitLab.Project#initialize
# project.branches              # => (empty)
# project.branches.fetch()      # => (loaded)
 
# an empty GitLab.Members collection is created on GitLab.Project#initialize
# project.members                 # => (empty)
# project.members.fetch           # => (loaded)
# project.members.create(data)    # CRUD methods available on the collection
 
# you can get a GitLab.File model OR a GitLab.Folder collection by using the contents() function
# project.contents(path, success, error)
 
# this shows how you can interact with the files and folders
# project.contents("/", (data) ->
#   console.log data           # => GitLab.Folder collection
#   console.log data.first()   # => GitLab.File model (empty)
#   file = data.first()
#   file.fetch()                  # (loaded)
#   file.get("content")           # returns content
#   file.set("content", "Rune")   # sets content
#   file.save()                   # updates content
#   file.destroy()                # delete file
# )