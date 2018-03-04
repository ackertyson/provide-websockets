# provide-websockets

## Install

`npm install --save provide-websockets`

## Usage

```
http = require 'http'
app = express()
httpServer = http.createServer app
Model = require './models-from-somewhere'
handlers =
  requestX: ({ payload, sendData, sendError, user }) ->
    Model.get payload.identifier
      .then (response) ->
        sendData response
      .catch (err) ->
        sendError err
WSS = require('provide-websockets').Server
socket = new WSS { httpServer, handlers }

# endpoint for socket request authentication + USER middleware definition
app.get '/auth/socket/token', socket.middleware ['id', 'first_name', 'last_name']

port = process.env.PORT or 3000
httpServer.listen port, ->
  console.log "App running on #{port}..."
```

The handler `payload` is whatever gets passed in the client request.

The middleware passed to the auth endpoint is building the `user` object
available in socket handlers. You can either provide an array of properties to
pick from `req.user` (shown) or pass a custom middleware which returns whatever
`user` you want available in your handlers.

## Local dev

`gulp`

## Test

`npm test`
