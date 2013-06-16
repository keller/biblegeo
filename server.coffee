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

app.get("/test", (req, res) ->
  res.sendfile(__dirname + '/test.html');
)

app.post('/point', (req, res) ->
  # cors!
  if req.headers.origin.match(/http:\/\/\w+\.biblegateway\.com/)
    res.set('Access-Control-Allow-Origin', req.headers.origin);
    res.set('Access-Control-Allow-Methods', 'POST');
    res.set('Access-Control-Allow-Headers', 'X-Requested-With, Content-Type');
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
      if info?.longitude && info?.latitude && point?.latitude && point?.longitude
        maxDistance = 1000
        circleDistance = maxDistance
        circleDistance += info.accuracy if info.accuracy?
        circleDistance += point.accuracy if point.accuracy?

        isPointInCircle = geolib.isPointInCircle(
          {latitude: point.latitude, longitude: point.longitude}, 
          {latitude: info.latitude, longitude: info.longitude},
          circleDistance
        )
        same_client = if point.id? && info.id? && point.id == info.id then true else false
        # socket.emit("nearby point", point) if isPointInCircle
        socket.emit("nearby point", point) if isPointInCircle && !same_client

    )
  )
)

map = io.of('/map').on('connection', (socket) ->
  serverEmitter.on('new point', (point) ->
    socket.emit("new point", point)
  )
)