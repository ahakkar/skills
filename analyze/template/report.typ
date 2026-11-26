// Analysis report template. Copied into the run directory as report.typ; agents never edit it.
// Tables come from data/*.yaml, narrative from prose/*.md (rendered with cmarker).
// Every file named here must exist: an empty list `[]` or an empty .md is fine.
// Build from the run directory:  typst compile report.typ REPORT.pdf
//
// data/meta.yaml:
//   title, question, target, commit, date, agents, lang (optional, default "en")
//   lanes: [{key: a, name: "Architecture"}, {key: b, name: "Tests"}]
//   -> loads data/findings-<key>.yaml and prose/<key>.md for each lane
// Also read: data/claim-check.yaml, prose/summary.md, prose/method.md

#import "@preview/cmarker:0.1.10"

// ---------- data ----------

#let load-list(path) = { let d = yaml(path); if d == none { () } else { d } }

#let meta = yaml("data/meta.yaml")
#let lanes = meta.lanes
#let findings = lanes.map(l => load-list("data/findings-" + l.key + ".yaml")).flatten()
#let checks = load-list("data/claim-check.yaml")
#let severity-rank = (high: 0, medium: 1, low: 2)
#let by-severity = findings.sorted(key: f => severity-rank.at(str(f.severity), default: 3))

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
  verified: rgb("#2e4053"), suspected: rgb("#7f8c8d"),
  holds: rgb("#1e8449"), weakened: rgb("#b9770e"), wrong: rgb("#b03a2e"),
  unverifiable: rgb("#7f8c8d"),
)
#let badge(s) = pill(str(s), colors.at(str(s), default: gray))

#let loc(l) = {
  if l == none { [—] }
  else if type(l) == array { l.map(x => raw(str(x))).join(linebreak()) }
  else { raw(str(l)) }
}

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

== Findings by severity

All findings, most severe first. IDs link to the full entry with its evidence.

#if findings.len() == 0 { none-recorded } else {
  grid-table(
    columns: (auto, 1fr, auto, auto),
    header: ([ID], [Finding], [Severity], [Check]),
    rows: by-severity.map(f => {
      let c = check-of(f.id)
      (
        link(label(f.id), raw(f.id)),
        md(f.finding),
        badge(f.severity),
        if c == none [—] else { badge(c.verdict) },
      )
    }).flatten(),
  )
}

// ---------- 2. findings by lane ----------

= Findings

#for l in lanes {
  let fs = findings.filter(f => upper(f.id).starts-with(upper(l.key) + "-"))
  [== #l.name]
  md-file("prose/" + l.key + ".md", h1-level: 3)
  if fs.len() == 0 { none-recorded }
  for f in fs [
    #let c = check-of(f.id)
    #let cl = f.at("claim", default: none)
    #block(breakable: true, width: 100%, inset: (left: 8pt, y: 4pt),
      stroke: (left: 2.5pt + colors.at(str(f.severity), default: gray)))[
      #set par(justify: false)
      #text(weight: "bold")[#raw(f.id) #h(4pt)] #md(f.finding) #label(f.id)
      #badge(f.severity) #h(3pt) #badge(f.confidence)
      #if c != none [#h(3pt) #badge(c.verdict)]
      \ #loc(f.at("location", default: none))

      #if f.at("quote", default: none) != none [*Quote.* #raw(str(f.quote))]

      #if cl != none [
        *Claim in the target.* #badge(cl.at("status", default: "unverifiable"))
        #raw(str(cl.at("quote", default: ""))) \ #loc(cl.at("location", default: none))
      ]

      #if c != none and c.at("note", default: none) != none [*Claim check.* #md(c.note)]
    ]
    #v(6pt)
  ]
}

// ---------- 3. method and limits ----------

= Method and limits

#md-file("prose/method.md", h1-level: 2)
