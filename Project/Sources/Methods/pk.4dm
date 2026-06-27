//%attributes = {"invisible":true}
// PromptKit CLI entry point — runs a prompt by name and emits the result to the
// system standard output. Driven by the `pk` shell CLI (see cli/pk).
//
// The CLI passes a JSON control payload through --user-param. It is either an inline
// JSON string or the POSIX path of a JSON file (preferred, to avoid shell length/quoting
// limits on large inputs). Recognised keys:
//   prompt     : Text   - prompt name to apply
//   inputFile  : Text   - POSIX path to a file holding the input (preferred)
//   input      : Text   - inline input (used when inputFile is absent)
//   cwd        : Text   - POSIX path of the caller's working directory (for store lookup)
//   store      : Text   - explicit prompt store folder (overrides cwd lookup)
//   model      : Text   - model override
//   strategy   : Text   - strategy name or literal strategy prompt
//   context    : Text   - context name or literal context text
//   session    : Text   - session name (persistent history)
//   provider   : Text   - AIKit provider name, or an http(s):// base URL
//   variables  : Object - template variables
//   list       : Bool   - list available prompt names instead of running
//   raw        : Bool   - render the composed prompt instead of calling the model
//   nonce      : Text   - marker token used to frame the output on stdout
//
// Output protocol (everything goes through LOG EVENT to stdout so the CLI can pick it
// out of tool4d's own diagnostics):
//   <nonce>:OUT:BEGIN
//   <payload, possibly multi-line>
//   <nonce>:OUT:END
//   <nonce>:EXIT:<code>   (0 = success, non-zero = failure)

var $param : Text
Get database parameter(User param value; $param)

var $ctrl : Object:=Null
If ((Length($param)>0) && (Substring($param; 1; 1)="/"))
	var $ctrlFile : 4D.File:=Try(File($param; fk posix path))
	If (($ctrlFile#Null) && ($ctrlFile.exists))
		$ctrl:=Try(JSON Parse($ctrlFile.getText()))
	End if
End if
If ($ctrl=Null)
	$ctrl:=Try(JSON Parse($param))  // inline JSON
End if
If (($ctrl=Null) || (Value type($ctrl)#Is object))
	$ctrl:={prompt: $param}  // fallback: the whole param is a prompt name
End if

var $nonce : Text:=String($ctrl.nonce)
If ($nonce="")
	$nonce:="PK"
End if

var $exit : Integer:=0
var $payload : Text:=""

Try
	// MARK:- resolve the prompt store
	var $store : cs.PromptStore
	If (String($ctrl.store)#"")
		$store:=cs.PromptStore.new(Folder($ctrl.store; fk posix path))
	Else
		// prompts in CWD, else Resources/prompts in CWD, else ~/.promptKit/prompts
		var $candidates : Collection:=[]
		var $cwd : Text:=String($ctrl.cwd)
		If ($cwd#"")
			$candidates.push(Folder($cwd; fk posix path).folder("prompts"))
			$candidates.push(Folder($cwd; fk posix path).folder("Resources").folder("prompts"))
		End if
		$candidates.push(Folder(fk home folder).folder(".promptKit").folder("prompts"))

		var $picked : 4D.Folder:=$candidates[$candidates.length-1]
		var $candidate : 4D.Folder
		For each ($candidate; $candidates)
			If ($candidate.exists)
				$picked:=$candidate
				break
			End if
		End for each
		$store:=cs.PromptStore.new($picked)
	End if

	// MARK:- read the input
	var $input : Text:=""
	If (String($ctrl.inputFile)#"")
		var $inputFile : 4D.File:=Try(File($ctrl.inputFile; fk posix path))
		If (($inputFile#Null) && ($inputFile.exists))
			$input:=$inputFile.getText()
		End if
	Else
		$input:=String($ctrl.input)
	End if

	// MARK:- per-call options
	var $options : Object:={}
	If (String($ctrl.strategy)#"")
		$options.strategy:=$ctrl.strategy
	End if
	If (String($ctrl.context)#"")
		$options.context:=$ctrl.context
	End if
	If (String($ctrl.session)#"")
		$options.session:=$ctrl.session
	End if
	If (Value type($ctrl.variables)=Is object)
		$options.variables:=$ctrl.variables
	End if

	Case of
		// MARK:- list available prompts
		: ($ctrl.list=True)
			$payload:=$store.list().join("\n")

		// MARK:- render the composed prompt without calling the model
		: ($ctrl.raw=True)
			var $prompt : cs.Prompt:=$store.get(String($ctrl.prompt))
			var $messages : Collection:=$prompt.buildMessages($input; $options.variables)
			var $previewRunner : cs.PromptRunner:=cs.PromptRunner.new(Null; $store)
			var $system : Text:=$previewRunner._composeSystem($messages[0].content; $options)
			$payload:="### system\n"+$system+"\n\n### user\n"+$messages[1].content

		// MARK:- run the prompt against the model
		Else
			If (String($ctrl.prompt)="")
				throw(1; "No prompt name given")
			End if

			// Resolve the AI client from the provider:
			//   - empty        -> default OpenAI; the API key is read from ~/.openai when present
			//   - http(s)://…  -> an OpenAI-compatible endpoint, used as the client baseURL
			//   - other text   -> a named AIKit provider (resolved by OpenAIProviders)
			// The ~/.openai key file is used ONLY for the default OpenAI provider.
			var $providerName : Text:=String($ctrl.provider)
			var $client : cs.AIKit.OpenAI
			Case of
				: ($providerName="")
					$client:=cs.AIKit.OpenAI.new()
					If ((Length($client.apiKey)=0) && (Folder(fk home folder).file(".openai").exists))
						var $key : Text:=Folder(fk home folder).file(".openai").getText()
						$client.apiKey:=Replace string(Replace string($key; Char(13); ""); Char(10); "")
					End if
				: ((Position("http://"; $providerName)=1) || (Position("https://"; $providerName)=1))
					$client:=cs.AIKit.OpenAI.new()
					$client.baseURL:=$providerName
				Else
					var $providers : cs.AIKit.OpenAIProviders:=cs.AIKit.OpenAIProviders.new()
					var $providerData : Object:=$providers.get($providerName)
					If ($providerData=Null)
						throw(1; "Unknown provider: \""+$providerName+"\"")
					End if
					$client:=cs.AIKit.OpenAI.new($providerData)
			End case

			var $runner : cs.PromptRunner:=cs.PromptRunner.new($client; $store)
			If (String($ctrl.model)#"")
				$runner.model:=String($ctrl.model)
			End if

			var $result : cs.PromptResult:=$runner.run(String($ctrl.prompt); $input; $options)
			If ($result.success)
				$payload:=$result.text
			Else
				$exit:=1
				$payload:=PK_errorsToText($result.errors)
			End if
	End case

Catch
	$exit:=1
	$payload:=PK_errorsToText(Last errors)
End try

// MARK:- emit the framed result on the system standard output.
// LOG EVENT does not append a newline, so the whole block (markers + payload) is
// built with explicit line breaks and emitted in a single call. The CLI extracts
// the payload between the BEGIN/END markers and reads the EXIT code.
var $eol : Text:=Char(10)
var $block : Text:=$nonce+":OUT:BEGIN"+$eol
$block:=$block+$payload+$eol
$block:=$block+$nonce+":OUT:END"+$eol
$block:=$block+$nonce+":EXIT:"+String($exit)+$eol
LOG EVENT(Into system standard outputs; $block; Information message)

QUIT 4D
