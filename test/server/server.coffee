noop = ->
httpServer =
  on: ->
handlers =
  fake: ({ payload, toClient, user }) ->
    console.log payload
WSS = require('../../src').Server
wss = new WSS httpServer, handlers, noop, 'bad_secret'


describe 'Websocket Server', ->
  describe 'ctor', ->
    it 'should throw if no SERVER', ->
      expect(require('../../src/server')).to.throw 'No HttpServer passed to ctor'

    it 'should throw if no SECRET', ->
      expect(-> require('../../src/server') {}).to.throw 'No SECRET passed to ctor and JWT_SECRET env var not set'


  describe '_customHandler', ->
    it 'should send token on success', ->
      handler =
        (req, res, next) ->
          ret_val = { id: req.user.identifier }
          ret_val
      req =
        user:
          identifier: 1234
      res = 'mock_res'
      sendToken = sinon.stub(wss, '_sendToken').returns()
      wss._customHandler(handler, '5s')(req, res).then (response) ->
        sinon.assert.calledWith sendToken, sinon.match({ id: 1234 }), 'mock_res', '5s'
        sendToken.restore()

    it 'should handle rejection (via next)', ->
      handler =
        (req, res, next) ->
          Promise.reject new Error 'nope'
      req = {}
      res = {}
      next = (err) ->
        err.should.have.property 'message', 'nope'
      sendToken = sinon.stub(wss, '_sendToken').returns()
      wss._customHandler(handler, '5s')(req, res, next).then (response) ->
        sinon.assert.notCalled sendToken
        sendToken.restore()
