# PromptChainResult

The result of running a [PromptChain](PromptChain.md). Holds each step's [result](PromptResult.md) and output, and exposes the final output text.

## Properties

| Property Name | Type | Default Value | Description |
|---------------|------|---------------|-------------|
| `results` | Collection of [PromptResult](PromptResult.md) | [] | One result per executed step. |
| `outputs` | Collection of Text | [] | One output text per executed step. |

## Computed properties

| Name | Type | Description |
|------|------|-------------|
| `text` | Text | The final output text of the chain (last step). |
| `success` | Boolean | `True` if every executed step succeeded. |
| `errors` | Collection | Errors from the first failed step, if any. |

```4d
var $result:=$runner.chain(["extract_wisdom"; "summarize"]).run($inputText)

$result.text            // final summary
$result.outputs[0]      // output of extract_wisdom
$result.outputs[1]      // output of summarize
$result.results.length  // 2
```
