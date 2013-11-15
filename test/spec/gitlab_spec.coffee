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

  # GitLab.Tree
  # ----------------------------------------------------------------

  # describe("GitLab.Tree", ->
  #   it("should parse listing into array of tree and blobs", ->
  #     tree = new GitLab.Tree([
  #       {
  #         "name": "assets",
  #         "type": "tree",
  #         "mode": "040000",
  #         "id": "6229c43a7e16fcc7e95f923f8ddadb8281d9c6c6"
  #       }, 
  #       {
  #         "name": "Rakefile",
  #         "type": "blob",
  #         "mode": "100644",
  #         "id": "35b2f05cbb4566b71b34554cf184a9d0bd9d46d6"
  #       }
  #     ])
  #     expect(tree.first().backboneClass).toEqual("Tree")
  #     expect(tree.first().path).toEqual("assets")
  #     expect(tree.first().sha).toEqual("6229c43a7e16fcc7e95f923f8ddadb8281d9c6c6")
  #     expect(tree.first().length).toBe(0)
  #     expect(tree.first().url()).toBe(url + "/projects/runemadsen%2Fbook?path=assets")  # 
  #     expect(tree.last().backboneClass).toEqual("Blob")
  #     expect(tree.last().get("name")).toEqual("Rakefile")
  #   )
  # )

  # GitLab.Blob
  # ----------------------------------------------------------------

  #describe("GitLab.Blob", ->
  #  it("should call correct url", ->
  #    # FILL WITH DATA FROM TREE AND MAKE SURE THE FETCH, SAVE, DESTROY METHODS CALL CORRECT URL
  #    expect(true).toBe(false)
  #  )
  #)

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

    project = null

    beforeEach(-> 
      project = gitlab.project("owner/project")
    )

    it("should return empty project model", ->
      project = gitlab.project("runemadsen/book") # override project to bypass canned folder thing
      expect(project.get("path")).toEqual("book")
      expect(project.get("path_with_namespace")).toEqual("runemadsen/book")
      expect(project.id).toBe(undefined)
      expect(project.url()).toEqual(url + "/projects/runemadsen%2Fbook")
    )

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

    # gitlab.project.contents
    # ---------------------------------------------------------

    describe("gitlab.project.tree", ->

      it("should return empty tree model", ->
        tree = project.tree()
        expect(tree.backboneClass).toEqual("Tree")
        expect(tree.id).toBe(undefined)
        expect(tree.url()).toEqual(url + "/projects/owner%2Fproject/repository/tree")
      )

      it("should return empty subfolder tree", ->
        tree = project.tree("subfolder")
        expect(tree.backboneClass).toEqual("Tree")
        expect(tree.id).toBe(undefined)
        expect(tree.url()).toEqual(url + "/projects/owner%2Fproject/repository/tree?path=subfolder")
      )
  
      it("should fetch the tree and parse trees/blobs", ->
        tree = project.tree()
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
          expect(blob.get("name")).toEqual("README.md")
          expect(blob.url()).toEqual(url + "/projects/owner%2Fproject/repository/blobs/master?filepath=README.md") 
          
          # put trees in trees array
          expect(tree.trees.length).toBe(1)
          subfolder = tree.trees[0]
          expect(subfolder.backboneClass).toEqual("Tree")
          expect(subfolder.path).toEqual("assets")
          expect(subfolder.sha).toEqual("6229c43a7e16fcc7e95f923f8ddadb8281d9c6c6")
          expect(subfolder.length).toBe(0)
          expect(subfolder.url()).toBe(url + "/projects/owner%2Fproject/repository/tree?path=assets") 
        )
      )

      # YOU CAN FETCH MODEL FROM THE MODEL YOU GOT FROM TREE!!!

      # fetch for a tree model only updates the "content" and doesn't erase the other data

      # IT SHOULD FETACH ANOTHER BRANCH BOTH TREE AND BLOB. IT SHOULD KEEP THE BRANCH WHEN GETTING BLOBS FROM TREES!

      # project.blob get blob directly without loading a tree

      # tree fetch should work on subsubfolders. Does name have full path?

      # make sure the save, update, destroy stuff works
    )
  )
)