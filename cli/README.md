# `pk` — the PromptKit CLI

A small [Fabric](https://github.com/danielmiessler/Fabric)-like command line front end
for PromptKit. You give it a **prompt name** and some **input** (a file, an argument, or
a pipe); it runs the prompt through a 4D method ([`pk`](../Project/Sources/Methods/pk.4dm))
inside the PromptKit project and prints the result. See the
[method reference](../Documentation/Methods/pk.md) for the 4D side.

Only the *prompts* part of Fabric is mirrored. Content acquisition (YouTube transcripts,
scraping, audio…) is intentionally **not** implemented — `pk` operates on text you give it.

```bash
echo "long article text…" | pk summarize
pk extract_wisdom -f transcript.txt
pk translate -t "Hello world" -v lang_code=fr-fr
pk --list
```

## How it works

```
input (file | -t text | stdin) ──► pk ──► tool4d ──► pk method ──► LOG EVENT ──► stdout
                                    │                    │
                                    │                    └─ PromptRunner → AIKit (OpenAI-compatible)
                                    └─ JSON control payload passed via --user-param
```

1. `pk` collects the input and your options into a small JSON **control file**.
2. It launches the PromptKit project with `tool4d`, passing the control file path through
   [`--user-param`](https://developer.4d.com/docs/commands/get-database-parameter). The
   `pk` method reads it with `Get database parameter(User param value; $param)`.
3. `pk` resolves the prompt store, runs the prompt, and emits the result with
   `LOG EVENT(Into system standard outputs; …; Information message)`, framed by a per-run
   marker so `pk` can separate it from tool4d's own diagnostics.

The result text goes to **stdout** (so you can pipe it), errors go to **stderr** with a
non-zero exit code.

## Prompt store resolution

The store is resolved **relative to the directory you run `pk` from** (not the PromptKit
install location), so you can keep a project's prompts next to the project:

1. `./prompts`
2. `./Resources/prompts`
3. `~/.promptKit/prompts`

The first one that exists wins. Override it with `--store DIR`. Each prompt is either a
`<name>/system.md` folder (with an optional `user.md`) or a single `<name>.prompt.md` file
(VS Code style, YAML frontmatter stripped). See the project README for the format.

## Install

`pk` lives in this repo and finds the PromptKit project relative to its own (real) location,
so installing is just a symlink — the script keeps working through the link.

```bash
# from the repo root
./cli/pk --install              # symlinks into /usr/local/bin (sudo if needed)
./cli/pk --install "$HOME/bin"  # …or into any directory on your PATH
```

Equivalent manual symlink:

```bash
ln -s "$(pwd)/cli/pk" /usr/local/bin/pk
# make sure the target dir is on your PATH, then:
pk --list
```

To uninstall: `rm /usr/local/bin/pk` (removes the link only).

## Runtime

By default `pk` auto-discovers `tool4d` installed by the
[4D-Analyzer](https://marketplace.visualstudio.com/items?itemName=4D.4d-analyzer) extension
(VS Code / Antigravity). Override it when needed:

```bash
export PK_4D="/path/to/tool4d.app/Contents/MacOS/tool4d"   # or a full 4D binary
# TOOL4D is also honoured (same meaning)
```

The override (`PK_4D`, then `TOOL4D`) is only used when it points to an **existing file**;
otherwise `pk` falls back to auto-discovery. Use a full 4D runtime
(`…/4D.app/Contents/MacOS/4D`) instead of `tool4d` if a prompt needs runtime features
`tool4d` lacks.

## Model, provider and API key

The model call is handled by [4D-AIKit](https://github.com/4d/4D-AIKit) (OpenAI-compatible).
`--provider` accepts either a name or a base URL:

| `--provider` value | Behaviour |
|---|---|
| *(omitted)* | Default **OpenAI**. The API key is read from `~/.openai` (a single line) when present. |
| `http(s)://…` | Used directly as the client **base URL** (any OpenAI-compatible API, e.g. a local LLM or a gateway). |
| any other text | A **named** AIKit provider, resolved through `OpenAIProviders`. Unknown names error out. |

The `~/.openai` key file is **only** used for the default OpenAI provider — never for a named
provider or a base-URL provider (configure their credentials in AIKit instead). Pick a model
with `--model NAME` (default: the runner's `gpt-4o-mini`).

```bash
pk summarize -f doc.txt                                   # default OpenAI (~/.openai key)
pk summarize -f doc.txt --provider http://127.0.0.1:11434/v1 --model llama3   # local LLM
pk summarize -f doc.txt --provider Mistral                # a named AIKit provider
```

## Options

| Option | Description |
|---|---|
| `<prompt-name>` | The prompt to apply (positional). |
| `-l, --list` | List available prompt names and exit. |
| `-f, --file FILE` | Read the input from `FILE`. |
| `-t, --text TEXT` | Use `TEXT` as the input. |
| `-m, --model MODEL` | Model to use. |
| `-s, --strategy NAME` | Strategy name or literal strategy prompt (e.g. `cot`). |
| `-c, --context TEXT` | Context name or literal context text. |
| `--session NAME` | Persistent session (conversation history). |
| `--provider NAME\|URL` | AIKit provider name, or an OpenAI-compatible base URL. |
| `--store DIR` | Prompt store folder (overrides the CWD lookup). |
| `-v, --var key=value` | Template variable. Repeatable. |
| `--raw` | Render the composed prompt instead of calling the model. |
| `-o, --output FILE` | Also write the result to `FILE`. |
| `--verbose` | Show tool4d diagnostics on stderr. |
| `--install [DIR]` | Symlink `pk` into `DIR` (default `/usr/local/bin`). |
| `-h, --help` | Show help. |

Input precedence when several are given: `-t/--text`, then `-f/--file`, then stdin.

## Examples

```bash
# Summarize a file
pk summarize -f article.txt

# Pipe and chain with other tools
pbpaste | pk extract_wisdom | pk summarize

# Use a reasoning strategy and an inline context
pk analyze_claims -s cot -c "Audience: French engineers." -f claims.md

# Keep a conversation going
pk summarize -f doc.md --session review
pk answer_question -t "What were the key risks?" --session review

# Inspect what would be sent, without spending tokens
pk summarize -f doc.md --raw

# Use your own prompts folder
pk my_prompt --store ./prompts -f input.txt
```
