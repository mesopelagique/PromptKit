# PromptChain

An ordered sequence of [prompts](Prompt.md). The output of each step is piped as the input of the next. A chain is created from a [PromptRunner](PromptRunner.md) via `chain()` or `newChain()`.

## Properties

| Property Name | Type | Default Value | Description |
|---------------|------|---------------|-------------|
| `runner` | [PromptRunner](PromptRunner.md) | - | The runner used to execute each step. |
| `steps` | Collection | [] | Ordered steps, each `{name: Text; options: Object}`. |

## Constructor

Create a chain from a [PromptRunner](PromptRunner.md):

```4d
var $chain:=$runner.newChain()
// or pre-filled
var $chain:=$runner.chain(["extract_wisdom"; "summarize"])
```

## Functions

### prompt()

**prompt**(*name* : Text ; *options* : Object) : PromptChain

| Parameter | Type | Description |
|-----------|------|-------------|
| *name* | Text | The prompt name for this step. |
| *options* | Object | Optional. `{variables: Object; parameters: `[OpenAIChatCompletionsParameters](OpenAIChatCompletionsParameters.md)`\|Object}`. |
| Function result | PromptChain | Returns the chain itself, for fluent chaining. |

Adds a prompt step and returns the chain, so calls can be chained.

```4d
$runner.newChain().prompt("extract_wisdom").prompt("summarize")
```

### run()

**run**(*input* : Text ; *variables* : Object) : [PromptChainResult](PromptChainResult.md)

| Parameter | Type | Description |
|-----------|------|-------------|
| *input* | Text | The initial input passed to the first prompt. |
| *variables* | Object | Optional. Variables merged into every step (step-level variables win). |
| Function result | [PromptChainResult](PromptChainResult.md) | The aggregated result of the chain. |

Runs the chain: pipes *input* through each prompt in order, using each step's output as the next step's input. **Stops at the first failing step.**

```4d
var $result:=$runner.chain(["extract_wisdom"; "summarize"]).run($inputText)
// $result.text / $result.outputs / $result.results / $result.success
```
