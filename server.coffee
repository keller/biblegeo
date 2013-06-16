pg = require('pg')
geolib = require('geolib')
express = require('express')
app = express()
server = require('http').createServer(app)
io = require('socket.io').listen(server)
events = require('events')
serverEmitter = new events.EventEmitter()

conString = process.env.DATABASE_URL || "tcp://kellerdavis@localhost/geobible"

app.use(express.bodyParser())

port = process.env.PORT || 8000
server.listen(port)

app.get('/', (req, res) ->
  res.sendfile(__dirname + '/index.html');
)

app.post('/point', (req, res) ->
  longitude = req.body.longitude
  latitude = req.body.latitude
  osis_ref = req.body.osis_ref
  version = req.body.version

  pgClient = new pg.Client(conString)
  pgClient.connect( (err) ->

    sql = "INSERT INTO requests (osis_ref, version, location) VALUES ('#{osis_ref}', '#{version}', 'POINT(#{longitude} #{latitude})')"
    # console.log sql
    pgClient.query(sql, (err, result) ->
      # handle error?
    )
  )

  serverEmitter.emit('bg request', req.body)
  # io.sockets.emit("bg request", req.body);

  res.send(
    saved: 'success'
  )
)

app.get('/point', (req, res) ->
  longitude = req.query.longitude
  latitude = req.query.latitude
  distance = req.body.distance || 1000
  limit = req.body.limit || 10

  pgClient = new pg.Client(conString)
  pgClient.connect( (err) ->

    sql = "SELECT osis_ref, version, ST_X(location::geometry) AS longitude, ST_Y(location::geometry) AS latitude FROM requests WHERE ST_DWithin( location, 'POINT(#{longitude} #{latitude})', #{distance}) ORDER BY time_requested DESC LIMIT #{limit}"
    pgClient.query(sql, (err, result) ->
      res.send(
        refs: result.rows
      )
    )
  )
  
)

io.sockets.on('connection', (socket) ->
  socket.on('set location', (location, callback) ->
    coords = 
      latitude: location.latitude
      longitude: location.longitude
    socket.set('location', coords, () ->
      callback()
    )
  )

  serverEmitter.on('bg request', (data) ->
    socket.get('location', (err, location) ->
      if location.longitude? && location.latitude?
        maxDistance = 1000

        distance = geolib.getDistance(
          {latitude: data.latitude, longitude: data.longitude}, 
          {latitude: location.latitude, longitude: location.longitude}
        )
        socket.emit("local osis", osis: data.osis_ref) if distance < maxDistance

    )
  )
  socket.on('debug', (data, callback) ->
    socket.get('location', (err, location) ->
      console.log data
      console.log location
      callback(location)
    )
  )
)