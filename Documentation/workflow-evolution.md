# From chains to workflows (evolution)

> **Status: design note, not implemented.** This describes how today's linear
> [`PromptChain`](Classes/PromptChain.md) can grow into a general **workflow**, and how
> *chain / pipeline* and *workflow* can live side by side rather than compete.

## Where we are today

A [`PromptChain`](Classes/PromptChain.md) is a **linear pipeline**: an ordered list of prompt
steps where each step's output text is piped into the next, stopping at the first failure.

```
input ──▶ [extract_wisdom] ──▶ [summarize] ──▶ [translate] ──▶ output
```

Every node is the same kind of thing (one LLM prompt call), and flow is strictly sequential.
That covers a large share of real use, and it should stay — it's simple to read and reason about.

## The idea: a workflow is a chain with richer nodes and edges

A **workflow** generalises the chain on two axes:

- **Node types** — not only "run a prompt", but also: transform text in 4D code, *fetch* content
  (a YouTube transcript, a scraped page — see [content acquisition](content-acquisition.md)),
  call a tool, branch on a condition, or map a step over a collection.
- **Topology** — not only a straight line, but branches, fan-out / fan-in, and loops.

The key design choice that lets them coexist: **a chain is just a workflow whose nodes are all
prompt steps wired in a line.** So we don't replace `PromptChain` — we factor out the piece they
share and let `PromptChain` become a thin, friendly façade over the general engine.

## The unifying abstraction: a `Step`

Introduce a small step contract that both the chain and the workflow execute:

```4d
// conceptual — every node implements this
Function run($input : Variant; $ctx : cs.WorkflowContext) : cs.StepResult
```

- `$input` — the value coming in (text from the previous step, or the initial input).
- `$ctx` — a shared **context** threaded through the whole run: template `variables`, the active
  `strategy` / `context`, an optional `session`, the `PromptRunner`, and a scratch `bag` for
  inter-step data. This is exactly today's `run()` options, promoted to a first-class object.
- returns a `StepResult` (`output`, `success`, `errors`) — a generalisation of
  [`PromptResult`](Classes/PromptResult.md).

### Candidate node types

| Step | Role | Notes |
|------|------|-------|
| `PromptStep` | run a named prompt | wraps a prompt + options; this is what chains use today |
| `TransformStep` | run a `4D.Function` on the value | pure 4D, no LLM (trim, regex, JSON shape, join) |
| `SourceStep` | produce text from an external source | YouTube transcript, scraped URL, file — the [content-acquisition](content-acquisition.md) tools as nodes |
| `ToolStep` | call a registered tool / method | side effects, lookups |
| `BranchStep` | pick the next step from a condition | `Formula` returning a branch key |
| `MapStep` | run a sub-step over each item of a collection | fan-out, then join |
| `WorkflowStep` | embed a whole workflow (or chain) as one node | composition |

## How chain / pipeline and workflow coexist

```
                 ┌─────────────────────────────────────────┐
   Prompt        │ Workflow  (graph of Steps)               │
   (unit)        │   ├─ PromptStep                          │
                 │   ├─ SourceStep / TransformStep / Tool   │
   PromptChain   │   ├─ BranchStep / MapStep                │
   (linear  ◀────┼── └─ WorkflowStep (embed a chain/wf)     │
    pipeline)    └─────────────────────────────────────────┘
```

- **`PromptChain` stays** as the ergonomic, linear, all-prompt API
  (`$runner.chain([...])`, `.newChain().prompt(...).prompt(...)`).
- **`Workflow`** is the general engine. Internally `PromptChain.run` builds a linear list of
  `PromptStep`s and hands them to the same executor.
- They **nest both ways**: a `Workflow` can contain a chain as a `WorkflowStep`, and a chain step
  could itself be any `Step`. A pipeline is the degenerate workflow; a workflow can orchestrate
  several pipelines.

This means no rename and no breakage: chains are the 80 % case, workflows are the escape hatch.

## A future workflow, sketched

```4d
// fetch a transcript, summarise it, and translate only if it's long  (illustrative)
var $wf:=$runner.newWorkflow()
$wf.source("transcript"; Formula(cs.AIKit.YouTube.new().transcript($1)))  // SourceStep
$wf.prompt("summarize")                                                    // PromptStep
$wf.branch(Formula(Length($1)>2000) ? "translate" : "done")               // BranchStep
$wf.prompt("translate"; {variables: {lang: "French"}}).as("translate")
$wf.end("done")

var $res:=$wf.run("https://youtu.be/…")
// $res.output, $res.success, $res.steps (each StepResult), $res.bag
```

The same `WorkflowContext` (variables, strategy, context, session) flows through every node, so
strategies/sessions work in a workflow exactly as they do in a single `run`.

## Suggested phased path (each phase ships independently, backward compatible)

1. **Extract `Step` + `WorkflowContext` + `StepResult`** and refactor `PromptChain` to run on
   them internally. Pure refactor, no public API change.
2. **Add `TransformStep` and `SourceStep`** — lets non-LLM and content-acquisition nodes appear in
   an otherwise linear flow (still a pipeline, now with mixed node types).
3. **Add `Workflow` + `BranchStep` / `MapStep`** with a small graph executor for non-linear flows.
4. **Add `WorkflowStep`** for nesting, and expose `newWorkflow()` on `PromptRunner`.

## Naming summary

| Concept | Class | Scope |
|---------|-------|-------|
| reusable unit | [`Prompt`](Classes/Prompt.md) | one system + user template |
| linear composition | [`PromptChain`](Classes/PromptChain.md) (a.k.a. *pipeline*) | all-prompt, sequential |
| general composition | `Workflow` *(future)* | typed nodes, branches, nesting |
| shared run state | `WorkflowContext` *(future)* | variables, strategy, context, session |

Keep `Prompt` as the atom, `PromptChain` as the linear sugar, and add `Workflow` as the superset —
they compose, they don't replace each other.
