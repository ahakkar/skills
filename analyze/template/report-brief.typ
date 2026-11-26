// Brief report template, for lens/brief.md. Copied into the run directory as report.typ;
// agents never edit it. Tables come from data/*.yaml, narrative from prose/*.md (rendered
// with cmarker). Every file named here must exist: `[]` or an empty .md is fine.
// Build from the run directory:  typst compile report.typ REPORT.pdf
//
// data/meta.yaml:
//   title, question, target, commit, date, agents, lang (optional, default "en")
//   lanes: [{key: a, name: "..."}]  -> data/findings-<key>.yaml and prose/<key>.md each
//   chapters: [{key, title, tables: [table keys]}]  in report order -> prose/chapter-<key>.md
//   tables: [{key, title, columns: [{key, name, width, values}], sort, file}]
//     no `file`: one row per finding with `table: <key>`, values from its `cells`
//     `file`: one row per entry in that file, e.g. data/documents.yaml
//     width: `auto` or a weight (default 1). values: stored value -> text shown.
//     sort: the column that orders the rows (default: by ID, or file order)
//   labels: every fixed text the report shows, in the report's language. The keys are in
//     `label-keys` below and in lens/brief.md.
// Also read: data/claim-check.yaml, prose/summary.md, prose/method.md, each table's file.
// The build stops on bad data: a missing label, a duplicate finding ID, an ID that no
// finding has (prose included), a value outside its list in `allowed` below, a table
// placed in no chapter or in two, a cell with no column, or a conflict with no `claim`.

#import "@preview/cmarker:0.1.10"

// ---------- data ----------

#let load-list(path) = { let d = yaml(path); if d == none { () } else { d } }

#let meta = yaml("data/meta.yaml")
#let lanes = meta.lanes
#let chapters = meta.chapters
#let tables = meta.at("tables", default: ())
#let labels = meta.at("labels", default: (:))
#let findings = lanes.map(l => load-list("data/findings-" + l.key + ".yaml")).flatten()
#let checks = load-list("data/claim-check.yaml")
#let chapter-file(c) = "prose/chapter-" + c.key + ".md"
#let prose-files = (lanes.map(l => "prose/" + l.key + ".md") + chapters.map(chapter-file)
  + ("prose/summary.md", "prose/method.md"))

#let kind-of(f) = str(f.at("kind", default: "fact"))
#let claim-of(f) = f.at("claim", default: none)
#let table-of(f) = { let t = f.at("table", default: none); if t == none { none } else { str(t) } }
#let table-named(k) = tables.find(x => str(x.key) == k)
#let kinds = ("fact", "open", "conflict", "gap")
#let severity-rank = (high: 0, medium: 1, low: 2)
// Facts first, then what the documents leave open; most important first within each.
#let entry-key(f) = (kinds.position(k => k == kind-of(f)), severity-rank.at(str(f.severity), default: 3), str(f.id))
#let entries-of(c) = (findings
  .filter(f => table-of(f) == none and str(f.at("chapter", default: "")) == str(c.key))
  .sorted(key: entry-key))
#let check-of(id) = checks.find(c => c.id == id)

// ---------- data checks: a failed build means bad data ----------

#let fail-if(bad, msg) = if bad.len() > 0 { panic(msg + ": " + bad.join("; ")) }

#let label-keys = (
  "target", "version", "date", "agents", "contents", "summary", "facts", "id", "source",
  "conflicts-with", "searched", "check", "none", "lanes", "method",
  "open", "conflict", "gap", "suspected", "holds", "weakened", "wrong", "unverifiable",
)
#fail-if(label-keys.filter(k => k not in labels), "Labels missing from data/meta.yaml")
#let txt(k) = str(labels.at(k))

#let ids = findings.map(f => str(f.id))
#fail-if(ids.filter(i => ids.filter(j => j == i).len() > 1).dedup(), "Duplicate finding IDs")

#let placed = chapters.map(c => c.at("tables", default: ()).map(str)).flatten()
#let allowed = (
  severity: ("high", "medium", "low"),
  confidence: ("verified", "suspected"),
  kind: kinds,
  chapter: chapters.map(c => str(c.key)),
  table: tables.filter(x => "file" not in x).map(x => str(x.key)),
  placed: tables.map(x => str(x.key)),
  claim: ("holds", "weakened", "wrong", "unverifiable"),
  verdict: ("holds", "weakened", "wrong"),
)
// (where, field, value) for every value with a fixed list
#let values = (
  findings.map(f => (
    (f.id, "severity", f.at("severity", default: none)),
    (f.id, "confidence", f.at("confidence", default: none)),
    (f.id, "kind", kind-of(f)),
    if table-of(f) == none { (f.id, "chapter", f.at("chapter", default: none)) }
    else { (f.id, "table", table-of(f)) },
    ..if claim-of(f) != none { ((f.id, "claim", claim-of(f).at("status", default: none)),) },
  )).sum(default: ())
  + checks.map(c => ("claim-check " + str(c.id), "verdict", c.at("verdict", default: none)))
  + placed.map(k => ("meta.yaml chapters", "placed", k))
)
#fail-if(values.filter(((w, k, v)) => v == none or str(v) not in allowed.at(k))
  .map(((w, k, v)) => str(w) + " " + k + " = " + repr(v)), "Missing or unknown value")
#fail-if(allowed.placed.filter(k => placed.filter(p => p == k).len() != 1),
  "Tables that are not in exactly one chapter's `tables`")
#fail-if(findings.filter(f => kind-of(f) == "conflict" and claim-of(f) == none).map(f => str(f.id)),
  "A conflict without `claim`")
#fail-if(findings.filter(f => table-of(f) != none and table-named(table-of(f)) != none).map(f => {
  let cols = table-named(table-of(f)).columns.map(c => str(c.key))
  let bad = f.at("cells", default: (:)).keys().filter(k => k not in cols)
  if "cells" not in f { str(f.id) + " has no cells" }
  else if bad.len() > 0 { str(f.id) + " " + bad.join(", ") }
}).filter(x => x != none), "Table rows with missing cells or cells with no such column")

#let id-pattern = regex("\\b(?:" + lanes.map(l => upper(str(l.key))).join("|") + ")-\\d+\\b")
#let id-refs = prose-files.map(p => (p, read(p).matches(id-pattern).map(m => m.text))) + (
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
#let none-recorded = text(fill: gray, emph(txt("none")))

#let pill(label, fill) = box(
  fill: fill, inset: (x: 4pt, y: 2pt), outset: (y: 1pt), radius: 2pt,
  text(fill: white, size: 1em, weight: "bold", label),
)
// Severity is how much a fact matters to the answer, not whether it is good or bad:
// one hue, darker for more weight.
#let colors = (
  high: rgb("#1b4f72"), medium: rgb("#5d8aa8"), low: rgb("#aab7b8"),
  open: rgb("#b9770e"), conflict: rgb("#b03a2e"), gap: rgb("#6c3483"),
  suspected: rgb("#7f8c8d"),
  holds: rgb("#1e8449"), weakened: rgb("#b9770e"), wrong: rgb("#b03a2e"),
  unverifiable: rgb("#7f8c8d"),
)
#let badge(s) = pill(txt(s), colors.at(s, default: gray))
#let check-pill(c) = pill(txt("check") + ": " + txt(str(c.verdict)), colors.at(str(c.verdict), default: gray))
#let pills(f) = {
  let c = check-of(f.id)
  let ps = (
    if kind-of(f) != "fact" { badge(kind-of(f)) },
    if str(f.confidence) == "suspected" { badge("suspected") },
    if c != none { check-pill(c) },
  ).filter(p => p != none)
  ps.join(h(3pt))
}

// In a narrow table column a path may break after `/`.
#let loc(l, wrap: false) = {
  let one(x) = raw(if wrap { str(x).replace("/", "/\u{200B}") } else { str(x) })
  if l == none { [—] }
  else if type(l) == array { l.map(one).join(linebreak()) }
  else { one(l) }
}

#let width-of(c) = { let w = c.at("width", default: 1); if w == "auto" { auto } else { w * 1fr } }
#let shown(c, v) = c.at("values", default: (:)).at(str(v), default: str(v))
#let cell(c, v) = {
  if v == none [—]
  else if type(v) == array { md(v.map(x => shown(c, x)).join(", ")) }
  else { md(shown(c, v)) }
}

#let grid-table(columns: (), header: (), rows: ()) = table(
  columns: columns,
  stroke: (x, y) => if y == 0 { (bottom: 0.7pt) } else { (bottom: 0.3pt + luma(220)) },
  inset: (x: 5pt, y: 5pt),
  align: left + horizon,
  table.header(..header.map(h => text(weight: "bold", h))),
  ..rows,
)

// A row from a file is plain data; a row from a finding gets its ID and location.
#let table-block(tb) = {
  let cols = tb.columns
  let from-file = "file" in tb
  let rows = if from-file { load-list(tb.file) } else {
    findings.filter(f => table-of(f) == str(tb.key)).sorted(key: f => str(f.id))
  }
  let value(r, k) = if from-file { r.at(k, default: none) } else { r.cells.at(k, default: none) }
  if "sort" in tb { rows = rows.sorted(key: r => str(value(r, str(tb.sort)))) }
  if rows.len() == 0 { return none-recorded }
  if from-file {
    grid-table(
      columns: cols.map(width-of),
      header: cols.map(c => str(c.name)),
      rows: rows.map(r => cols.map(c => cell(c, value(r, str(c.key))))).flatten(),
    )
  } else {
    grid-table(
      columns: (auto,) + cols.map(width-of) + (1.2fr,),
      header: (txt("id"),) + cols.map(c => str(c.name)) + (txt("source"),),
      rows: rows.map(f => (
        [#raw(f.id)#label(f.id)],
        ..cols.map(c => cell(c, value(f, str(c.key)))),
        text(size: 10pt)[#loc(f.at("location", default: none), wrap: true)
          #if pills(f) != none [\ #pills(f)]],
      )).flatten(),
    )
  }
}

// Document text reads as a quotation; a gap's quote is the search command.
#let entry(f) = {
  let c = check-of(f.id)
  let cl = claim-of(f)
  let gap = kind-of(f) == "gap"
  block(breakable: true, width: 100%, inset: (left: 8pt, y: 4pt),
    stroke: (left: 2.5pt + colors.at(str(f.severity), default: gray)))[
    #set par(justify: false)
    #text(weight: "bold")[#raw(f.id) #h(4pt)] #md(f.finding) #label(f.id)
    #pills(f)

    *#txt(if gap { "searched" } else { "source" }).*
    #if f.at("quote", default: none) != none {
      if gap { raw(str(f.quote)) } else { quote(str(f.quote)) }
    }
    \ #loc(f.at("location", default: none))

    #if cl != none [
      *#txt("conflicts-with").* #badge(str(cl.at("status", default: "unverifiable")))
      #quote(str(cl.at("quote", default: ""))) \ #loc(cl.at("location", default: none))
    ]

    #if c != none and c.at("note", default: none) != none [*#txt("check").* #md(c.note)]
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
// Typst shrinks raw text to 0.8em by default; keep it at the surrounding size.
#show raw: set text(size: 1.25em)
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
    strong(txt("target")), str(meta.target),
    strong(txt("version")), raw(str(meta.commit)),
    strong(txt("date")), str(meta.date),
    strong(txt("agents")), str(meta.agents),
  )
]

#pagebreak()
#outline(title: txt("contents"), depth: 2)

// ---------- summary ----------

= #txt("summary")

#md-file("prose/summary.md")

// ---------- chapters: prose, tables, then the chapter's findings ----------

#for c in chapters [
  = #str(c.title)

  #md-file(chapter-file(c))

  #for k in c.at("tables", default: ()) [
    #let tb = table-named(str(k))
    == #str(tb.title)
    #table-block(tb)
  ]

  #let fs = entries-of(c)
  #if fs.len() > 0 [
    == #txt("facts")
    #fs.map(entry).join()
  ]
]

// ---------- lane notes ----------

= #txt("lanes")

#for l in lanes [
  == #str(l.name)
  #md-file("prose/" + l.key + ".md", h1-level: 3)
]

// ---------- method and limits ----------

= #txt("method")

#md-file("prose/method.md")
