// Appraisal report template, for lens/appraise.md. Copied into the run directory as
// report.typ; agents never edit it. Tables come from data/*.yaml, narrative from prose/*.md
// (rendered with cmarker). Every file named here must exist: `[]` or an empty .md is fine.
// Build from the run directory:  typst compile report.typ REPORT.pdf
//
// data/meta.yaml:
//   title, question, target, commit, date, agents, lang (optional, default "en")
//   verdict: one sentence, shown first
//   lanes: [{key: a, name: "The paper"}, {key: b, name: "..."}]
//   -> loads data/findings-<key>.yaml and prose/<key>.md for each lane
//   aspects: [claims, consistency, system, artifact, method]  optional subset, default all
//   criteria_source: the published checklist behind data/criteria.yaml (optional)
//   assumptions: what every effort estimate assumes (required once any option has effort)
// Also read: data/claim-check.yaml, data/artifacts.yaml, data/criteria.yaml,
//   data/options.yaml, prose/summary.md, prose/questions.md, prose/method.md
// The build stops on bad data: a duplicate finding ID, an ID that no finding has (prose
// included), a value outside its list in `allowed` below, or an effort with no basis.

#import "@preview/cmarker:0.1.10"

// ---------- data ----------

#let load-list(path) = { let d = yaml(path); if d == none { () } else { d } }

#let meta = yaml("data/meta.yaml")
#let lanes = meta.lanes
#let aspect-names = (
  claims: "Claims and evidence",
  consistency: "Internal inconsistencies",
  system: "System description vs. code",
  artifact: "Reproducibility and artifact",
  method: "Methodological appraisal",
)
#let aspects = meta.at("aspects", default: aspect-names.keys()).map(str)
#let findings = lanes.map(l => load-list("data/findings-" + l.key + ".yaml")).flatten()
#let checks = load-list("data/claim-check.yaml")
#let artifacts = load-list("data/artifacts.yaml")
#let criteria = load-list("data/criteria.yaml")
#let options = load-list("data/options.yaml")
#let prose-files = lanes.map(l => "prose/" + l.key + ".md") + ("prose/summary.md", "prose/questions.md", "prose/method.md")

#let claim-of(f) = f.at("claim", default: none)
#let claim-status(f) = str(claim-of(f).at("status", default: "unverifiable"))
#let aspect-of(f) = str(f.at("aspect", default: ""))
// A claim that holds is listed only in the claims matrix.
#let confirmed(f) = aspect-of(f) == "claims" and claim-of(f) != none and claim-status(f) == "holds"
#let severity-rank = (high: 0, medium: 1, low: 2)
#let threats = ("construct", "internal", "external", "conclusion")
#let sort-key(f) = {
  let t = threats.position(t => t == f.at("threat", default: none))
  (if t == none { 0 } else { t + 1 }, severity-rank.at(str(f.severity), default: 3), str(f.id))
}
#let listed = findings.filter(f => not confirmed(f)).sorted(key: f => sort-key(f).slice(1))
#let in-aspect(a) = listed.filter(f => aspect-of(f) == a).sorted(key: sort-key)
#let matrix = findings.filter(f => aspect-of(f) == "claims").sorted(key: f => str(f.id))
#let check-of(id) = checks.find(c => c.id == id)
#let related(id) = findings.filter(f => str(id) in f.at("bears_on", default: ()).map(str)).map(f => f.id)
#let estimates = options.map(o => (o,) + o.at("parts", default: ())).flatten().filter(e => "effort" in e)

// ---------- data checks: a failed build means bad data ----------

#let fail-if(bad, msg) = if bad.len() > 0 { panic(msg + ": " + bad.join("; ")) }
#let ids = findings.map(f => str(f.id))
#fail-if(ids.filter(i => ids.filter(j => j == i).len() > 1).dedup(), "Duplicate finding IDs")

#let allowed = (
  severity: ("high", "medium", "low"),
  confidence: ("verified", "suspected"),
  aspect: aspects,
  aspects: aspect-names.keys(),
  threat: threats,
  claim: ("holds", "weakened", "wrong", "unverifiable"),
  verdict: ("holds", "weakened", "wrong"),
  available: ("present", "partial", "missing"),
  criterion: ("met", "partial", "unmet", "n/a"),
)
// (where, field, value) for every value with a fixed list
#let values = (
  findings.map(f => (
    (f.id, "severity", f.at("severity", default: none)),
    (f.id, "confidence", f.at("confidence", default: none)),
    (f.id, "aspect", f.at("aspect", default: none)),
    ..if "threat" in f { ((f.id, "threat", f.threat),) },
    ..if claim-of(f) != none { ((f.id, "claim", claim-of(f).at("status", default: none)),) },
  )).sum(default: ())
  + aspects.map(a => ("meta.yaml", "aspects", a))
  + checks.map(c => ("claim-check " + str(c.id), "verdict", c.at("verdict", default: none)))
  + artifacts.map(x => ("artifact " + str(x.at("item", default: "?")), "available", x.at("status", default: none)))
  + criteria.map(x => ("criterion " + str(x.at("criterion", default: "?")), "criterion", x.at("status", default: none)))
)
#fail-if(values.filter(((w, k, v)) => v == none or str(v) not in allowed.at(k))
  .map(((w, k, v)) => str(w) + " " + k + " = " + repr(v)), "Missing or unknown value")
#fail-if(matrix.filter(f => claim-of(f) == none).map(f => str(f.id)), "A claims finding without `claim`")
#fail-if(estimates.filter(e => str(e.at("basis", default: "")).trim() == "")
  .map(e => str(e.at("option", default: e.at("task", default: "?")))), "Effort with no basis")
#fail-if(if estimates.len() > 0 and "assumptions" not in meta { ("data/meta.yaml",) } else { () },
  "Efforts need `assumptions`")

#let id-pattern = regex("\\b(?:" + lanes.map(l => upper(str(l.key))).join("|") + ")-\\d+\\b")
#let refs(xs) = xs.map(x => x.at("findings", default: ())).sum(default: ())
#let id-refs = prose-files.map(p => (p, read(p).matches(id-pattern).map(m => m.text))) + (
  ("bears_on", findings.map(f => f.at("bears_on", default: ())).sum(default: ())),
  ("data/claim-check.yaml", checks.map(c => c.id)),
  ("data/artifacts.yaml", refs(artifacts)),
  ("data/criteria.yaml", refs(criteria)),
  ("data/options.yaml", refs(options)),
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
  verified: rgb("#2e4053"), suspected: rgb("#7f8c8d"),
  holds: rgb("#1e8449"), weakened: rgb("#b9770e"), wrong: rgb("#b03a2e"),
  unverifiable: rgb("#7f8c8d"),
  present: rgb("#1e8449"), partial: rgb("#b9770e"), missing: rgb("#b03a2e"),
  met: rgb("#1e8449"), unmet: rgb("#b03a2e"), "n/a": rgb("#7f8c8d"),
  recommended: rgb("#1e8449"),
)
#let badge(s) = pill(str(s), colors.at(str(s), default: gray))
#let check-pill(c) = pill("check: " + str(c.verdict), colors.at(str(c.verdict), default: gray))
#let check-badge(id) = { let c = check-of(id); if c == none [—] else { badge(c.verdict) } }

#let loc(l) = {
  if l == none { [—] }
  else if type(l) == array { l.map(x => raw(str(x))).join(linebreak()) }
  else { raw(str(l)) }
}
// Document text (under sources/) reads as a quotation, code as code.
#let said(s, l) = {
  let first = if type(l) == array { l.first() } else { l }
  if str(first).starts-with("sources/") { quote(str(s)) } else { raw(str(s)) }
}
#let id-link(id) = link(label(str(id)), raw(str(id)))
#let id-links(ids, sep: [, ]) = if ids.len() == 0 [—] else { ids.map(id-link).join(sep) }

#let grid-table(columns: (), header: (), rows: ()) = table(
  columns: columns,
  stroke: (x, y) => if y == 0 { (bottom: 0.7pt) } else { (bottom: 0.3pt + luma(220)) },
  inset: (x: 5pt, y: 5pt),
  align: left + horizon,
  table.header(..header.map(h => text(weight: "bold", h))),
  ..rows,
)

#let checklist(xs, first, promised: false) = if xs.len() == 0 { none-recorded } else {
  let opt(x) = if promised { (x,) } else { () }
  grid-table(
    columns: (1fr,) + opt(auto) + (auto, 1fr, auto),
    header: (first,) + opt([Promised at]) + ([Status], [Note], [Findings]),
    rows: xs.map(x => (md(x.at("item", default: x.at("criterion", default: none))),)
      + opt(loc(x.at("promised", default: none)))
      + (badge(x.status), md(x.at("note", default: none)),
        id-links(x.at("findings", default: ()), sep: linebreak()))).flatten(),
  )
}

#let entry(f) = {
  let c = check-of(f.id)
  let cl = claim-of(f)
  let conflict = aspect-of(f) == "consistency"
  block(breakable: true, width: 100%, inset: (left: 8pt, y: 4pt),
    stroke: (left: 2.5pt + colors.at(str(f.severity), default: gray)))[
    #set par(justify: false)
    #text(weight: "bold")[#raw(f.id) #h(4pt)] #md(f.finding) #label(f.id)
    #badge(f.severity) #h(3pt) #badge(f.confidence)
    #if "threat" in f [#h(3pt) #pill(f.threat + " validity", colors.suspected)]
    #if c != none [#h(3pt) #check-pill(c)]

    #if cl != none [
      *#if conflict [Statement] else [Claim in the target].* #badge(claim-status(f))
      #said(cl.at("quote", default: ""), cl.at("location", default: "")) \ #loc(cl.at("location", default: none))
    ]

    *#if conflict [Conflicts with] else [Evidence].*
    #if f.at("quote", default: none) != none { said(f.quote, f.at("location", default: "")) }
    \ #loc(f.at("location", default: none))

    #if "rests_on" in f [*Rests on.* #str(f.rests_on) \ ]
    #if f.at("bears_on", default: ()).len() > 0 [*Bears on* #id-links(f.bears_on) \ ]
    #if c != none and c.at("note", default: none) != none [*Claim check.* #md(c.note)]
  ]
  v(6pt)
}
#let entries(a) = { let fs = in-aspect(a); if fs.len() == 0 { none-recorded } else { fs.map(entry).join() } }

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
    [*Target*], str(meta.target),
    [*Version*], raw(str(meta.commit)),
    [*Date*], str(meta.date),
    [*Agents*], str(meta.agents),
  )
]

#pagebreak()
#outline(depth: 2)

// ---------- verdict ----------

= Verdict

#block(width: 100%, inset: 10pt, radius: 3pt, fill: luma(240))[
  #set par(justify: false)
  #text(size: 14pt, weight: "bold", str(meta.at("verdict", default: "No verdict recorded.")))
]

#md-file("prose/summary.md", h1-level: 2)

== Findings overview

Most severe first. IDs link to the full entry. _Suspected_ findings are plausible but not
confirmed. Check is the claim check's verdict, where there is one. Claims that hold are
listed in the claims matrix only.

#if listed.len() == 0 { none-recorded } else {
  grid-table(
    columns: (auto, 1fr, auto, auto, auto),
    header: ([ID], [Finding], [Aspect], [Severity], [Check]),
    rows: listed.map(f => (
      id-link(f.id),
      [#md(f.finding)#if f.confidence == "suspected" [ #text(fill: gray)[_(suspected)_]]],
      aspect-of(f), badge(f.severity), check-badge(f.id),
    )).flatten(),
  )
}

// ---------- one section per aspect ----------

#for a in aspect-names.keys().filter(a => a in aspects) [
  = #aspect-names.at(a)

  #if a == "claims" [
    Status says how well the target's own evidence supports each claim: _holds_,
    _weakened_ (few data points, self-report only, or confounded), _wrong_ (contradicted
    by the target, its data or its code), _unverifiable_ (nothing in the target bears on
    it). Related lists the findings that bear on the claim.

    #if matrix.len() == 0 { none-recorded } else {
      grid-table(
        columns: (auto, 1fr, auto, 1fr, auto),
        header: ([ID], [Claim in the target], [Status], [What the evidence shows], [Related]),
        rows: matrix.map(f => {
          let cl = claim-of(f)
          (
            if confirmed(f) [#raw(f.id)#label(f.id)] else { id-link(f.id) },
            [#quote(str(cl.at("quote", default: ""))) \ #loc(cl.at("location", default: none))
              #if "rests_on" in f [\ #text(fill: gray)[Rests on: #str(f.rests_on)]]],
            badge(claim-status(f)),
            [#md(f.finding) \ #loc(f.at("location", default: none))],
            id-links(related(f.id), sep: linebreak()),
          )
        }).flatten(),
      )
    }

    == Claims that do not hold
  ]

  #if a == "artifact" [
    == Checklist

    What the target says is available, and what a reproduction needs.

    #checklist(artifacts, [Item], promised: true)

    == Findings
  ]

  #if a == "method" [
    == Criteria

    #if "criteria_source" in meta [Checked against #str(meta.criteria_source).]

    #checklist(criteria, [Criterion])

    == Findings
  ]

  #entries(a)
]

// ---------- options and effort ----------

= Options and effort

#if estimates.len() > 0 [
  Every effort is a judgement, not a measurement, and says how it was estimated.
  All estimates assume: #md(meta.assumptions)
]

#if options.len() == 0 { none-recorded }
#for o in options [
  == #str(o.option) #if o.at("recommended", default: false) [#h(4pt) #badge("recommended")]

  #md(o.at("description", default: none))

  #let parts = o.at("parts", default: ())
  #if parts.len() > 0 or "effort" in o {
    grid-table(
      columns: (1fr, auto, 1fr),
      header: ([Part], [Effort (judgement)], [Basis]),
      rows: parts.map(p => (md(p.task), [#p.at("effort", default: [—])], md(p.at("basis", default: none)))).flatten()
        + (if "effort" in o { (strong[Total], strong(o.effort), md(o.basis)) } else { () }),
    )
  }

  #if o.at("findings", default: ()).len() > 0 [Findings: #id-links(o.findings)]
]

// ---------- open questions ----------

= Open questions

#if read("prose/questions.md").trim() == "" { none-recorded } else { md-file("prose/questions.md") }

// ---------- lane notes ----------

= Lane notes

#for l in lanes [
  == #l.name
  #md-file("prose/" + l.key + ".md", h1-level: 3)
]

// ---------- method and limits ----------

= Method and limits

#md-file("prose/method.md", h1-level: 2)
