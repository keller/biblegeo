geolib = require('geolib')
express = require('express')
app = express()
server = require('http').createServer(app)
io = require('socket.io').listen(server)
events = require('events')
serverEmitter = new events.EventEmitter()

app.use(express.bodyParser())

port = process.env.PORT || 8000
server.listen(port)

app.get('/', (req, res) ->
  res.sendfile(__dirname + '/index.html');
)

app.post('/point', (req, res) ->
  if req.body.longitude? && req.body.latitude?
    # should check valid input
    serverEmitter.emit('new point', req.body)
    success = true
  else 
    success = false

  res.send(
    recieved: success
  )
)

io.sockets.on('connection', (socket) ->
  socket.on('set info', (info) ->
    coords = 
      latitude: info.latitude
      longitude: info.longitude
    socket.set('info', coords)
  )

  serverEmitter.on('new point', (point) ->
    socket.get('info', (err, info) ->
      if info.longitude? && info.latitude?
        maxDistance = 1000

        distance = geolib.getDistance(
          {latitude: point.latitude, longitude: point.longitude}, 
          {latitude: info.latitude, longitude: info.longitude}
        )
        socket.emit("local point", point) if distance < maxDistance

    )
  )
  socket.on('debug', (data, callback) ->
    socket.get('data', (err, info) ->
      console.log data
      console.log info
      callback(info)
    )
  )
)