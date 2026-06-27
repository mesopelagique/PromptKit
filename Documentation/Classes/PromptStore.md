# PromptStore

Loads [prompts](Prompt.md) from a folder, in two supported layouts:

- **system-style** — a sub-folder `<name>` containing a `system.md` (and an optional `user.md`).
- **[VS Code-style](https://code.visualstudio.com/docs/agent-customization/prompt-files)** — a single `<name>.prompt.md` file.

In both layouts, an optional leading **YAML frontmatter** (delimited by `---`) is stripped from the content sent to the AI and kept on the prompt's [`metadata`](Prompt.md). A library of prompts is bundled in the component's `Resources/prompts` folder.

## Properties

| Property Name | Type | Default Value | Description |
|---------------|------|---------------|-------------|
| `folder` | 4D.Folder | bundled `Resources/prompts` | Root folder containing one sub-folder per prompt. |
| `_cache` | Object | {} | Cache of already loaded prompts, keyed by name. |

## Constructor

**PromptStore**(*folder* : 4D.Folder)

| Parameter | Type | Description |
|-----------|------|-------------|
| *folder* | 4D.Folder | Optional. Defaults to the bundled `Resources/prompts` folder. |

```4d
// bundled prompts
var $store:=cs.PromptKit.PromptStore.new()

// custom folder
var $store:=cs.PromptKit.PromptStore.new(Folder("/path/to/my/prompts"))
```

## Functions

### get()

**get**(*name* : Text) : [Prompt](Prompt.md)

| Parameter | Type | Description |
|-----------|------|-------------|
| *name* | Text | The prompt name (sub-folder name, or `<name>.prompt.md` file base name). |
| Function result | [Prompt](Prompt.md) | The loaded prompt. |

Loads and returns a prompt by name. Resolves either `<name>/system.md` (+ optional `user.md`) or `<name>.prompt.md`; frontmatter is stripped into the prompt's `metadata`. Results are cached. **Throws** if the prompt is not found.

### exists()

**exists**(*name* : Text) : Boolean

Returns `True` if a prompt with this name exists in either layout.

### list()

**list**() : Collection

Returns the sorted, de-duplicated collection of available prompt names (both layouts).

```4d
var $names:=$store.list()  // ["agility_story"; "analyze_answers"; ...]
```
