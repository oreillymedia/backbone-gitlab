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

# user.key.create(data)   # CRUD methods available on the collection

    )
  )

#
  #  it("INDEX should fetch users", ->
  #    users = new GitLab.Users()
  #    users.fetch()
  #    
  #    waitsFor(-> 
  #      return users.length > 0
  #    , "Users never loaded", ajaxTimeout
  #    )
#
  #    runs(->
  #      expect(users.length).toEqual(3)
  #      expect(users.first().get("username")).toEqual("runemadsen")
  #      expect(users.last().get("username")).toEqual("zachschwartz")
  #    )
  #  )
#
  #  it("POST should create user and assign correct url", ->
  #    users = new GitLab.Users()
  #    user = users.create(username:"runemadsen")
#
  #    waitsFor(-> 
  #      return user.id == 1
  #    , "User was never created", ajaxTimeout
  #    )
#
  #    runs(->
  #      expect(user.url()).toEqual(url + "/users/1")
  #    )
  #  )
  #)
)

 
# you can get a GitLab.Project model by using the project() function
# project = gitlab.project("myproject")   # => (empty)
# project.fetch()                         # => (loaded)
 
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