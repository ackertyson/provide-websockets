class UserSession
  constructor: (@user, @connection, @handlers) ->
    throw new Error 'No USER provided' unless @user?
    throw new Error 'No CONNECTION provided' unless @connection?
    throw new Error 'No HANDLERS provided' unless @handlers?
    @connection.on 'message', @handleMsg

  emit: (msg, body) =>
    return unless @connection.connected
    body = body.message if msg is 'error'
    @connection.sendUTF JSON.stringify { msg, body }

  handleMsg: (message) =>
    throw new Error 'No handlers provided!' unless @handlers?
    throw new Error 'UTF8 messages only!' unless message.type is 'utf8'
    { msg, body } = JSON.parse message.utf8Data
    throw new Error 'Bad message format' unless msg?
    throw new Error "No Websocket handler found for message type '#{msg}'" unless @handlers[msg]?
    @handlers[msg]
      payload: body
      handle: @pHandler
      toClient: @emit
      user: @user

  pHandler: (handler, mock_req) -> # wrap Express handler in Promise
    new Promise (resolve, reject) ->
      mock_res =
        headers: {}
        json: (data) ->
          resolve { code: 200, data }
        sendStatus: (code) ->
          return reject { code } if code >= 400
          resolve { code }
        send: (data) ->
          resolve { code: 200, data, headers: @headers }
        set: (header, value) ->
          @headers[header] = value
        status: (code) -> json: (data) ->
          return reject { code, data } if code >= 400
          resolve { code, data }
      handler mock_req, mock_res


module.exports = UserSession
