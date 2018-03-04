wss = require '../../src/server'

describe 'Websocket Server', ->
  describe '_customHandler', ->
    it 'should do stuff', ->
      console.log wss._customHandler()
