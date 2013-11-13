ajaxTimeout = 3000
token = "abcdefg"
url = "http://127.0.0.1:5000"

describe("GitLab", ->

  beforeEach(->
    GitLab.token = token
    GitLab.url = url
  )

  # GitLab
  # ----------------------------------------------------------------

  it("should set default variables", ->
    expect(GitLab.token).toBe(token)
    expect(GitLab.url).toBe(url)
    expect(GitLab.version).toBe("v3")
  )

  # GitLab.User
  # ----------------------------------------------------------------

  describe("GitLab.Users", ->

    it("INDEX should fetch users", ->
      users = new GitLab.Users()
      users.fetch()
      
      waitsFor(-> 
        return users.length > 0
      , "Users never loaded", ajaxTimeout
      )

      runs(->
        expect(users.length).toEqual(3);
        expect(users.first().get("username")).toEqual("runemadsen")
        expect(users.last().get("username")).toEqual("zachschwartz")
      )
    )

    it("POST should create user and assign correct url", ->
      users = new GitLab.Users()
      user = users.create(username:"runemadsen")

      waitsFor(-> 
        return user.id == 1
      , "User was never created", ajaxTimeout
      )

      runs(->
        expect(user.url()).toEqual(url + "/users/1");
      )
    )
  )


)