# Strategy

A reasoning strategy: a named prompt prepended to the system message — e.g. Chain-of-Thought, Tree-of-Thought. A library is bundled in the component's `Resources/strategies` folder and resolved through a [StrategyStore](StrategyStore.md).

## Properties

| Property Name | Type | Default Value | Description |
|---------------|------|---------------|-------------|
| `name` | Text | - | The strategy name (the JSON file name in the store). |
| `description` | Text | - | Human-readable description. |
| `prompt` | Text | - | The prompt prepended to the system message. |

## Constructor

**Strategy**(*data* : Object)

| Parameter | Type | Description |
|-----------|------|-------------|
| *data* | Object | `{name: Text; description: Text; prompt: Text}` |

Usually you do not build a `Strategy` directly — you pass a name to `PromptRunner.run`'s `strategy` option, or load one from a [StrategyStore](StrategyStore.md).

```4d
var $strategy:=$runner.strategies.get("cot")
$strategy.prompt  // "Think step by step to answer the question. ..."
```

## Bundled strategies

`aot`, `cod`, `cot` (Chain-of-Thought), `ltm`, `reflexion`, `self-consistent`, `self-refine`, `standard`, `tot` (Tree-of-Thought).
