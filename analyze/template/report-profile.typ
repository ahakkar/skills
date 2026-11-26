// Profile report template. Copied into the run directory; agents never edit it.
// All content comes from data/*.yaml (tables) and prose/*.md (narrative, cmarker).
// Every file named here must exist: an empty list `[]` or an empty .md is fine.
// Build from the run directory:  typst compile report.typ REPORT.pdf
//
// data/meta.yaml:
//   title, target, commit, date, agents, scope
//   lanes: [{key: a, name: "Architecture"}, {key: b, name: "Features and claims"},
//           {key: x, name: "History and measurements"}]
//   -> loads data/facts-<key>.yaml and prose/<key>.md for each lane

#import "@preview/cmarker:0.1.10"

// ---------- data ----------

#let load-list(path) = { let d = yaml(path); if d == none { () } else { d } }

#let meta = yaml("data/meta.yaml")
#let lanes = meta.lanes
#let facts = lanes.map(l => load-list("data/facts-" + l.key + ".yaml")).flatten()
#let selected = load-list("data/selected.yaml").sorted(key: s => s.rank)
#let claims = load-list("data/claims.yaml")
#let checks = load-list("data/claim-check.yaml")

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
  code: rgb("#2e4053"), history: rgb("#5d6d7e"), measured: rgb("#1e8449"),
  estimate: rgb("#b9770e"),
  verified: rgb("#2e4053"), suspected: rgb("#7f8c8d"),
  holds: rgb("#1e8449"), weakened: rgb("#b9770e"), wrong: rgb("#b03a2e"),
  unmeasured: rgb("#7f8c8d"), unverifiable: rgb("#7f8c8d"),
)
#let badge(s) = pill(str(s), colors.at(str(s), default: gray))

#let loc(l) = {
  if l == none { [—] }
  else if type(l) == array { l.map(x => raw(str(x))).join(linebreak()) }
  else { raw(str(l)) }
}

#let fact-by-id(id) = facts.find(f => f.id == id)
#let check-of(id) = checks.find(c => c.id == id)

#let grid-table(columns: (), header: (), rows: ()) = table(
  columns: columns,
  stroke: (x, y) => if y == 0 { (bottom: 0.7pt) } else { (bottom: 0.3pt + luma(220)) },
  inset: (x: 5pt, y: 5pt),
  align: left + horizon,
  table.header(..header.map(h => text(weight: "bold", h))),
  ..rows,
)

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
  #v(0.6em)
  #text(size: 14pt, raw(str(meta.target)))
  #v(1.5em)
  #grid(columns: 2, column-gutter: 1em, row-gutter: 0.6em, align: (right, left),
    [*Commit*], raw(str(meta.commit)),
    [*Date*], str(meta.date),
    [*Agents*], str(meta.agents),
    [*Scope*], str(meta.scope),
  )
]

#pagebreak()
#outline(depth: 2)

// ---------- 1. summary and selected facts ----------

= Summary

#md-file("prose/summary.md", h1-level: 2)

== Selected facts

The facts chosen to carry the presentation. IDs link to the full entry with its evidence.

#if selected.len() == 0 { none-recorded } else {
  grid-table(
    columns: (auto, auto, 1fr, auto, auto),
    header: ([\#], [ID], [Fact], [Source], [Check]),
    rows: selected.map(s => {
      let f = fact-by-id(s.id)
      let c = check-of(s.id)
      (
        [#s.rank],
        link(label(s.id), raw(s.id)),
        if f == none { text(fill: red)[unknown ID] } else [#md(f.fact) #text(fill: gray, md(s.reason))],
        if f == none [—] else { badge(f.source) },
        if c == none [—] else { badge(c.verdict) },
      )
    }).flatten(),
  )
}

// ---------- 2. draft ----------

= Draft text

#md-file("prose/draft.md", h1-level: 2)

// ---------- 3. claims ----------

= Current text checked

Each claim in the existing presentation text, checked against the target.

#if claims.len() == 0 { none-recorded } else {
  grid-table(
    columns: (1fr, auto, 1fr),
    header: ([Claim], [Status], [Reality]),
    rows: claims.map(c => (
      [#md(c.claim) #raw(str(c.at("in", default: "")))],
      badge(c.status),
      [#md(c.reality) #loc(c.at("location", default: none))],
    )).flatten(),
  )
}

// ---------- 4. all facts by lane ----------

= All facts

#for l in lanes {
  let fs = facts.filter(f => upper(f.id).starts-with(upper(l.key) + "-"))
  [== #l.name]
  md-file("prose/" + l.key + ".md", h1-level: 3)
  if fs.len() == 0 { none-recorded }
  for f in fs [
    #block(breakable: true, width: 100%, inset: (left: 8pt, y: 4pt),
      stroke: (left: 2.5pt + colors.at(str(f.source), default: gray)))[
      #text(weight: "bold")[#raw(f.id) #h(4pt)] #md(f.fact) #label(f.id)
      #badge(f.source) #h(3pt) #badge(f.confidence)
      #{ let c = check-of(f.id); if c != none [#h(3pt) #badge(c.verdict)] }
      \ #loc(f.at("location", default: none))

      #if f.at("why", default: none) != none [*Why it matters.* #md(f.why)]

      #if f.at("quote", default: none) != none [*Quote.* #raw(str(f.quote))]
      #if f.at("basis", default: none) != none [*Estimate basis.* #md(f.basis)]
      #{ let c = check-of(f.id); if c != none and c.at("note", default: none) != none [*Claim check.* #md(c.note)] }
    ]
    #v(6pt)
  ]
}

// ---------- 5. method and limits ----------

= Method and limits

#md-file("prose/method.md", h1-level: 2)
