# Content acquisition (to port later)

The [Prompts](../README.md#prompts) feature operates on **text you provide**. Some workflow app additionally ships a set of *content-acquisition tools* that fetch external content and feed it into a prompt. These are **not** ported  yet. This document inventories them so they can be added later — ideally in a separate ingestion project that hands the resulting text to a [`PromptRunner`](Classes/PromptRunner.md).

## The shape they all share

Every one of these is the same shape: **acquire text → run a prompt on it**.

```4d
var $transcript:=/* fetch from somewhere */
var $summary:=$runner.run("youtube_summary"; $transcript).text
```

So none of them require changes to the Prompt classes — they are *input providers* that produce a Text. A natural 4D design is one small class per source exposing a function that returns Text (e.g. `cs.xxx.YouTube.new().transcript($url)`).

## tools

| tool / flag | What it does | External dependency | Paired prompts |
|--------------------|--------------|---------------------|-----------------|
| `youtube` (`--youtube`, `--transcript`, `--comments`, `--metadata`) | Fetch a video/playlist transcript, comments, or metadata | **yt-dlp** (binary) for transcripts; **YouTube Data API key** for comments/metadata | `youtube_summary`, `create_video_chapters`, `extract_videoid` |
| `jina` (`--scrape_url`, `--scrape_question`) | Scrape a web page to markdown; web-search a question | **Jina AI** API | article/analysis prompts |
| `spotify` (`--spotify`) | Grab podcast / episode metadata | **Spotify** API | summarization prompts |
| `converter` / `--readability` | Convert HTML into clean, readable markdown | — (pure transform) | any |
| transcription (`--transcribe-file`, `--split-media-file`) | Transcribe an audio/video file to text; split files >25 MB | transcription model; **ffmpeg** for splitting | summarization prompts |
| `--attachment` | Attach a file/URL (image, etc.) to the message | — | vision prompts |

## Recommended integration 

1. Build each provider as a tiny, self-contained class returning Text (or a Blob for media), e.g. `YouTube.transcript($url)`, `WebScraper.toMarkdown($url)`.
2. Keep secrets (API keys) out of the classes — read them from the environment or a settings object, mirroring how [OpenAI](Classes/OpenAI.md) resolves `OPENAI_API_KEY`.
3. Feed the result straight into a prompt or chain:
   ```4d
   var $text:=cs.xxx.YouTube.new().transcript($url)
   var $summary:=$runner.run("youtube_summary"; $text).text
   ```
4. Since these depend on external binaries/services (yt-dlp, ffmpeg, Jina, Spotify), they fit well in a **separate ingestion project** rather than the core component, keeping AIKit dependency-free.
