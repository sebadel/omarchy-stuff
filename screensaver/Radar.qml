import QtQuick
import QtQuick.Window
import "map.js" as Map

Window {
    id: root
    visible: true
    width: 1440
    height: 900
    visibility: Window.FullScreen
    color: "#000c08"
    title: "fw-radar"

    property real centerLat: 50.7806
    property real centerLon: 4.7696
    property real radiusKm: 100.0
    readonly property real kmPerDegLat: 111.0
    readonly property real kmPerDegLon: 111.0 * Math.cos(centerLat * Math.PI / 180)

    property var states: []
    property real sweep: 0
    property string fontFam: "JetBrainsMono Nerd Font"

    property var airports: [
        ["EBAM", 50.7401, 3.4849], ["EBAR", 49.6620, 5.8860], ["EBAV", 50.7061, 5.0677],
        ["EBAW", 51.1907, 4.4632], ["EBBE", 50.7586, 4.7683], ["EBBL", 51.1683, 5.4700],
        ["EBBN", 50.4150, 6.2764], ["EBBR", 50.9014, 4.4844], ["EBBT", 51.3426, 4.5035],
        ["EBBX", 49.8915, 5.2274], ["EBBY", 50.5681, 4.4352], ["EBBZ", 50.5423, 4.3825],
        ["EBCF", 50.1528, 4.3872], ["EBCI", 50.4620, 4.4596], ["EBCV", 50.5758, 3.8310],
        ["EBDT", 51.0040, 5.0647], ["EBFN", 51.0903, 2.6528], ["EBFS", 50.2433, 4.6458],
        ["EBGB", 50.9485, 4.3918], ["EBGG", 50.7556, 3.8639], ["EBHN", 51.3061, 4.3872],
        ["EBIS", 50.6636, 3.8047], ["EBKH", 51.1810, 5.2211], ["EBKT", 50.8189, 3.2096],
        ["EBLE", 51.1200, 5.3072], ["EBLG", 50.6386, 5.4439], ["EBMB", 50.9134, 4.4910],
        ["EBMG", 50.1042, 4.6361], ["EBML", 50.3750, 4.9265], ["EBMO", 50.8513, 3.1477],
        ["EBNM", 50.4897, 4.7697], ["EBOS", 51.1998, 2.8747], ["EBSG", 50.4580, 3.8210],
        ["EBSH", 50.0359, 5.4043], ["EBSL", 50.9494, 5.5935], ["EBSM", 51.2683, 4.1755],
        ["EBSP", 50.4820, 5.9134], ["EBST", 50.7908, 5.1996], ["EBSU", 50.0344, 5.4408],
        ["EBTN", 50.7817, 4.9578], ["EBTX", 50.5511, 5.8540], ["EBTY", 50.5316, 3.4962],
        ["EBUL", 51.1442, 3.4756], ["EBWE", 51.3948, 4.9602], ["EBZH", 50.9704, 5.3753],
        ["EBZR", 51.2691, 4.7624], ["EBZU", 51.2555, 3.1399], ["EBZW", 51.0154, 5.5265]
    ]

    property bool ready: false

    onActiveChanged: { if (root.ready && !active) Qt.quit() }

    Component.onCompleted: {
        root.fetchData()
        readyTimer.start()
    }

    Timer {
        id: readyTimer
        interval: 2000
        repeat: false
        onTriggered: root.ready = true
    }

    function fmtAlt(ft) {
        if (ft >= 4500) return "FL" + Math.round(ft / 100)
        return Math.round(ft) + "ft"
    }

    function bbox() {
        var dlat = radiusKm / kmPerDegLat
        var dlon = radiusKm / kmPerDegLon
        return { lamin: centerLat - dlat, lomin: centerLon - dlon, lamax: centerLat + dlat, lomax: centerLon + dlon }
    }

    function fetchData() {
        var xhr = new XMLHttpRequest()
        var b = root.bbox()
        var url = "https://opensky-network.org/api/states/all?lamin=" + b.lamin.toFixed(3)
            + "&lomin=" + b.lomin.toFixed(3) + "&lamax=" + b.lamax.toFixed(3) + "&lomax=" + b.lomax.toFixed(3)
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE && xhr.status === 200) {
                try {
                    var d = JSON.parse(xhr.responseText)
                    if (d && d.states) root.states = d.states
                } catch (e) {}
            }
        }
        xhr.open("GET", url)
        xhr.setRequestHeader("User-Agent", "fw-radar/3.0")
        xhr.send()
    }

    Timer {
        interval: 6000; repeat: true; running: true
        onTriggered: root.fetchData()
    }

    Timer {
        interval: 33; repeat: true; running: true
        onTriggered: { root.sweep = (root.sweep + 0.8) % 360; canvas.requestPaint() }
    }

    Canvas {
        id: canvas
        anchors.fill: parent

        onPaint: {
            var ctx = getContext("2d")
            var w = width, h = height
            var cx = w / 2, cy = h / 2
            var scale = (Math.min(w, h) * 0.47) / root.radiusKm
            var ring = root.radiusKm * scale
            var sweepRad = (root.sweep - 90) * Math.PI / 180

            function px(lon, lat) { return cx + (lon - root.centerLon) * root.kmPerDegLon * scale }
            function py(lat) { return cy - (lat - root.centerLat) * root.kmPerDegLat * scale }

            ctx.clearRect(0, 0, w, h)

            // ---- map: land
            var land = Map.mapData.land || []
            ctx.fillStyle = "#0c1f13"
            for (var i = 0; i < land.length; i++) {
                var pts = land[i]
                ctx.beginPath()
                for (var j = 0; j < pts.length; j++) {
                    var x = px(pts[j][0], pts[j][1]), y = py(pts[j][1])
                    if (j === 0) ctx.moveTo(x, y); else ctx.lineTo(x, y)
                }
                ctx.closePath()
                ctx.fill()
            }

            // ---- map: borders
            var borders = Map.mapData.borders || []
            ctx.strokeStyle = "#24402c"
            ctx.lineWidth = 1.2
            for (var bi = 0; bi < borders.length; bi++) {
                var bp = borders[bi].pts
                ctx.beginPath()
                for (var bj = 0; bj < bp.length; bj++) {
                    var bx = px(bp[bj][0], bp[bj][1]), by = py(bp[bj][1])
                    if (bj === 0) ctx.moveTo(bx, by); else ctx.lineTo(bx, by)
                }
                ctx.stroke()
            }

            // ---- range rings
            ctx.strokeStyle = "#1d4a2e"
            ctx.lineWidth = 1
            for (var rk = 1; rk <= 4; rk++) {
                ctx.beginPath()
                ctx.arc(cx, cy, ring * rk / 4, 0, 2 * Math.PI)
                ctx.stroke()
            }
            ctx.beginPath(); ctx.moveTo(cx - ring, cy); ctx.lineTo(cx + ring, cy); ctx.stroke()
            ctx.beginPath(); ctx.moveTo(cx, cy - ring); ctx.lineTo(cx, cy + ring); ctx.stroke()

            ctx.fillStyle = "#4c7a58"
            ctx.font = "12px " + root.fontFam
            ctx.fillText("200", cx + ring + 8, cy + 4)
            ctx.fillText("100", cx + ring / 2 + 4, cy - 6)

            // ---- sweep halo (smooth gradient)
            var haloSteps = 100
            for (var k = haloSteps - 1; k >= 0; k--) {
                var a1 = sweepRad - (k + 1) * Math.PI / 180
                var a2 = sweepRad - k * Math.PI / 180
                var lvl = 1 - Math.pow(k / haloSteps, 1.5)
                var alpha = 0.04 + 0.22 * lvl
                ctx.fillStyle = "rgba(35," + Math.round(80 + 170 * lvl) + ",70," + alpha.toFixed(3) + ")"
                ctx.beginPath()
                ctx.moveTo(cx, cy)
                ctx.lineTo(cx + Math.cos(a1) * ring, cy + Math.sin(a1) * ring)
                ctx.arc(cx, cy, ring, a1, a2, false)
                ctx.closePath()
                ctx.fill()
            }

            // sweep line
            ctx.strokeStyle = "#3dff7e"
            ctx.lineWidth = 2
            ctx.beginPath()
            ctx.moveTo(cx, cy)
            ctx.lineTo(cx + Math.cos(sweepRad) * ring, cy + Math.sin(sweepRad) * ring)
            ctx.stroke()

            // ---- home marker
            ctx.fillStyle = "#f5d95c"
            ctx.beginPath(); ctx.arc(cx, cy, 5, 0, 2 * Math.PI); ctx.fill()
            ctx.font = "12px " + root.fontFam
            ctx.fillText("HOME", cx + 9, cy + 9)

            // ---- airports
            ctx.font = "10px " + root.fontFam
            ctx.fillStyle = "#7d95a8"
            for (var ai = 0; ai < root.airports.length; ai++) {
                var ap = root.airports[ai]
                var ax = px(ap[2], ap[1]), ay = py(ap[1])
                var adx = ax - cx, ady = ay - cy
                if (Math.sqrt(adx * adx + ady * ady) > ring) continue
                ctx.fillStyle = "#7d95a8"
                ctx.beginPath(); ctx.arc(ax, ay, 2, 0, 2 * Math.PI); ctx.fill()
                ctx.fillText(ap[0], ax + 5, ay + 3)
            }

            // ---- blips (ATC-style data blocks, decluttered)
            var blips = []
            for (var si = 0; si < root.states.length; si++) {
                var s = root.states[si]
                var lon = parseFloat(s[5]), lat = parseFloat(s[6])
                if (isNaN(lon) || isNaN(lat) || lon === null || lat === null) continue
                var bx2 = px(lon, lat), by2 = py(lat)
                var bdx = bx2 - cx, bdy = by2 - cy
                if (Math.sqrt(bdx * bdx + bdy * bdy) > ring) continue
                var callsign = (s[1] || "").trim() || "?"
                var altM = parseFloat(s[7]) || 0
                var track = parseFloat(s[10]) || 0
                var vel = parseFloat(s[9]) || 0
                blips.push([altM, bx2, by2, bdx, bdy, callsign, altM * 3.28084, track, vel])
            }
            blips.sort(function (p, q) { return p[0] - q[0] })

            ctx.font = "11px " + root.fontFam
            var placed = []
            for (var bi2 = 0; bi2 < blips.length; bi2++) {
                var bl = blips[bi2]
                var bX = bl[1], bY = bl[2], bDx = bl[3], bDy = bl[4]
                var call = bl[5], altFt = bl[6], trk = bl[7], vel = bl[8]
                var blipAng = Math.atan2(bDx, -bDy) * 180 / Math.PI
                if (blipAng < 0) blipAng += 360
                var diff = (root.sweep - blipAng) % 360
                if (diff < 0) diff += 360
                var lvl = Math.max(0, 1 - diff / 75)
                lvl = lvl * lvl
                var altFactor = altFt <= 10000 ? 1.0 : Math.max(0.2, 1.0 - (altFt - 10000) / 25000)
                var vis = lvl * altFactor

                // aircraft position symbol
                var g = Math.round(70 + 185 * vis)
                ctx.fillStyle = "rgb(25," + g + ",65)"
                ctx.beginPath(); ctx.arc(bX, bY, 4, 0, 2 * Math.PI); ctx.fill()

                // heading tick
                var tr = trk * Math.PI / 180
                ctx.strokeStyle = "rgb(25," + g + ",65)"
                ctx.lineWidth = 2
                ctx.beginPath()
                ctx.moveTo(bX, bY)
                ctx.lineTo(bX + Math.sin(tr) * 13, bY - Math.cos(tr) * 13)
                ctx.stroke()

                // data block lines: callsign / altitude / speed
                var lines = []
                lines.push(call.substring(0, 8))
                lines.push(root.fmtAlt(altFt))
                if (vel > 0) lines.push(Math.round(vel * 1.94384) + "kt")

                var maxW = 0
                for (var li = 0; li < lines.length; li++) {
                    var tw = ctx.measureText(lines[li]).width
                    if (tw > maxW) maxW = tw
                }
                var lineH = 14, padX = 5, padY = 3
                var blockW = maxW + padX * 2
                var blockH = lines.length * lineH + padY * 2

                var dbX = bX + 10, dbY = bY - blockH - 8

                // rectangle collision vs placed blocks
                var collide = false
                for (var pi = 0; pi < placed.length; pi++) {
                    var pr = placed[pi]
                    if (dbX < pr[0] + pr[2] && dbX + blockW > pr[0] && dbY < pr[1] + pr[3] && dbY + blockH > pr[1]) { collide = true; break }
                }
                if (collide) continue

                // leader line
                ctx.strokeStyle = "rgba(" + Math.round(80 + 120 * vis) + "," + Math.round(150 + 80 * vis) + ",100,0.5)"
                ctx.lineWidth = 1
                ctx.beginPath()
                ctx.moveTo(bX, bY)
                ctx.lineTo(dbX, dbY + blockH)
                ctx.stroke()

                // block background + border
                ctx.fillStyle = "rgba(0,10,6,0.72)"
                ctx.fillRect(dbX, dbY, blockW, blockH)
                ctx.strokeStyle = "rgba(" + Math.round(60 + 100 * vis) + "," + Math.round(140 + 90 * vis) + ",90,0.5)"
                ctx.lineWidth = 1
                ctx.strokeRect(dbX, dbY, blockW, blockH)

                // text lines
                for (var li2 = 0; li2 < lines.length; li2++) {
                    ctx.fillStyle = "rgb(" + Math.round(100 + 155 * vis) + "," + Math.round(170 + 85 * vis) + ",120)"
                    ctx.fillText(lines[li2], dbX + padX, dbY + padY + lineH * (li2 + 1) - 3)
                }
                placed.push([dbX, dbY, blockW, blockH])
            }
        }
    }

    Item {
        id: inputCatcher
        anchors.fill: parent
        focus: true

        Keys.onPressed: Qt.quit()
        Keys.onReleased: Qt.quit()

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.AllButtons
            onClicked: Qt.quit()
            onWheel: Qt.quit()
            onPositionChanged: { if (root.ready) Qt.quit() }
        }
    }
}
