# PromptRunner

Runs [prompts](Prompt.md) against an `OpenAI` (or OpenAI-compatible) client, and chains them together. Each step is a single chat completion; chaining pipes the output of one prompt into the input of the next.

## Properties

| Property Name | Type | Default Value | Description |
|---------------|------|---------------|-------------|
| `client` | [OpenAI](OpenAI.md) | - | The client used to perform completions. |
| `store` | [PromptStore](PromptStore.md) | bundled `Resources/prompts` | The store used to resolve prompt names. |
| `strategies` | [StrategyStore](StrategyStore.md) | bundled `Resources/strategies` | The store used to resolve strategy names. |
| `contexts` | [ContextStore](ContextStore.md) | `Resources/contexts` | The store used to resolve context names. |
| `sessionsFolder` | 4D.Folder | host data folder | Folder where named [sessions](Session.md) are persisted. |
| `model` | Text | `"gpt-4o-mini"` | Default model used when a call does not specify one. |

## Constructor

**PromptRunner**(*client* : [OpenAI](OpenAI.md) ; *store* : [PromptStore](PromptStore.md))

| Parameter | Type | Description |
|-----------|------|-------------|
| *client* | [OpenAI](OpenAI.md) | The client used to run completions. |
| *store* | [PromptStore](PromptStore.md) | Optional. Defaults to a store over the bundled `Resources/prompts` folder. |

```4d
var $client:=cs.AIKit.OpenAI.new("your api key")
var $runner:=cs.PromptKit.PromptRunner.new($client)
```

## Functions

### run()

**run**(*name* : Text ; *input* : Text ; *options* : Object) : [PromptResult](PromptResult.md)

| Parameter | Type | Description |
|-----------|------|-------------|
| *name* | Text | The prompt name to run. |
| *input* | Text | The input passed to the prompt. |
| *options* | Object | Optional. See the options below. |
| Function result | [PromptResult](PromptResult.md) | The result of the run (`text`, `success`, `errors`). |

`options` keys:

| Key | Type | Description |
|-----|------|-------------|
| `variables` | Object | Values substituted into the prompt's `{{placeholders}}`. |
| `parameters` | [OpenAIChatCompletionsParameters](OpenAIChatCompletionsParameters.md) \| Object | Overrides the model and other completion options. |
| `strategy` | Text \| [Strategy](Strategy.md) \| Object | A reasoning prompt prepended to the system message (name or raw text). |
| `context` | Text \| Object | Extra text prepended to the system message (name or raw text). |
| `session` | Text \| [Session](Session.md) | A persistent conversation history (name or instance). |

Runs a single prompt against *input*. The composed system message order is **strategy → context → prompt**. When a `session` is given, prior history is sent before the input and the new exchange is appended and persisted. Throws if the prompt is not found.

```4d
var $result:=$runner.run("summarize"; $inputText)
var $translated:=$runner.run("translate"; $inputText; {variables: {lang: "French"}})
var $reasoned:=$runner.run("analyze_claims"; $inputText; {strategy: "cot"})
```

### chain()

**chain**(*names* : Collection) : [PromptChain](PromptChain.md)

| Parameter | Type | Description |
|-----------|------|-------------|
| *names* | Collection | Prompt names to run in order. |
| Function result | [PromptChain](PromptChain.md) | A chain pre-filled with the given prompts. |

```4d
var $result:=$runner.chain(["extract_wisdom"; "summarize"]).run($inputText)
```

### newChain()

**newChain**() : [PromptChain](PromptChain.md)

Returns an empty [PromptChain](PromptChain.md) to build fluently.

```4d
var $result:=$runner.newChain().prompt("extract_wisdom").prompt("summarize").run($inputText)
```

### session()

**session**(*name* : Text) : [Session](Session.md)

Creates (and auto-loads) a named [Session](Session.md) persisted in `sessionsFolder`. Pass it via the `session` option of `run()` to keep conversation history across calls.

```4d
var $session:=$runner.session("my-chat")
$runner.run("summarize"; $doc; {session: $session})
$runner.run("answer_question"; "What were the key points?"; {session: $session})
```
