# StrategyStore

Loads reasoning [strategies](Strategy.md) from a folder of JSON files (`{description, prompt}`). A library is bundled in the component's `Resources/strategies` folder.

## Properties

| Property Name | Type | Default Value | Description |
|---------------|------|---------------|-------------|
| `folder` | 4D.Folder | bundled `Resources/strategies` | Root folder containing one `<name>.json` per strategy. |
| `_cache` | Object | {} | Cache of already loaded strategies, keyed by name. |

## Constructor

**StrategyStore**(*folder* : 4D.Folder)

| Parameter | Type | Description |
|-----------|------|-------------|
| *folder* | 4D.Folder | Optional. Defaults to the bundled `Resources/strategies` folder. |

A `PromptRunner` exposes a ready-to-use store as `$runner.strategies`.

## Functions

### get()

**get**(*name* : Text) : [Strategy](Strategy.md)

Loads and returns a strategy by name (reading its `<name>.json`). Cached. **Throws** if not found.

### exists()

**exists**(*name* : Text) : Boolean

Returns `True` if a strategy with this name exists.

### list()

**list**() : Collection

Returns the sorted collection of available strategy names.

```4d
$runner.strategies.list()  // ["aot"; "cod"; "cot"; "ltm"; "reflexion"; ...]
```
