// Pure helpers for the notification center. No Qt objects in here so the
// calendar math and the history grouping can be reasoned about on their own.

var MS_PER_DAY = 86400000

function pad2(v) { return (v < 10 ? "0" : "") + v }

function dateKey(y, m, d) { return y + "-" + pad2(m + 1) + "-" + pad2(d) }

function keyForDate(date) { return dateKey(date.getFullYear(), date.getMonth(), date.getDate()) }

// Sunday-start grid, the way the Windows calendar flyout lays it out for an
// en-US locale. Six rows so the panel never changes height month to month.
function monthGrid(year, month, todayKey) {
  var leading = new Date(year, month, 1).getDay()
  var cursor = new Date(year, month, 1 - leading)
  var weeks = []
  for (var w = 0; w < 6; w++) {
    var days = []
    for (var d = 0; d < 7; d++) {
      var key = dateKey(cursor.getFullYear(), cursor.getMonth(), cursor.getDate())
      days.push({
        key: key,
        day: cursor.getDate(),
        inMonth: cursor.getMonth() === month && cursor.getFullYear() === year,
        today: key === todayKey
      })
      cursor.setDate(cursor.getDate() + 1)
    }
    weeks.push(days)
  }
  return weeks
}

function stepMonth(year, month, delta) {
  var t = new Date(year, month + delta, 1)
  return { year: t.getFullYear(), month: t.getMonth() }
}

var MONTHS = ["January", "February", "March", "April", "May", "June", "July",
  "August", "September", "October", "November", "December"]
var WEEKDAYS = ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]

function monthTitle(year, month) { return MONTHS[month] + " " + year }

// Windows shows "Just now", "5m", "2h", "Yesterday", then a short date.
function timeAgo(timestamp, now) {
  var delta = Math.max(0, now - timestamp)
  if (delta < 60000) return "Just now"
  if (delta < 3600000) return Math.floor(delta / 60000) + "m"
  if (delta < MS_PER_DAY) return Math.floor(delta / 3600000) + "h"
  var then = new Date(timestamp)
  var today = new Date(now)
  var startOfToday = new Date(today.getFullYear(), today.getMonth(), today.getDate()).getTime()
  if (timestamp >= startOfToday - MS_PER_DAY) return "Yesterday"
  return MONTHS[then.getMonth()].slice(0, 3) + " " + then.getDate()
}

// One JSON object per line, as `awk 1 history/*.json` emits them. Bad lines
// are skipped rather than failing the whole read: one corrupt file must not
// blank the center.
function parseHistory(raw) {
  var rows = []
  var lines = String(raw || "").split("\n")
  for (var i = 0; i < lines.length; i++) {
    var line = lines[i].trim()
    if (!line) continue
    try {
      var e = JSON.parse(line)
      if (!e || typeof e !== "object") continue
      rows.push({
        id: e.id || 0,
        originalId: e.originalId || e.id || 0,
        app: e.app || "",
        appIcon: e.appIcon || "",
        summary: e.summary || "",
        body: e.body || "",
        image: e.image || "",
        glyph: e.glyph || "",
        execArgv: e.execArgv || "",
        urgency: typeof e.urgency === "number" ? e.urgency : 1,
        timestamp: e.timestamp || 0,
        // Same stem the notifications service uses for the file and its
        // image copies, so "dismiss" can remove both.
        fileStem: String(e.timestamp || 0) + "-" + String(e.originalId || e.id || 0)
      })
    } catch (err) {}
  }
  rows.sort(function(a, b) { return (b.timestamp || 0) - (a.timestamp || 0) })
  return rows
}

// Group consecutive rows by app, newest group first, the way the Windows
// center stacks a sender's notifications under one header.
function groupByApp(rows) {
  var groups = []
  var index = {}
  for (var i = 0; i < rows.length; i++) {
    var r = rows[i]
    var key = (r.app || "").toLowerCase()
    if (index[key] === undefined) {
      index[key] = groups.length
      groups.push({ app: r.app, appIcon: r.appIcon, items: [] })
    }
    groups[index[key]].items.push(r)
  }
  return groups
}

// Windows renders notification bodies as plain text. Senders (Chrome above
// all) pad theirs with <a>, <b>, <img> markup, so strip every tag and undo
// the entities the markup escaped, then collapse the whitespace it leaves.
function plainBody(text) {
  return String(text || "")
    .replace(/<br\s*\/?>/gi, " ")
    .replace(/<[^>]+>/g, "")
    .replace(/&lt;/g, "<").replace(/&gt;/g, ">").replace(/&quot;/g, '"')
    .replace(/&#39;/g, "'").replace(/&apos;/g, "'").replace(/&nbsp;/g, " ")
    .replace(/&amp;/g, "&")
    .replace(/\s+/g, " ").trim()
}
