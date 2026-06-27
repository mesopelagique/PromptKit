# ContextStore

Loads named **contexts** — plain text prepended to the system message (background, role, audience, constraints…) — from a folder. Contexts are user-provided; by default the folder is `Resources/contexts` (which may not exist until you add files).

## Properties

| Property Name | Type | Default Value | Description |
|---------------|------|---------------|-------------|
| `folder` | 4D.Folder | `Resources/contexts` | Root folder containing one text file per context (`<name>.md` or `<name>`). |
| `_cache` | Object | {} | Cache of already loaded contexts, keyed by name. |

## Constructor

**ContextStore**(*folder* : 4D.Folder)

| Parameter | Type | Description |
|-----------|------|-------------|
| *folder* | 4D.Folder | Optional. Defaults to the `Resources/contexts` folder. |

A `PromptRunner` exposes a ready-to-use store as `$runner.contexts`.

## Functions

### get()

**get**(*name* : Text) : Text

Returns the text content of a context (`<name>.md` or `<name>`). Cached. **Throws** if not found.

### exists()

**exists**(*name* : Text) : Boolean

Returns `True` if a context with this name exists.

### list()

**list**() : Collection

Returns the sorted collection of available context names.

> You can also pass context text inline, without any file: `$runner.run("summarize"; $input; {context: "You answer for a French audience."})`.
