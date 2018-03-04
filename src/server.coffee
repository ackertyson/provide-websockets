WebSocketServer = require('websocket').server
jwt = require 'jsonwebtoken'
{ pick } = require 'lodash'
UserSession = require './user_session'


class SimpleWebSockets
  constructor: ({ handlers, httpServer, secret, verify }={}) ->
    throw new Error 'No HTTPSERVER passed to ctor' unless httpServer?
    @handlers = handlers
    throw new Error 'No HANDLERS passed to ctor' unless @handlers?
    @secret = secret or process.env.JWT_SECRET
    throw new Error "No SECRET passed to ctor and JWT_SECRET env var not set" unless @secret?
    @verify = verify or (user) -> Promise.resolve user # default pass-thru
    ws = new WebSocketServer { httpServer }
    ws.on 'request', @handleConnection

  _customHandler: (handler, expiresIn) ->
    (req, res, next) =>
      proceed = handler.call @, req, res, next
      # coerce HANDLER to return Promise
      Promise.resolve(proceed).then (payload) =>
        @_sendToken payload, res, expiresIn
      , (err) ->
        console.log err unless process.env.NODE_ENV is 'test'
        next err

  establishSession: (user, connection) ->
    session = new UserSession user, connection, @handlers
    connection.on 'close', ->
      session = null

  handleConnection: (request) => # establish new socket connection for user
    { token } = request.resourceURL.query
    @_verify(token).then (user) =>
      connection = request.accept('provide-ws', request.origin)
      @establishSession user, connection
    .catch (err) ->
      console.log err unless process.env.NODE_ENV is 'test'
      request.reject 401

  middleware: (propsOrHandler, expiresIn) ->
    # Express should pass a custom handler which returns JWT payload...
    if @_typeof propsOrHandler, 'function', 'generatorfunction'
      return @_customHandler propsOrHandler, expiresIn
    # ...or an array of properties which should be picked from req.user to form payload
    props = propsOrHandler
    unless Array.isArray props
      throw new Error "Socket middleware should pass a custom handler function
        which returns USER available to handlers or an array of props to pull
        from req.user for that purpose"
    (req, res, next) =>
      payload = pick req.user, props...
      @_sendToken payload, res, expiresIn

  _sendToken: (payload, res, expiresIn='5m') ->
    token = jwt.sign payload, @secret, { expiresIn }
    res.json { token }

  _typeof: (subject, type...) ->
    # typeof that actually works!
    Object::toString.call(subject).toLowerCase().slice(8, -1) in type

  _verify: (token) ->
    new Promise (resolve, reject) =>
      return reject(new Error 'No token provided') unless token?
      jwt.verify token, @secret, (err, payload) =>
        if err?
          console.log err unless process.env.NODE_ENV is 'test'
          return reject err
        resolve @verify payload


module.exports = SimpleWebSockets
