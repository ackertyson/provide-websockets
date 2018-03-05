{ isFunction } = require 'lodash'

class SimpleSocketClient
  @_callbacks: {}

  constructor: (@host, handleError, @protocol='provide-ws') ->
    @handleError = handleError or @_handleError
    @ctor = @constructor

  _handleError: (err) ->
    console.log 'General socket error:', err

  handleMessage: (message) ->
    { msg, body } = JSON.parse message.data
    throw new Error 'Bad message format' unless msg?
    return @handleError body if msg is 'error' # general error
    msg_arr = msg.split ' '
    response_type = msg_arr.pop() # 'data' or 'error'
    sent_as_msg = msg_arr.join ' '
    @ctor._callbacks[sent_as_msg][response_type] body # invoke corresponding handler for this msg+response type

  init: (token, proceed) ->
    @socket = new WebSocket "#{@host}?token=#{token}", @protocol
    @socket.onopen = () =>
      @socket.onmessage = @handleMessage.bind @
      proceed @
    @socket.onerror = @handleError.bind @

  send: (msg, body, onData, onError, onConnectionError) ->
    throw new Error 'Bad message format' unless msg?
    throw new Error 'onData must be a function!' unless isFunction onData
    onError ?= @_handleError
    throw new Error 'onError must be a function!' unless isFunction onError
    onConnectionError ?= @_handleError
    throw new Error 'onConnectionError must be a function!' unless isFunction onConnectionError
    @ctor._callbacks[msg] = data: onData, error: onError
    if @socket.readyState is WebSocket.OPEN
      @socket.send JSON.stringify { msg, body }
    else
      onConnectionError new Error('Socket is closed'), msg, body, onData, onError


module.exports = SimpleSocketClient
