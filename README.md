# PromptKit

PromptKit is a 4D toolkit for running reusable prompts, chaining them into workflows, and composing strategy, context, and session history around AI calls.

## Prompts

Prompts are reusable, named instructions that you can run against any input and **chain** together, piping the output of one operation into the next.

Each prompt is either a folder containing a `system.md` (the system prompt) and an optional `user.md` template, or a single `<name>.prompt.md` file. A library of prompts is bundled vy default in the base `Resources/prompts` folder.

### Running a prompt

Create a [`PromptRunner`](Documentation/Classes/PromptRunner.md) from an `OpenAI` client, then run a prompt by name. The result behaves like any AIKit result (`success`, `errors`) and exposes the produced `text`.

```4d
var $client:=cs.AIKit.OpenAI.new("your api key")
var $runner:=cs.PromptKit.PromptRunner.new($client)

var $result:=$runner.run("summarize"; $inputText)
// $result.text / $result.success / $result.errors
```

You can override the model (per runner or per call) and pass template variables. Variables work with both the mustache `{{lang}}` form and the VS Code `${input:lang}` form:

```4d
$runner.model:="gpt-4o"
var $result:=$runner.run("translate"; $inputText; {variables: {lang: "French"}})
```

### Chaining prompts

Chain several prompts so the output of each step becomes the input of the next. The chain stops at the first failing step.

```4d
// from a list of prompt names
var $result:=$runner.chain(["extract_wisdom"; "summarize"]).run($inputText)

// or build it fluently
var $result:=$runner.newChain().prompt("extract_wisdom").prompt("summarize").run($inputText)

// $result.text     -> final output
// $result.outputs  -> collection of each step's output
// $result.results  -> collection of PromptResult
```

### Strategies

A [strategy](Documentation/Classes/Strategy.md) is a reasoning instruction (e.g. Chain-of-Thought) prepended to the system prompt. One is bundled in `Resources/strategies`, you can your own inside your `Resources/strategies` database folder.

```4d
var $result:=$runner.run("summarize"; $inputText; {strategy: "cot"})

$runner.strategies.list()  // ["cot"]
```

You can also pass strategy prompt text directly: `{strategy: "Think step by step."}`.

### Contexts

A context is extra text (background, role, constraints…) prepended to the system prompt. Pass it by name (resolved from a [`ContextStore`](Documentation/Classes/ContextStore.md)) or inline:

```4d
var $result:=$runner.run("summarize"; $inputText; {context: "You answer for a French audience."})
```

The composed system prompt order is: **strategy → context → prompt**.

### Sessions

A [session](Documentation/Classes/Session.md) keeps a persistent conversation history across runs, so the model remembers previous turns.

```4d
var $session:=$runner.session("my-chat")   // loaded from / saved to the sessions folder
$runner.run("summarize"; "Here is the document..."; {session: $session})
$runner.run("answer_question"; "What were the key points?"; {session: $session})

$session.reset()  // clear and delete the persisted history
```

### Using your own prompts

By default prompts are loaded from `Resources/prompts`. Point a [`PromptStore`](Documentation/Classes/PromptStore.md) at any folder to use your own:

```4d
var $store:=cs.PromptKit.PromptStore.new(Folder("/path/to/my/prompts"))
var $runner:=cs.PromptKit.PromptRunner.new($client; $store)
$store.list()  // available prompt names
```

A prompt can be either a folder (`<name>/system.md`) or a single [VS Code `<name>.prompt.md` file](https://code.visualstudio.com/docs/agent-customization/prompt-files). For `.prompt.md` files the YAML frontmatter is stripped from the AI content and kept on `$prompt.metadata` (and `$result.metadata`):

```4d
var $prompt:=$store.get("react-form")
$prompt.metadata.model  // e.g. "GPT-4o" — preserved for inspection, not auto-applied
```

### Command line (`pk`)

A small [Fabric](https://github.com/danielmiessler/Fabric)-like CLI runs a prompt by name
on input from a file, an argument, or a pipe, executing the [`pk`](Project/Sources/Methods/pk.4dm)
method via `tool4d` and printing the result:

```bash
echo "long text…" | pk summarize
pk translate -f notes.txt -v lang_code=fr-fr
pk --list

# set a default provider+model once, then omit the flags:
pk config set provider=http://127.0.0.1:11434/v1 model=gemma4
echo "hello" | pk translate -v lang_code=fr-fr
```

Install it with a symlink (`./cli/pk --install`) and see [cli/README.md](cli/README.md) for
the full reference. Prompts are resolved relative to your working directory
(`./prompts` → `./Resources/prompts` → `~/.promptKit/prompts`); default provider/model come
from `--provider`/`--model`, the `PK_PROVIDER`/`PK_MODEL` env, or a `pk config` file.

### Find prepared prompt and strategy libraries

If you want ready-to-use material, these repositories are good starting points:

- Prompt patterns: [Fabric patterns](https://github.com/danielmiessler/Fabric/tree/main/data/patterns)
- Prompt collections: [awesome-prompts](https://github.com/ai-boost/awesome-prompts)
- Strategies: [Fabric strategies](https://github.com/danielmiessler/Fabric/tree/main/data/strategies)

See [PromptRunner](Documentation/Classes/PromptRunner.md), [Prompt](Documentation/Classes/Prompt.md), [PromptChain](Documentation/Classes/PromptChain.md), [PromptStore](Documentation/Classes/PromptStore.md), [Strategy](Documentation/Classes/Strategy.md), [ContextStore](Documentation/Classes/ContextStore.md) and [Session](Documentation/Classes/Session.md) for details.


## Roadmap

> Content acquisition (fetching YouTube transcripts, scraping URLs, transcribing audio, etc.) is **not** included — prompts operate on text you provide. See [content acquisition](Documentation/content-acquisition.md).

> Chains are linear today; see [from chains to workflows](Documentation/workflow-evolution.md) for how this could grow into branching/graph **workflows** while keeping the chain API.

## License

See the [LICENSE](LICENSE.md) file for details

