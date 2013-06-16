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


nearby = io.of('/nearby').on('connection', (socket) ->
  socket.on('set info', (info) ->
    socket.set('info', info)
  )

  serverEmitter.on('new point', (point) ->
    socket.get('info', (err, info) ->
      if info.longitude? && info.latitude?
        maxDistance = 1000
        circleDistance = maxDistance
        circleDistance += info.accuracy if info.accuracy?
        circleDistance += point.accuracy if point.accuracy?

        isPointInCircle = geolib.isPointInCircle(
          {latitude: point.latitude, longitude: point.longitude}, 
          {latitude: info.latitude, longitude: info.longitude},
          circleDistance
        )
        socket.emit("nearby point", point) if isPointInCircle

    )
  )
)