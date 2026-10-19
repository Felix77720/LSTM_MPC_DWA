# Final blind review C — figures, readability, references, and submission compliance

## Verdict: MINOR

**Blocking issues: none.**

### Integrity and rendered-page check

- All 8 files listed in `FREEZE_MANIFEST.sha256` match their SHA-256 digests.
- Rendered `main_revised.pdf`: 4 pages, US Letter (612 × 792 pt). Rendered `supplementary_methods.pdf`: 15 pages.
- No clipped text, overlapping captions, or page-edge overflow was visible. The main paper is within the four-page limit.

### Main-paper figures and table

- Figure 1 is on page 2, before the Planning Method heading, with its full caption. The scene, start/goal, obstacle paths, and direct start-to-goal direction are distinguishable.
- Figure 3 panels a–d carry direct controller labels. The plotted outcomes and terminal marks agree: a and c stop, b collides, and d reaches the goal. The non-arrival routes end at their recorded states rather than being drawn to the goal. Captions and nearby text identify the same comparison.
- Figures 2–4 and Table 1 are fully on the page and legible in the rendered PDF. Table 1 fits on one page; its headers and five controller rows can be read without ambiguity. Figure 4's plot labels are the smallest main-text elements, but remain readable at full-page rendering.
- The main text uses compact conference typography; the body and references render at about 10 pt, while some plot annotations are about 8 pt. No figure/text mismatch or destructive crop was found.

### Supplement

- All 15 rendered pages were inspected. Tables S1–S10 and Figures S1–S4 stay within the page; their labels and captions are visible.
- Minor layout note: pages 6, 12, and 15 have conspicuously large unused areas around otherwise complete tables/figures. This does not hide content or impair comprehension, but the supplement could be more compactly laid out.

### References and compliance

- The main PDF contains 14 sequential references ([1]–[14]); all are cited in the text. The rendered DOI labels are live links for 13 entries. Reference [8] provides a visible CNKI source URL; the link is embedded in the PDF.
- Per `reference_verification.md`, all 14 entries were checked against currently available bibliographic records and no guessed fields were added. The Chang et al. online-first record does not supply a DOI, volume, issue, or final page range; those fields are intentionally omitted and a CNKI source link is supplied. The Dobrevski record has no issue number in the consulted authoritative records. The audit notes that the direct Crossref API was inaccessible and records its publisher/institutional alternatives; no unresolved field-level mismatch is reported.
- `command_template_compliance.md` records the supplied conference checklist as passed. The frozen PDF independently confirms the four-page Letter layout and sequential Figures 1–4 and Table 1. Its report also documents 14 references, the source link for the Chang item, and the stated affiliation-country requirement.

### Minor action

If layout changes are still permitted before submission, tighten the whitespace on supplement pages 6, 12, and 15. No change is required to resolve a blocking issue.

## Post-minor verification

**Status: PASS**

- All 9 files listed in the postminor packet manifest match their SHA-256 digests.
- The updated supplementary PDF renders to 15 US Letter pages. All 15 pages were visually inspected; no clipping, overflow, or severe overlap was found.
- The added explanations on pages 2, 3, 8, and 9 remain within the page layout and do not collide with equations, tables, headings, or page numbers. The denser text on pages 3 and 8 remains readable.
- This regression check does not reopen the previously identified, non-blocking whitespace on pages 6, 12, and 15.
