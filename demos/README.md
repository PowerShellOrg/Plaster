# Plaster Presentation Demos

Three ready-to-run demos showing **Plaster** scaffolding with both manifest formats,
using dummy data (Contoso / Fabrikam / Acme / Ada Lovelace).

| # | Format | Template | Shows off |
|---|--------|----------|-----------|
| 1 | **XML**  | `templates/01-xml-greeter`  | Classic format, `${PLASTER_PARAM_X}` syntax, `choice` param, `templateFile`, `message` |
| 2 | **JSON** | `templates/02-json-greeter` | Same template, modern format: `${X}` syntax, `&`-labels without XML escaping |
| 3 | **JSON** | `templates/03-json-module`  | `multichoice` (native `[0,1]` array default), `pattern` validation, `user-fullname` (git), **conditional** content, `newModuleManifest`, `modify` |
| 4 | both | `Demo4-Discovery-Authoring.ps1` | The surrounding cmdlets: `Get-PlasterTemplate` (discover), `New-PlasterManifest` (author), `Test-PlasterManifest` (validate), then scaffold from the authored template |

## Run it (non-interactive — safe for a live stage)

```powershell
# From the repo root
.\demos\Run-Demos.ps1            # runs all four
.\demos\Run-Demos.ps1 -Demo 2    # just one (1, 2, 3, 4)
.\demos\Demo4-Discovery-Authoring.ps1   # the discovery/authoring demo on its own
```

Every parameter is passed on the command line, so nothing prompts and the run is
deterministic. Generated projects land in `demos/output/`.

## Run it interactively (to show the prompts live)

Plaster turns each template parameter into a real cmdlet parameter *and* prompts for
any you omit. To demo the interactive Q&A, run a template by hand and leave parameters off:

```powershell
Import-Module .\Plaster\Plaster.psd1 -Force
Invoke-Plaster -TemplatePath .\demos\templates\03-json-module `
               -DestinationPath .\demos\output\live
```

You'll get prompts for the module name (with regex validation), author (pre-filled from
`git config user.name`), a single-choice license menu, and a multi-select feature list.
Run it from a real terminal — the VS Code integrated terminal works; piped/non-TTY hosts do not.

## Talking points

- **One engine, two formats.** Internally Plaster converts JSON manifests to the same XML
  structure the engine has always used, so JSON is purely an authoring convenience with
  zero behavioral difference. (See `Plaster/Private/ConvertFrom-JsonManifest.ps1`.)
- **Variable syntax differs by location:**
  - *Manifest attributes* (`destination`, message `text`): JSON lets you write the short
    `${ModuleName}`; Plaster rewrites it to `${PLASTER_PARAM_ModuleName}` automatically.
  - *`condition` expressions* and *template file bodies* (`<%= ... %>`): use the **full**
    `$PLASTER_PARAM_ModuleName` form — those paths are not rewritten.
- **Conditions exclude files.** In Demo 3, `Build` is deselected, so `build.ps1` is never
  created — show the output tree to make the point.
- **`modify` edits an already-generated file.** Demo 3 generates `README.md` with a
  `__LICENSE__` placeholder, then a `modify` action swaps in the chosen license.
- **Safety.** Templates are declarative and expressions run in a *constrained runspace* —
  a template can't run arbitrary destructive code. (See `New-ConstrainedRunspace.ps1`.)

## Side-by-side: same template, two formats

`01-xml-greeter/plasterManifest.xml` vs `02-json-greeter/plasterManifest.json` produce an
equivalent script. Good slide material for the XML-vs-JSON contrast:

- XML: `<choice label="&amp;Hello" .../>`  →  JSON: `{ "label": "&Hello" }` (no escaping)
- XML: `default="0"` string  →  JSON: `"default": 0` (and `[0, 1]` for multichoice)
- XML: `${PLASTER_PARAM_ScriptName}`  →  JSON: `${ScriptName}`

## Note on module fixes

Running the templates from source surfaced three small bugs that these demos depend on; all
are fixed in this branch:

1. `Test-PlasterManifest` resolved the XML schema (`PlasterManifest-v1.xsd`) relative to
   `Public/` when run from source — added a one-level-up fallback.
2. `ConvertFrom-JsonContentAction` leaked `AppendChild` return values into the pipeline for
   `modify` actions, returning an array instead of a single element — suppressed with `$null =`.
3. `Get-PlasterTemplate` (no args) looked for the bundled `Templates/` folder relative to
   `Public/` when run from source — added the same one-level-up fallback.

All three share one root cause: when the module runs from source its functions are
dot-sourced from `Public/`/`Private/`, so `$PSScriptRoot` points one level below the module
root. The compiled build in `Output/` flattens everything to the root, so it was already fine —
but it has been rebuilt (`.\build.ps1`) anyway so source and compiled match.
