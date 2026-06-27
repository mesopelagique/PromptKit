# pk (method)

`pk` is the project method that backs the [`pk` command line tool](../../cli/README.md). It
runs a named [prompt](../Classes/Prompt.md) through a [PromptRunner](../Classes/PromptRunner.md)
and emits the result to the **system standard output** with
`LOG EVENT(Into system standard outputs; …; Information message)`.

It is meant to be launched as a **startup method** by `tool4d` (or a full 4D), not called from
your own code — for that, use [`PromptRunner`](../Classes/PromptRunner.md) directly.

```bash
"<tool4d>" --project="…/PromptKit.4DProject" --startup-method="pk" \
           --skip-onstartup --dataless --user-param="<control>"
```

The `pk` shell script builds the `--user-param` value and parses the framed output for you, so
in practice you just run:

```bash
echo "long text…" | pk summarize
pk translate -f notes.txt -v lang_code=fr-fr
pk --list
```

## Input — the `--user-param` control payload

The method reads its single parameter with
[`Get database parameter(User param value; $param)`](https://developer.4d.com/docs/commands/get-database-parameter).
`$param` is interpreted, in order, as:

1. a POSIX path to a JSON file (preferred — avoids shell length/quoting limits on large input),
2. an inline JSON string,
3. otherwise the whole value is taken as a prompt name.

Recognised JSON keys:

| Key | Type | Description |
|-----|------|-------------|
| `prompt` | Text | Prompt name to apply. |
| `inputFile` | Text | POSIX path to a file holding the input (preferred). |
| `input` | Text | Inline input (used when `inputFile` is absent). |
| `cwd` | Text | POSIX path of the caller's working directory (used for prompt-store lookup). |
| `store` | Text | Explicit prompt-store folder (overrides the `cwd` lookup). |
| `model` | Text | Model override (default: the runner's `gpt-4o-mini`). |
| `strategy` | Text | Strategy name or literal strategy prompt. |
| `context` | Text | Context name or literal context text. |
| `session` | Text | Session name (persistent conversation history). |
| `provider` | Text | AIKit provider name, or an `http(s)://` base URL. |
| `variables` | Object | Template variables (`{{key}}` / `${input:key}`). |
| `list` | Boolean | List available prompt names instead of running. |
| `raw` | Boolean | Render the composed prompt instead of calling the model. |
| `nonce` | Text | Marker token used to frame the output (see below). |

## Prompt store resolution

When `store` is not given, the store is resolved **relative to `cwd`** (the directory the CLI
was run from), taking the first that exists:

1. `<cwd>/prompts`
2. `<cwd>/Resources/prompts`
3. `~/.promptKit/prompts`

## Provider resolution

The AI client is built from `provider`:

| `provider` | Behaviour |
|---|---|
| *(empty)* | Default **OpenAI**. The API key is read from `~/.openai` (CR/LF trimmed) when the client has none. |
| `http(s)://…` | Used directly as the client **`baseURL`** — any OpenAI-compatible endpoint (local LLM, gateway, …). |
| any other text | A **named** AIKit provider via `OpenAIProviders`. An unknown name throws. |

> The `~/.openai` key file is used **only** for the default OpenAI provider. Named and
> base-URL providers must carry their own credentials (configured in AIKit).

## Output protocol

`LOG EVENT` does not append a newline, so `pk` writes the whole result as one framed block on
stdout. The CLI extracts the payload between the `BEGIN`/`END` markers and reads the exit code;
everything else on stdout/stderr (tool4d diagnostics) is ignored.

```
<nonce>:OUT:BEGIN
<payload — the result text, the prompt list, or an error message>
<nonce>:OUT:END
<nonce>:EXIT:<code>      # 0 = success, non-zero = failure
```

On failure the payload is a human-readable message built by
[`PK_errorsToText`](PK_errorsToText.md) from the AIKit/4D errors, and `<code>` is non-zero.

## Examples

Run, list and preview, expressed as the control payload the CLI generates:

```jsonc
// pk summarize  (input piped, default OpenAI)
{ "prompt": "summarize", "inputFile": "/tmp/pk.123/input.txt", "cwd": "/work", "nonce": "PK-…" }

// pk translate -v lang_code=fr-fr  against a local LLM
{ "prompt": "translate", "inputFile": "…", "cwd": "/work",
  "provider": "http://127.0.0.1:11434/v1", "model": "llama3",
  "variables": { "lang_code": "fr-fr" }, "nonce": "PK-…" }

// pk --list
{ "prompt": "", "cwd": "/work", "list": true, "nonce": "PK-…" }

// pk summarize --raw  (no API call)
{ "prompt": "summarize", "inputFile": "…", "cwd": "/work", "raw": true, "nonce": "PK-…" }
```

## See also

- [cli/README.md](../../cli/README.md) — the `pk` command reference and install steps.
- [PromptRunner](../Classes/PromptRunner.md) — run/chain prompts from your own 4D code.
- [PromptStore](../Classes/PromptStore.md) — prompt layouts and loading.
