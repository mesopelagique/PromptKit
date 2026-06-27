# PK_errorsToText (method)

Helper used by the [`pk`](pk.md) method to turn a collection of error objects into a single,
human-readable text block for the CLI.

**PK_errorsToText**(*errors* : Collection) : Text

| Parameter | Type | Description |
|-----------|------|-------------|
| *errors* | Collection | Error objects — AIKit `OpenAIError` (`message`, `errCode`) or 4D `Last errors`. |
| Function result | Text | One `pk: <message> (<errCode>)` line per error, joined by newlines. |

Each entry uses the error's `message` (falling back to `JSON Stringify` when absent) and appends
`errCode` in parentheses when present. Returns `"pk: unknown error"` for an empty/`Null`
collection.

```4d
$payload:=PK_errorsToText($result.errors)   // after a failed run
$payload:=PK_errorsToText(Last errors)       // inside a Catch block
```
