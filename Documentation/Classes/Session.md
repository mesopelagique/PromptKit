# Session

A persistent conversation history: a named, ordered list of `{role; content}` messages, optionally loaded from and saved to a JSON file. Pass a session to [PromptRunner](PromptRunner.md)'s `session` option so the model remembers previous turns.

## Properties

| Property Name | Type | Default Value | Description |
|---------------|------|---------------|-------------|
| `name` | Text | - | The session name (the JSON file name when persisted). |
| `messages` | Collection | [] | Ordered conversation messages (plain `{role; content}` objects). |
| `folder` | 4D.Folder | - | Folder where the session is persisted. If `Null`, the session stays in memory only. |

## Constructor

**Session**(*name* : Text ; *folder* : 4D.Folder)

Loads existing messages from `<folder>/<name>.json` if present. The easiest way to obtain one is `$runner.session("name")`, which binds it to the runner's `sessionsFolder`.

```4d
var $session:=$runner.session("my-chat")
```

## Functions

### append()

**append**(*message* : Variant)

Appends a message ([OpenAIMessage](OpenAIMessage.md) or `{role; content}` object) to the history. `PromptRunner.run` does this automatically for the user input and the assistant reply.

### save()

**save**()

Persists the session to `<folder>/<name>.json` (creating the folder if needed). Called automatically after a successful `run` with a session.

### load()

**load**()

Reloads messages from the backing file. Called by the constructor.

### reset()

**reset**()

Clears the history and removes the backing file.

### isEmpty()

**isEmpty**() : Boolean

Returns `True` when the session has no messages.

```4d
var $session:=$runner.session("my-chat")
$runner.run("summarize"; "Here is the document..."; {session: $session})
$runner.run("answer_question"; "What were the key points?"; {session: $session})
// $session.messages holds the full conversation, persisted on disk

$session.reset()  // start over
```
