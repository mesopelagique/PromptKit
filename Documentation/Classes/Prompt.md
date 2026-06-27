# Prompt

A reusable AI prompt: a system prompt and an optional user template. Prompts are usually loaded from a [PromptStore](PromptStore.md) and run through a [PromptRunner](PromptRunner.md), but they can also be created directly in code.

## Properties

| Property Name | Type | Default Value | Description |
|---------------|------|---------------|-------------|
| `name` | Text | - | The prompt name (the folder/file name in the store). |
| `system` | Text | - | The system prompt (the prompt body, frontmatter stripped). |
| `user` | Text | - | The optional user template (content of `user.md`). May be empty. |
| `metadata` | Object | {} | Frontmatter parsed from a `.prompt.md` file (e.g. `description`, `mode`, `model`, `tools`). |

## Computed properties

| Name | Type | Description |
|------|------|-------------|
| `description` | Text | Convenience accessor for `metadata.description`. |

## Constructor

**Prompt**(*data* : Object)

| Parameter | Type | Description |
|-----------|------|-------------|
| *data* | Object | `{name: Text; system: Text; user: Text}` |

```4d
var $prompt:=cs.PromptKit.Prompt.new({name: "translate"; system: "Translate to {{lang}}."; user: "{{input}}"})
```

## Functions

### buildMessages()

**buildMessages**(*input* : Text ; *variables* : Object) : Collection

| Parameter | Type | Description |
|-----------|------|-------------|
| *input* | Text | The input to run the prompt against. |
| *variables* | Object | Optional. Values substituted into `{{placeholders}}`. `input` is always available. |
| Function result | Collection | A collection of `{role; content}` messages ready for `chat.completions.create`. |

Builds the chat messages for this prompt:

- The `system` message is `system.md` / the prompt body, with variables substituted.
- The `user` message depends on the `user.md` template:
  - empty template → the raw *input* is sent;
  - template containing `{{...}}` or `${...}` → variables (including the input) are substituted;
  - static template (no placeholder) → the template is prepended to *input*.

```4d
var $messages:=$prompt.buildMessages("bonjour"; {lang: "English"})
```

### Variable syntaxes

Both the [mustache](https://mustache.github.io/) `{{name}}` form and the [VS Code](https://code.visualstudio.com/docs/agent-customization/prompt-files) `${...}` form are supported, resolved from the `variables` you pass (the run input is always available):

| Reference | Resolves to |
|-----------|-------------|
| `{{name}}` | `variables.name` |
| `${input}` | the run input |
| `${input:name}` | `variables.name` |
| `${input:name:placeholder}` | `variables.name`, or `placeholder` if missing |
| `${name}` | `variables.name` (e.g. supply `selection`, `file`… yourself) |

Editor-context variables like `${selection}` or `${file}` have no 4D equivalent — they resolve only if you provide them in `variables`. Unresolved references are left untouched.

## VS Code `.prompt.md` files

A [`PromptStore`](PromptStore.md) can also load [VS Code prompt files](https://code.visualstudio.com/docs/agent-customization/prompt-files) (`<name>.prompt.md`). Their leading YAML frontmatter is stripped from the `system` content and parsed into `metadata`:

```markdown
---
mode: agent
model: GPT-4o
description: Generate a React form component
tools: ['githubRepo', 'codebase']
---
Your goal is to generate a new React form component...
```

```4d
var $prompt:=$store.get("react-form")
$prompt.system       // "Your goal is to generate..." (frontmatter removed)
$prompt.metadata     // {mode: "agent"; model: "GPT-4o"; description: "..."; tools: ["githubRepo"; "codebase"]}
$prompt.description  // "Generate a React form component"
```

> The frontmatter is preserved for inspection only — it is **not** sent to the model, and fields like `model`/`tools` are not auto-applied.
