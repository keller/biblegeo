books_displays= Gen:"Genesis",Exod:"Exodus",Lev:"Leviticus",Num:"Numbers",Deut:"Deuteronomy",Josh:"Joshua",Judg:"Judges",Ruth:"Ruth","1Sam":"1 Samuel","2Sam":"2 Samuel","1Kgs":"1 Kings","2Kgs":"2 Kings","1Chr":"1 Chronicles","2Chr":"2 Chronicles",Ezra:"Ezra",Neh:"Nehemiah",Esth:"Esther",Job:"Job",Ps:"Psalm",Prov:"Proverbs",Eccl:"Ecclesiastes",Song:"Song of Solomon",Isa:"Isaiah",Jer:"Jeremiah",Lam:"Lamentations",Ezek:"Ezekiel",Dan:"Daniel",Hos:"Hosea",Joel:"Joel",Amos:"Amos",Obad:"Obadiah",Jonah:"Jonah",Mic:"Micah", Nah:"Nahum",Hab:"Habakkuk",Zeph:"Zephaniah",Hag:"Haggai",Zech:"Zechariah",Mal:"Malachi",Matt:"Matthew",Mark:"Mark",Luke:"Luke",John:"John",Acts:"Acts",Rom:"Romans","1Cor":"1 Corinthians","2Cor":"2 Corinthians",Gal:"Galatians",Eph:"Ephesians",Phil:"Philippians",Col:"Colossians","1Thess":"1 Thessalonians","2Thess":"2 Thessalonians","1Tim":"1 Timothy","2Tim":"2 Timothy",Titus:"Titus",Phlm:"Philemon",Heb:"Hebrews",Jas:"James","1Pet":"1 Peter","2Pet":"2 Peter","1John":"1 John","2John":"2 John","3John":"3 John", Jude:"Jude",Rev:"Revelation",Tob:"Tobit",Jdt:"Judith","1Macc":"1 Maccabees","2Macc":"2 Maccabees",Sir:"Sirach",Wis:"Wisdom",Bar:"Baruch",GkEst:"Greek Esther",EpJer:"Letter of Jeremiah",SgThr:"Song of the Three Young Men",PrAz:"Prayer of Azariah",Sus:"Susanna",Bel:"Bel and the Dragon","1Esd":"1 Esdras",PrMan:"Prayer of Manasseh",Ps151:"Psalm 151","3Ma":"3 Maccabees","2Esd":"2 Esdras","4Ma":"4 Maccabees",AdEst:"Additions to Esther"
create_passage_displays = (osises) ->
  passage_displays = []
  for osis in osises
    passage_display = ''
    for osis_part, i in osis.split '-'
      passage_display += '-' if i == 1
      passage_parts = osis_part.split('.')
      passage_display += "" + books_displays[passage_parts[0]] + " " + passage_parts[1]
      passage_display += ":" + passage_parts[2] if passage_parts[2]?

    passage_displays.push(passage_display)

  passage_displays

L.Map = L.Map.extend(
  openPopup: (popup) ->
    
    # @closePopup()  #just comment this
    @_popup = popup;

    @addLayer(popup).fire('popupopen',
      popup: @_popup
    )
    # console.log layer
    # @removeLayer(layer)
)
map = L.map('map',
  center: [37.8, -96]
  zoom: 4
  maxZoom: 12
)
L.tileLayer('http://{s}.tile.osm.org/{z}/{x}/{y}.png', 
    attribution: '&copy; <a href="http://osm.org/copyright">OpenStreetMap</a> contributors'
).addTo(map)


# L.tileLayer('http://{s}.tile.cloudmade.com/{key}/{styleId}/256/{z}/{x}/{y}.png', {
#     key: '2bcc2489d43c44b597bf7b4cbd26cc96'
#     styleId: 22677
# }).addTo(map)

if (navigator.geolocation)
  socket = io.connect('http://'+location.host+'/map')

  socket.on('connect',  () ->
    # connect
  )
    
  socket.on('new point', (data) ->
    passages = create_passage_displays(data.passages)
    passage_display = passages.join(", ")
    L.marker([data.latitude, data.longitude]).addTo(map).bindPopup(passage_display).openPopup()
    # marker = L.marker([data.latitude, data.longitude]).addTo(map)
    # popup = L.popup().setContent(passage_display)
    # map.addLayer(popup)

  )