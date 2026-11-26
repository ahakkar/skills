// Review report template, for lens/review.md. Copied into the run directory as report.typ;
// agents never edit it. Tables come from data/*.yaml, narrative from prose/*.md (rendered
// with cmarker). Every file named here must exist: an empty list `[]` or an empty .md is fine.
// Build from the run directory:  typst compile report.typ REPORT.pdf
//
// data/meta.yaml:
//   title, question, target, commit, date, agents, lang (optional, default "en")
//   lanes: [{key: a, name: "Architecture and code quality"}, {key: b, name: "..."}]
//   -> loads data/findings-<key>.yaml and prose/<key>.md for each lane
//   areas: [{key: architecture, name: "Architecture"}, ...]  every finding's area, in report order
// Also read: data/claim-check.yaml, data/scores.yaml, data/actions.yaml, data/tooling.yaml,
//   prose/summary.md, prose/method.md
// The build stops on bad data: a duplicate finding ID, an ID that no finding has (prose
// included), or a value outside its list in `allowed` below.

#import "@preview/cmarker:0.1.10"

// ---------- data ----------

#let load-list(path) = { let d = yaml(path); if d == none { () } else { d } }

#let meta = yaml("data/meta.yaml")
#let lanes = meta.lanes
#let areas = meta.areas
#let findings = lanes.map(l => load-list("data/findings-" + l.key + ".yaml")).flatten()
#let checks = load-list("data/claim-check.yaml")
#let scores = load-list("data/scores.yaml")
#let actions = load-list("data/actions.yaml")
#let tooling = load-list("data/tooling.yaml")
#let prose-files = lanes.map(l => "prose/" + l.key + ".md") + ("prose/summary.md", "prose/method.md")

#let claim-of(f) = f.at("claim", default: none)
#let claim-status(f) = str(claim-of(f).at("status", default: "unverifiable"))
#let is-strength(f) = f.at("kind", default: "issue") == "strength"
// A claim that holds is listed only in the documentation claims table.
#let confirmed(f) = claim-of(f) != none and claim-status(f) == "holds"
#let severity-rank = (high: 0, medium: 1, low: 2)
#let by-severity(fs) = fs.sorted(key: f => (severity-rank.at(str(f.severity), default: 3), str(f.id)))
#let listed = by-severity(findings.filter(f => not confirmed(f)))
#let issues = listed.filter(f => not is-strength(f))
#let strengths = listed.filter(is-strength)
#let claimed = findings.filter(f => claim-of(f) != none).sorted(key: f => str(f.id))
#let check-of(id) = checks.find(c => c.id == id)

// ---------- data checks: a failed build means bad data ----------

#let fail-if(bad, msg) = if bad.len() > 0 { panic(msg + ": " + bad.join("; ")) }
#let ids = findings.map(f => str(f.id))
#fail-if(ids.filter(i => ids.filter(j => j == i).len() > 1).dedup(), "Duplicate finding IDs")

#let allowed = (
  severity: ("high", "medium", "low"),
  confidence: ("verified", "suspected"),
  kind: ("issue", "strength"),
  area: areas.map(a => str(a.key)),
  claim: ("holds", "weakened", "wrong", "unverifiable"),
  verdict: ("holds", "weakened", "wrong"),
  score: ("1", "2", "3", "4", "5"),
  effort: ("S", "M", "L"),
  result: ("pass", "fail", "warn", "skipped"),
)
// (where, field, value) for every value with a fixed list
#let values = (
  findings.map(f => (
    (f.id, "severity", f.at("severity", default: none)),
    (f.id, "confidence", f.at("confidence", default: none)),
    (f.id, "kind", f.at("kind", default: "issue")),
    (f.id, "area", f.at("area", default: none)),
    ..if claim-of(f) != none { ((f.id, "claim", claim-of(f).at("status", default: none)),) },
  )).sum(default: ())
  + checks.map(c => ("claim-check " + str(c.id), "verdict", c.at("verdict", default: none)))
  + scores.map(s => (("scores " + str(s.area), "area", s.area), ("scores " + str(s.area), "score", s.at("score", default: none)))).sum(default: ())
  + actions.map(a => ("action " + str(a.at("rank", default: "?")), "effort", a.at("effort", default: none)))
  + tooling.map(t => ("tooling " + str(t.at("check", default: "?")), "result", t.at("result", default: none)))
)
#fail-if(values.filter(((w, k, v)) => v == none or str(v) not in allowed.at(k))
  .map(((w, k, v)) => str(w) + " " + k + " = " + repr(v)), "Missing or unknown value")

#let id-pattern = regex("\\b(?:" + lanes.map(l => upper(str(l.key))).join("|") + ")-\\d+\\b")
#let id-refs = prose-files.map(p => (p, read(p).matches(id-pattern).map(m => m.text))) + (
  ("data/scores.yaml", scores.map(s => s.at("findings", default: ())).sum(default: ())),
  ("data/actions.yaml", actions.map(a => a.at("findings", default: ())).sum(default: ())),
  ("data/claim-check.yaml", checks.map(c => c.id)),
)
#fail-if(id-refs.map(((file, used)) => {
  let bad = used.map(str).filter(i => i not in ids).dedup()
  if bad.len() > 0 { file + " " + bad.join(", ") }
}).filter(x => x != none), "Finding IDs that no finding has; rename or remove them")

// ---------- helpers ----------

#let md(s, h1-level: 4) = {
  if s == none or str(s).trim() == "" { [] } else {
    cmarker.render(str(s), set-document-title: false, h1-level: h1-level)
  }
}
#let md-file(path, h1-level: 2) = md(read(path), h1-level: h1-level)
#let none-recorded = text(fill: gray)[_None recorded._]

#let pill(label, fill) = box(
  fill: fill, inset: (x: 4pt, y: 2pt), outset: (y: 1pt), radius: 2pt,
  text(fill: white, size: 12pt, weight: "bold", label),
)
#let colors = (
  high: rgb("#b03a2e"), medium: rgb("#b9770e"), low: rgb("#5d6d7e"),
  verified: rgb("#2e4053"), suspected: rgb("#7f8c8d"), strength: rgb("#1e8449"),
  holds: rgb("#1e8449"), weakened: rgb("#b9770e"), wrong: rgb("#b03a2e"),
  unverifiable: rgb("#7f8c8d"),
  pass: rgb("#1e8449"), fail: rgb("#b03a2e"), warn: rgb("#b9770e"), skipped: rgb("#7f8c8d"),
)
#let badge(s) = pill(str(s), colors.at(str(s), default: gray))
// A strength's severity is its weight, not a risk: grey, not red.
#let severity-badge(f) = if is-strength(f) { pill(str(f.severity), colors.suspected) } else { badge(f.severity) }
#let check-badge(id) = { let c = check-of(id); if c == none [—] else { badge(c.verdict) } }

#let loc(l) = {
  if l == none { [—] }
  else if type(l) == array { l.map(x => raw(str(x))).join(linebreak()) }
  else { raw(str(l)) }
}
#let id-link(id) = link(label(str(id)), raw(str(id)))
#let id-links(ids) = if ids.len() == 0 [—] else { ids.map(id-link).join([, ]) }
#let area-name(key) = { let a = areas.find(a => a.key == key); if a == none { key } else { a.name } }

#let score-bar(n) = {
  let n = int(n)
  box(baseline: 1pt, stack(dir: ltr, spacing: 1.5pt,
    ..range(5).map(i => box(width: 8pt, height: 8pt, radius: 1pt,
      fill: if i < n { rgb("#2e4053") } else { rgb("#d5d8dc") }))))
  h(5pt)
  [#n/5]
}

#let grid-table(columns: (), header: (), rows: ()) = table(
  columns: columns,
  stroke: (x, y) => if y == 0 { (bottom: 0.7pt) } else { (bottom: 0.3pt + luma(220)) },
  inset: (x: 5pt, y: 5pt),
  align: left + horizon,
  table.header(..header.map(h => text(weight: "bold", h))),
  ..rows,
)

#let entry(f) = {
  let c = check-of(f.id)
  let cl = claim-of(f)
  let edge = if is-strength(f) { colors.strength } else { colors.at(str(f.severity), default: gray) }
  block(breakable: true, width: 100%, inset: (left: 8pt, y: 4pt), stroke: (left: 2.5pt + edge))[
    #set par(justify: false)
    #text(weight: "bold")[#raw(f.id) #h(4pt)] #md(f.finding) #label(f.id)
    #if is-strength(f) [#badge("strength") #h(3pt)]
    #severity-badge(f) #h(3pt) #badge(f.confidence)
    #if c != none [#h(3pt) #badge(c.verdict)]
    \ #loc(f.at("location", default: none))

    #if f.at("quote", default: none) != none [*Quote.* #raw(str(f.quote))]

    #if cl != none [
      *Claim in the target.* #badge(claim-status(f))
      #quote(str(cl.at("quote", default: ""))) \ #loc(cl.at("location", default: none))
    ]

    #if c != none and c.at("note", default: none) != none [*Claim check.* #md(c.note)]
  ]
  v(6pt)
}

// ---------- document setup ----------

#set document(title: meta.title)
#set page(
  paper: "a4",
  margin: (x: 2cm, y: 2.2cm),
  numbering: "1",
  header: context if counter(page).get().first() > 1 {
    set text(size: 12pt, fill: gray)
    meta.title
    h(1fr)
    meta.target
  },
)
#set text(size: 12pt, lang: meta.at("lang", default: "en"))
#set par(justify: true, leading: 0.62em)
#set heading(numbering: "1.1")
#show heading.where(level: 1): it => { pagebreak(weak: true); it; v(0.4em) }
#show table: set text(size: 12pt)
#show table: set par(justify: false)
// Typst shrinks raw text to 0.8em by default; keep code at the body size.
#show raw: set text(size: 12pt)
#show link: set text(fill: rgb("#1f618d"))

// ---------- title page ----------

#align(center + horizon)[
  #text(size: 24pt, weight: "bold", meta.title)
  #v(0.8em)
  #block(width: 85%)[
    #set par(justify: false)
    #text(size: 14pt, style: "italic", str(meta.question))
  ]
  #v(1.5em)
  #grid(columns: 2, column-gutter: 1em, row-gutter: 0.6em, align: (right, left),
    [*Target*], raw(str(meta.target)),
    [*Commit*], raw(str(meta.commit)),
    [*Date*], str(meta.date),
    [*Agents*], str(meta.agents),
  )
]

#pagebreak()
#outline(depth: 2)

// ---------- 1. summary ----------

= Summary

#md-file("prose/summary.md", h1-level: 2)

== Scores by area

5 exemplary, 4 solid with minor issues, 3 acceptable with clear gaps, 2 significant
problems, 1 broken or absent.

#if scores.len() == 0 { none-recorded } else {
  grid-table(
    columns: (auto, auto, 1fr, auto),
    header: ([Area], [Score], [Rationale], [Findings]),
    rows: areas.map(a => {
      let s = scores.find(s => s.area == a.key)
      if s == none { (a.name, [—], [—], [—]) } else {
        (a.name, score-bar(s.score), md(s.rationale), id-links(s.at("findings", default: ())))
      }
    }).flatten(),
  )
}

== Findings by area

Issues by severity, and strengths. Claims that hold are counted in @claims only.

#{
  let count(fs, key) = { let n = fs.filter(f => f.area == key).len(); if n == 0 [·] else [#n] }
  let sev(s) = issues.filter(f => f.severity == s)
  let keys = ("high", "medium", "low")
  if listed.len() == 0 { none-recorded } else {
    grid-table(
      columns: (1fr,) + (auto,) * 5,
      header: ([Area],) + keys.map(badge) + (badge("strength"), [Total]),
      rows: areas.map(a =>
        (a.name,) + keys.map(s => count(sev(s), a.key))
          + (count(strengths, a.key), strong(count(listed, a.key)))
      ).flatten() + (
        (strong[All],) + keys.map(s => strong[#sev(s).len()])
          + (strong[#strengths.len()], strong[#listed.len()])
      ),
    )
  }
}

== Recommended actions

Most valuable first. Effort is a relative judgement: S, M or L.

#if actions.len() == 0 { none-recorded } else {
  grid-table(
    columns: (auto, 1fr, auto, auto),
    header: ([\#], [Action], [Effort], [Findings]),
    rows: actions.sorted(key: a => a.rank).map(a => (
      [#a.rank], md(a.action), [#a.effort], id-links(a.at("findings", default: ())),
    )).flatten(),
  )
}

// ---------- 2. overview ----------

= Findings overview

IDs link to the full entry with its evidence. _Suspected_ findings are plausible but not
confirmed. Check is the claim check's verdict, where there is one.

== Issues

#if issues.len() == 0 { none-recorded } else {
  grid-table(
    columns: (auto, 1fr, auto, auto, auto),
    header: ([ID], [Finding], [Area], [Severity], [Check]),
    rows: issues.map(f => (
      id-link(f.id),
      [#md(f.finding)#if f.confidence == "suspected" [ #text(fill: gray)[_(suspected)_]]],
      area-name(f.area), badge(f.severity), check-badge(f.id),
    )).flatten(),
  )
}

== Strengths

#if strengths.len() == 0 { none-recorded } else {
  grid-table(
    columns: (auto, 1fr, auto, auto),
    header: ([ID], [Finding], [Area], [Check]),
    rows: strengths.map(f => (
      id-link(f.id), md(f.finding), area-name(f.area), check-badge(f.id),
    )).flatten(),
  )
}

// ---------- 3. lane notes ----------

= Lane notes

#for l in lanes [
  == #l.name
  #md-file("prose/" + l.key + ".md", h1-level: 3)
]

// ---------- 4. findings in full ----------

= Findings in full

#for a in areas {
  let fs = issues.filter(f => f.area == a.key) + strengths.filter(f => f.area == a.key)
  if fs.len() > 0 [
    == #a.name
    #for f in fs { entry(f) }
  ]
}
#if listed.len() == 0 { none-recorded }

// ---------- 5. checks ----------

= Checks

== Tooling results

#if tooling.len() == 0 { none-recorded } else {
  grid-table(
    columns: (auto, auto, auto, 1fr),
    header: ([Check], [Command], [Result], [Summary]),
    rows: tooling.map(t => (
      t.check, raw(str(t.command)), badge(t.result),
      [#md(t.summary)#if t.at("output", default: none) != none [#linebreak()Output: #raw(str(t.output))]],
    )).flatten(),
  )
}

== Documentation claims <claims>

#if claimed.len() == 0 { none-recorded } else [
  #claimed.len() claims checked: #{
    allowed.claim.map(s => (s, claimed.filter(f => claim-status(f) == s).len()))
      .filter(((s, n)) => n > 0).map(((s, n)) => [#s #n]).join([, ])
  }. A claim that holds has no entry of its own; the others link to theirs.

  #grid-table(
    columns: (auto, 1fr, auto, 1fr),
    header: ([ID], [Claim in the target], [Status], [What is true]),
    rows: claimed.map(f => {
      let cl = claim-of(f)
      (
        if confirmed(f) [#raw(f.id)#label(f.id)] else { id-link(f.id) },
        [#quote(str(cl.at("quote", default: ""))) \ #loc(cl.at("location", default: none))],
        badge(claim-status(f)),
        [#md(f.finding)#linebreak()#loc(f.at("location", default: none))],
      )
    }).flatten(),
  )
]

// ---------- 6. method and limits ----------

= Method and limits

#md-file("prose/method.md", h1-level: 2)
