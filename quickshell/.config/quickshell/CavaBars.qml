import QtQuick

Item {
  id: root

  property var state: CavaState
  property bool mirrored: false
  property string channel: "left"
  property int columnWidth: 2
  property int rowHeight: 1
  property int rowSpacing: 0
  property int maxHeight: 16
  property color accentColor: Theme.accent
  property var history: []

  readonly property var channelBars: channel === "right" ? state.rightBars : state.leftBars
  readonly property int bandCount: channelBars.length
  readonly property int maxColumns: Math.max(1, Math.floor(implicitWidth / columnWidth))

  visible: CavaStyleState.current === "scope"
      ? WaveformState.available
      : (state.enabled && state.available)
  implicitWidth: 60
  implicitHeight: bandCount > 0 ? Math.min(maxHeight, (bandCount * rowHeight) + ((bandCount - 1) * rowSpacing)) : 0

  function trimHistory() {
    if (history.length > maxColumns) {
      history = history.slice(history.length - maxColumns)
    }
  }

  function pushFrame(levels) {
    if (!levels || !levels.length) return

    const nextHistory = history.slice()
    nextHistory.push(levels.slice())
    history = nextHistory
    trimHistory()
    spectrogram.requestPaint()
  }

  function colorForLevel(level) {
    if (level >= 0.75) return accentColor
    if (level >= 0.4) return Theme.text
    return Theme.textDim
  }

  onMaxColumnsChanged: {
    trimHistory()
    spectrogram.requestPaint()
  }

  onVisibleChanged: {
    if (!visible) {
      history = []
      spectrogram.requestPaint()
    }
  }

  Connections {
    target: root.state

    function onLeftBarsChanged() {
      if (root.channel === "left" && root.visible) root.pushFrame(root.state.leftBars)
    }

    function onRightBarsChanged() {
      if (root.channel === "right" && root.visible) root.pushFrame(root.state.rightBars)
    }
  }

  Connections {
    target: CavaStyleState
    function onCurrentChanged() { spectrogram.requestPaint() }
  }

  Connections {
    target: WaveformState
    function onSamplesChanged() {
      if (CavaStyleState.current === "scope") spectrogram.requestPaint()
    }
  }

  Canvas {
    id: spectrogram
    anchors.fill: parent

    function paintSpectrogram(ctx) {
      for (let xIndex = 0; xIndex < root.history.length; xIndex++) {
        const frame = root.history[xIndex]
        const drawX = root.mirrored
          ? xIndex * root.columnWidth
          : width - ((xIndex + 1) * root.columnWidth)

        for (let band = 0; band < frame.length; band++) {
          const level = Math.max(0, Math.min(1, frame[band] || 0))
          const drawY = height - root.rowHeight - (band * (root.rowHeight + root.rowSpacing))

          ctx.globalAlpha = 0.2 + (level * 0.8)
          ctx.fillStyle = root.colorForLevel(level)
          ctx.fillRect(drawX, drawY, root.columnWidth, root.rowHeight)
        }
      }
    }

    function currentFrame() {
      return root.history.length > 0 ? root.history[root.history.length - 1] : []
    }

    function paintBars(ctx) {
      const frame = currentFrame()
      if (!frame.length) return
      const barW = Math.max(1, Math.floor(width / frame.length) - 1)
      for (let i = 0; i < frame.length; i++) {
        const level = Math.max(0, Math.min(1, frame[i] || 0))
        const h = level * height
        const x = root.mirrored ? (frame.length - 1 - i) * (barW + 1) : i * (barW + 1)
        ctx.fillStyle = root.colorForLevel(level)
        ctx.fillRect(x, height - h, barW, h)
      }
    }

    function paintMirror(ctx) {
      const frame = currentFrame()
      if (!frame.length) return
      const barW = Math.max(1, Math.floor(width / frame.length) - 1)
      const mid = height / 2
      for (let i = 0; i < frame.length; i++) {
        const level = Math.max(0, Math.min(1, frame[i] || 0))
        const h = (level * height) / 2
        const x = root.mirrored ? (frame.length - 1 - i) * (barW + 1) : i * (barW + 1)
        ctx.fillStyle = root.colorForLevel(level)
        ctx.fillRect(x, mid - h, barW, h * 2)
      }
    }

    function paintDots(ctx) {
      const frame = currentFrame()
      if (!frame.length) return
      const slot = width / frame.length
      const r = Math.max(1, Math.floor(slot / 2) - 1)
      for (let i = 0; i < frame.length; i++) {
        const level = Math.max(0, Math.min(1, frame[i] || 0))
        const cx = (root.mirrored ? (frame.length - 1 - i) : i) * slot + slot / 2
        const cy = height - (level * height)
        ctx.fillStyle = root.colorForLevel(level)
        ctx.beginPath()
        ctx.arc(cx, cy, r, 0, Math.PI * 2)
        ctx.fill()
      }
    }

    function paintWave(ctx) {
      const frame = currentFrame()
      if (frame.length < 2) return
      const step = width / (frame.length - 1)
      ctx.beginPath()
      for (let i = 0; i < frame.length; i++) {
        const level = Math.max(0, Math.min(1, frame[i] || 0))
        const idx = root.mirrored ? frame.length - 1 - i : i
        const x = idx * step
        const y = height - (level * height)
        if (i === 0) ctx.moveTo(x, y)
        else ctx.lineTo(x, y)
      }
      ctx.strokeStyle = root.accentColor
      ctx.lineWidth = 1.5
      ctx.stroke()
      // soft fill below
      ctx.lineTo(width, height)
      ctx.lineTo(0, height)
      ctx.closePath()
      ctx.fillStyle = Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.15)
      ctx.fill()
    }

    function paintCircles(ctx) {
      const frame = currentFrame()
      if (!frame.length) return
      const slot = width / frame.length
      const rMax = Math.min(slot / 2 - 0.5, height / 2 - 0.5)
      const cy = height / 2
      for (let i = 0; i < frame.length; i++) {
        const level = Math.max(0, Math.min(1, frame[i] || 0))
        const cx = (root.mirrored ? (frame.length - 1 - i) : i) * slot + slot / 2
        const r = Math.max(0.5, level * rMax)
        ctx.fillStyle = root.colorForLevel(level)
        ctx.globalAlpha = 0.35 + level * 0.65
        ctx.beginPath()
        ctx.arc(cx, cy, r, 0, Math.PI * 2)
        ctx.fill()

        ctx.globalAlpha = 1
        ctx.strokeStyle = root.accentColor
        ctx.lineWidth = 0.5
        ctx.beginPath()
        ctx.arc(cx, cy, rMax, 0, Math.PI * 2)
        ctx.stroke()
      }
      ctx.globalAlpha = 1
    }

    function paintSpikes(ctx) {
      const frame = currentFrame()
      if (!frame.length) return
      const slot = width / frame.length
      for (let i = 0; i < frame.length; i++) {
        const level = Math.max(0, Math.min(1, frame[i] || 0))
        const cx = (root.mirrored ? (frame.length - 1 - i) : i) * slot + slot / 2
        const h = level * height
        ctx.strokeStyle = root.colorForLevel(level)
        ctx.lineWidth = 1
        ctx.beginPath()
        ctx.moveTo(cx, height)
        ctx.lineTo(cx, height - h)
        ctx.stroke()
        ctx.fillStyle = root.colorForLevel(level)
        ctx.beginPath()
        ctx.arc(cx, height - h, 1.5, 0, Math.PI * 2)
        ctx.fill()
      }
    }

    function paintStairs(ctx) {
      const frame = currentFrame()
      if (frame.length < 2) return
      const step = width / frame.length
      ctx.beginPath()
      ctx.moveTo(0, height)
      for (let i = 0; i < frame.length; i++) {
        const level = Math.max(0, Math.min(1, frame[i] || 0))
        const idx = root.mirrored ? frame.length - 1 - i : i
        const x = idx * step
        const y = height - level * height
        ctx.lineTo(x, y)
        ctx.lineTo(x + step, y)
      }
      ctx.lineTo(width, height)
      ctx.closePath()
      ctx.fillStyle = Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.35)
      ctx.fill()
      ctx.strokeStyle = root.accentColor
      ctx.lineWidth = 1
      ctx.stroke()
    }

    function paintTriangle(ctx) {
      const frame = currentFrame()
      if (!frame.length) return
      const slot = width / frame.length
      for (let i = 0; i < frame.length; i++) {
        const level = Math.max(0, Math.min(1, frame[i] || 0))
        const cx = (root.mirrored ? (frame.length - 1 - i) : i) * slot + slot / 2
        const h = level * height
        ctx.fillStyle = root.colorForLevel(level)
        ctx.beginPath()
        ctx.moveTo(cx - slot / 2, height)
        ctx.lineTo(cx + slot / 2, height)
        ctx.lineTo(cx, height - h)
        ctx.closePath()
        ctx.fill()
      }
    }

    function paintGlow(ctx) {
      const frame = currentFrame()
      if (!frame.length) return
      const slot = width / frame.length
      for (let i = 0; i < frame.length; i++) {
        const level = Math.max(0, Math.min(1, frame[i] || 0))
        const cx = (root.mirrored ? (frame.length - 1 - i) : i) * slot + slot / 2
        const cy = height / 2
        for (let pass = 3; pass >= 1; pass--) {
          ctx.globalAlpha = (level * 0.35) / pass
          ctx.fillStyle = root.accentColor
          ctx.beginPath()
          ctx.arc(cx, cy, level * height * pass * 0.8, 0, Math.PI * 2)
          ctx.fill()
        }
      }
      ctx.globalAlpha = 1
    }

    function paintRibbon(ctx) {
      const frame = currentFrame()
      if (frame.length < 2) return
      const step = width / (frame.length - 1)
      const mid = height / 2
      ctx.beginPath()
      for (let i = 0; i < frame.length; i++) {
        const level = Math.max(0, Math.min(1, frame[i] || 0))
        const idx = root.mirrored ? frame.length - 1 - i : i
        const x = idx * step
        const y = mid - (level * mid)
        if (i === 0) ctx.moveTo(x, y)
        else ctx.lineTo(x, y)
      }
      for (let j = frame.length - 1; j >= 0; j--) {
        const level = Math.max(0, Math.min(1, frame[j] || 0))
        const idx = root.mirrored ? frame.length - 1 - j : j
        const x = idx * step
        const y = mid + (level * mid)
        ctx.lineTo(x, y)
      }
      ctx.closePath()
      ctx.fillStyle = Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.45)
      ctx.fill()
      ctx.strokeStyle = root.accentColor
      ctx.lineWidth = 1
      ctx.stroke()
    }

    property var peakHold: ({})

    function paintEqualizer(ctx) {
      const frame = currentFrame()
      if (!frame.length) return
      const barW = Math.max(1, Math.floor(width / frame.length) - 1)
      for (let i = 0; i < frame.length; i++) {
        const level = Math.max(0, Math.min(1, frame[i] || 0))
        const h = level * height
        const x = root.mirrored ? (frame.length - 1 - i) * (barW + 1) : i * (barW + 1)
        ctx.fillStyle = root.colorForLevel(level)
        ctx.fillRect(x, height - h, barW, h)

        const prev = (peakHold[i] || 0) - 0.02
        const peak = Math.max(level, prev, 0)
        peakHold[i] = peak
        const peakY = height - peak * height
        ctx.fillStyle = root.accentColor
        ctx.fillRect(x, peakY - 1, barW, 1)
      }
    }

    function paintScope(ctx) {
      const samples = WaveformState.samples
      if (!samples || samples.length < 2) return
      const mid = height / 2

      // visible window — fit into width
      const visible = Math.min(samples.length, Math.max(2, Math.floor(width)))
      const step = width / (visible - 1)
      const start = samples.length - visible

      // peak envelope (filled)
      ctx.beginPath()
      for (let i = 0; i < visible; i++) {
        const s = samples[start + i]
        const idx = root.mirrored ? (visible - 1 - i) : i
        const x = idx * step
        ctx.lineTo(x, mid - s.peak * mid)
      }
      for (let j = visible - 1; j >= 0; j--) {
        const s = samples[start + j]
        const idx = root.mirrored ? (visible - 1 - j) : j
        const x = idx * step
        ctx.lineTo(x, mid + s.peak * mid)
      }
      ctx.closePath()
      ctx.fillStyle = Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.25)
      ctx.fill()

      // signed mean (centerline)
      ctx.beginPath()
      for (let k = 0; k < visible; k++) {
        const s = samples[start + k]
        const idx = root.mirrored ? (visible - 1 - k) : k
        const x = idx * step
        const y = mid - s.avg * mid
        if (k === 0) ctx.moveTo(x, y)
        else ctx.lineTo(x, y)
      }
      ctx.strokeStyle = root.accentColor
      ctx.lineWidth = 1
      ctx.stroke()
    }

    onPaint: {
      const ctx = getContext("2d")
      ctx.reset()
      switch (CavaStyleState.current) {
        case "bars":       paintBars(ctx); break
        case "wave":       paintWave(ctx); break
        case "dots":       paintDots(ctx); break
        case "mirror":     paintMirror(ctx); break
        case "circles":    paintCircles(ctx); break
        case "spikes":     paintSpikes(ctx); break
        case "stairs":     paintStairs(ctx); break
        case "triangle":   paintTriangle(ctx); break
        case "glow":       paintGlow(ctx); break
        case "ribbon":     paintRibbon(ctx); break
        case "equalizer":  paintEqualizer(ctx); break
        case "scope":      paintScope(ctx); break
        default:           paintSpectrogram(ctx); break
      }
      ctx.globalAlpha = 1.0
    }
  }

  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    onClicked: function(e) {
      if (e.button === Qt.RightButton) CavaStyleState.prev()
      else CavaStyleState.next()
    }
  }
}
