# PromptResult

The result of running a single [prompt](Prompt.md) through a [PromptRunner](PromptRunner.md). Wraps the underlying [OpenAIChatCompletionsResult](OpenAIChatCompletionsResult.md) and exposes the produced text.

## Properties

| Property Name | Type | Default Value | Description |
|---------------|------|---------------|-------------|
| `result` | [OpenAIChatCompletionsResult](OpenAIChatCompletionsResult.md) | - | The underlying chat completion result. |
| `prompt` | Text | - | The name of the prompt that produced this result. |
| `metadata` | Object | - | Frontmatter metadata of the prompt used (see [Prompt](Prompt.md)). |

## Computed properties

| Name | Type | Description |
|------|------|-------------|
| `text` | Text | The output text produced by the prompt. |
| `success` | Boolean | `True` if the underlying request succeeded. |
| `errors` | Collection | Collection of [OpenAIError](OpenAIError.md), if any. |

```4d
var $result:=$runner.run("summarize"; $inputText)
If ($result.success)
	var $summary:=$result.text
Else
	// $result.errors
End if
```
