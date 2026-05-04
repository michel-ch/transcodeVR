# Project report (LaTeX)

`report.tex` is a structured LaTeX article describing the goal,
architecture, FFmpeg pipeline, and trade-offs of the `transcodeVR`
project. It uses standard `article` class plus `tikz`, `listings`,
`booktabs`, `tabularx`, `geometry`, `microtype`, `hyperref`, `xcolor`,
`fancyhdr` — all of which ship with any reasonably recent TeX
distribution.

## Compiling to PDF

The machine this was authored on has **no LaTeX engine installed**, so
the `.pdf` is not pre-built. Pick whichever path is easiest for you.

### Option A — Tectonic (lightweight, recommended)

Tectonic is a single-binary LaTeX engine that fetches packages on
demand. It's ~30 MB and reversible.

```powershell
scoop install tectonic
cd C:\Users\$env:USERNAME\Desktop\transcodeVR\report
tectonic report.tex
```

Produces `report.pdf` in the same folder. First run downloads packages
(takes a minute); subsequent runs are instant.

### Option B — MiKTeX or TeX Live (full distribution)

If you already have one of these, or prefer the full toolchain:

```powershell
cd C:\Users\$env:USERNAME\Desktop\transcodeVR\report
pdflatex report.tex
pdflatex report.tex      # second pass for the table of contents
```

Or with `latexmk`:

```powershell
latexmk -pdf report.tex
```

### Option C — Overleaf (zero install)

1. Create a free Overleaf account.
2. New Project ➜ Upload Project ➜ drag `report.tex`.
3. Click *Recompile*.

### Option D — pandoc (if already installed)

Pandoc still needs a LaTeX engine for PDF output, but if you have one:

```powershell
pandoc report.tex -o report.pdf --pdf-engine=xelatex
```

## What the report covers

1. **Goal** — what problem the project solves and what it deliberately
   doesn't.
2. **Architecture** — the three batch entry points, their shared
   conventions, and a TikZ dataflow diagram.
3. **FFmpeg pipeline** — the per-clip conversion command, the
   concat stage, and the 1080p path; with a per-parameter table for
   the `v360` filter.
4. **Trade-offs** — design decisions and known limitations.
5. **Conclusion** — pointer back to the markdown documentation in
   `docs/`.
