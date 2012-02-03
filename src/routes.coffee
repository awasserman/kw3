config   = require __dirname + '/config'
models   = require __dirname + '/models'
app      = require __dirname + '/app'
mongoose = require 'mongoose'
async    = require 'async'
io       = require('socket.io').listen app

io.enable 'browser client minification'
io.enable 'browser client etag'
io.enable 'browser client gzip'
io.set 'log level', 1

User = null
FeedItem = null
totalCount = 0

models.define mongoose, ->
  User = mongoose.model 'User'
  FeedItem = mongoose.model 'FeedItem'
  mongoose.connect config.dbUrl


exports.index = (req, res) ->

  async.parallel

    users: (cb) ->
      User.find {}, (err, users) -> cb null, users

    feedItems: (cb) ->
      FeedItem.find().limit(30).sort('createdAt', -1).run (err, feedItems) -> cb null, feedItems

    (err, results) ->
      totalCount = results.users.map((user) -> user.wings).reduce (prev, current) ->
        prev + current

      res.render 'index', locals:
        users: results.users
        feedItems: results.feedItems
        total: totalCount



exports.wings = (req, res) ->
  { rfid } = req.body
  return res.send 500 unless rfid

  User.findOne rfid: rfid, (err, user) ->
    return res.send 500 unless user
    user.wings += config.wingCount
    totalCount += config.wingCount
    feedText = "#{ user.name } just ate #{ config.wingCount } more wings."

    io.sockets.emit 'tap',
      rfid: rfid
      wings: user.wings
      text: feedText
      total: totalCount

    feedItem = new FeedItem
      text: feedText
      user: user.rfid

    user.save()
    feedItem.save()
    res.send 200



exports.users = (req, res) ->
  { rfid } = req.body
  User.findOne rfid: rfid, (err, user) ->
    if user
      res.send 500
    else
      newUser = new User req.body
      feedItem = new FeedItem
        text: "#{ newUser.name } of #{ newUser.team } just joined the fight."
        user: newUser.rfid
      newUser.save()
      feedItem.save()
      io.sockets.emit 'newUser', text: feedItem.text
      res.send 200
