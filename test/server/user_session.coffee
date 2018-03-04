UserSession = require '../../src/user_session'
user =
  identifier: 1234
  name: 'Frank'
connection =
  connected: false
  on: ->
  sendUTF: ->

describe 'UserSession', ->
  describe 'ctor', ->
    it 'should throw if no user', ->
      expect(-> new UserSession).to.throw 'No USER provided'

    it 'should throw if no connection', ->
      expect(-> new UserSession {}).to.throw 'No CONNECTION provided'

    it 'should throw if no handlers', ->
      expect(-> new UserSession {}, {}).to.throw 'No HANDLERS provided'


  describe 'emit', ->


  describe 'handleMsg', ->
    it 'should call handler with args', ->
      handlers =
        fake: (arg) ->
          arg.should.have.property 'payload'
          arg.payload.should.have.property 'name', 'Sue'
          arg.should.have.property 'user'
          arg.user.should.have.property 'name', 'Frank'
      session = new UserSession user, connection, handlers
      msg =
        utf8Data: JSON.stringify { msg: 'fake', body: { name: 'Sue' }}
        type: 'utf8'
      session.handleMsg msg

    it 'should throw on bad message', ->
      handlers =
        fake: ->
      session = new UserSession user, connection, handlers
      msg =
        utf8Data: JSON.stringify { body: 'Hi there' }
        type: 'utf8'
      expect(-> session.handleMsg msg).to.throw 'Bad message format'

    it 'should throw on bad message encoding', ->
      handlers =
        fake: ->
      session = new UserSession user, connection, handlers
      msg =
        utf8Data: JSON.stringify { body: 'Hi there' }
        type: 'utf6'
      expect(-> session.handleMsg msg).to.throw 'UTF8 messages only!'

    it 'should throw on missing handler', ->
      handlers =
        real: ->
      session = new UserSession user, connection, handlers
      msg =
        utf8Data: JSON.stringify { msg: 'fake', body: 'Hi there' }
        type: 'utf8'
      expect(-> session.handleMsg msg).to.throw "No Websocket handler found for message type 'fake'"


  describe 'pHandler', ->
    it 'should call (mock) res on success', ->
      session = new UserSession user, connection, {}
      handler = (req, res, next) ->
        id = req.params.id
        return res.sendStatus 500 unless id > 1233
        res.status(200).json { fetched: id }
      mock_req =
        params:
          id: 1234
      session.pHandler handler, mock_req
        .then (response) ->
          response.should.have.property 'code', 200
          response.should.have.property 'data'
          response.data.should.have.property 'fetched', 1234

    it 'should reject on error', ->
      session = new UserSession user, connection, {}
      handler = (req, res, next) ->
        id = req.params.id
        return res.sendStatus 500 unless id > 1233
        res.status(200).json { fetched: id }
      mock_req =
        params:
          id: 1233
      session.pHandler handler, mock_req
        .catch (err) ->
          err.should.have.property 'code', 500
