# provide-websockets

## Install

`npm install --save provide-websockets`

## Usage

In server app:

```
http = require 'http'
app = express()
httpServer = http.createServer app
handlers =
  'requestX': ({ payload, toClient, user }) ->
    Model.get payload.identifier
      .then (response) ->
        toClient 'requestX data', response
      .catch (err) ->
        toClient 'requestX error', err
socket = require('provide-websockets').server httpServer, handlers

# endpoint for socket request authentication
app.get '/auth/socket/token', socket.middleware ['id', 'first_name', 'last_name']

port = process.env.PORT or 3000
httpServer.listen port, ->
  console.log "App running on #{port}..."
```

## Local dev

`gulp`

## TEST

`npm test`
