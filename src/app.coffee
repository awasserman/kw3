express = require 'express'
app     = module.exports = express.createServer()
config  = require __dirname + '/config'
routes  = require __dirname + '/routes'

app.configure ->
  app.set 'views', __dirname + '/../views'
  app.set 'view engine', 'jade'
  app.use express.bodyParser()
  app.use express.static __dirname + '/../public'
  app.use app.router
  app.use express.errorHandler dumpExceptions: true, showStack: true


app.get '/', routes.index

app.post '/users', routes.users

app.post '/wings', routes.wings

app.listen process.env.VMC_APP_PORT or config.port,
  -> console.log 'Keep Winging Server initialized'