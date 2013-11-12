lib: coffee -w -o test/ -c backbone-gitlab.coffee
spec: coffee -w -c test/spec/
canned: node_modules/.bin/canned -p 5000 --headers "PRIVATE-TOKEN" ./test/canned
server: node test/server.js