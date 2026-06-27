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
var $r:=Get database parameter:C643(User param value:K37:94; $param)

var $ctrl : Object:=Null:C1517
If ((Length:C16($param)>0) && (Substring:C12($param; 1; 1)="/"))
	var $ctrlFile : 4D:C1709.File:=Try(File:C1566($param; fk posix path:K87:1))
	If (($ctrlFile#Null:C1517) && ($ctrlFile.exists))
		$ctrl:=Try(JSON Parse:C1218($ctrlFile.getText()))
	End if 
End if 
If ($ctrl=Null:C1517)
	$ctrl:=Try(JSON Parse:C1218($param))  // inline JSON
End if 
If (($ctrl=Null:C1517) || (Value type:C1509($ctrl)#Is object:K8:27))
	$ctrl:={prompt: $param}  // fallback: the whole param is a prompt name
End if 

var $nonce : Text:=String:C10($ctrl.nonce)
If ($nonce="")
	$nonce:="PK"
End if 

var $exit : Integer:=0
var $payload : Text:=""

Try
	// MARK:- resolve the prompt store
	var $store : cs:C1710.PromptStore
	If (String:C10($ctrl.store)#"")
		$store:=cs:C1710.PromptStore.new(Folder:C1567($ctrl.store; fk posix path:K87:1))
	Else 
		// prompts in CWD, else Resources/prompts in CWD, else ~/.promptKit/prompts
		var $candidates : Collection:=[]
		var $cwd : Text:=String:C10($ctrl.cwd)
		If ($cwd#"")
			$candidates.push(Folder:C1567($cwd; fk posix path:K87:1).folder("prompts"))
			$candidates.push(Folder:C1567($cwd; fk posix path:K87:1).folder("Resources").folder("prompts"))
		End if 
		$candidates.push(Folder:C1567(fk home folder:K87:24).folder(".promptKit").folder("prompts"))
		$candidates.push(Folder:C1567(fk resources folder:K87:11).folder("prompts"))
		
		var $picked : 4D:C1709.Folder:=$candidates[$candidates.length-1]
		var $candidate : 4D:C1709.Folder
		For each ($candidate; $candidates)
			If ($candidate.exists)
				$picked:=$candidate
				break
			End if 
		End for each 
		$store:=cs:C1710.PromptStore.new($picked)
	End if 
	
	// MARK:- read the input
	var $input : Text:=""
	If (String:C10($ctrl.inputFile)#"")
		var $inputFile : 4D:C1709.File:=Try(File:C1566($ctrl.inputFile; fk posix path:K87:1))
		If (($inputFile#Null:C1517) && ($inputFile.exists))
			$input:=$inputFile.getText()
		End if 
	Else 
		$input:=String:C10($ctrl.input)
	End if 
	
	// MARK:- per-call options
	var $options : Object:={}
	If (String:C10($ctrl.strategy)#"")
		$options.strategy:=$ctrl.strategy
	End if 
	If (String:C10($ctrl.context)#"")
		$options.context:=$ctrl.context
	End if 
	If (String:C10($ctrl.session)#"")
		$options.session:=$ctrl.session
	End if 
	If (Value type:C1509($ctrl.variables)=Is object:K8:27)
		$options.variables:=$ctrl.variables
	End if 
	
	Case of 
			// MARK:- list available prompts
		: ($ctrl.list=True:C214)
			$payload:=$store.list().join("\n")
			
			// MARK:- render the composed prompt without calling the model
		: ($ctrl.raw=True:C214)
			var $prompt : cs:C1710.Prompt:=$store.get(String:C10($ctrl.prompt))
			var $messages : Collection:=$prompt.buildMessages($input; $options.variables)
			var $previewRunner : cs:C1710.PromptRunner:=cs:C1710.PromptRunner.new(Null:C1517; $store)
			var $system : Text:=$previewRunner._composeSystem($messages[0].content; $options)
			$payload:="### system\n"+$system+"\n\n### user\n"+$messages[1].content
			
			// MARK:- run the prompt against the model
		Else 
			If (String:C10($ctrl.prompt)="")
				throw:C1805(1; "No prompt name given")
			End if 
			
			// Resolve the AI client from the provider:
			//   - empty        -> default OpenAI; the API key is read from ~/.openai when present
			//   - http(s)://…  -> an OpenAI-compatible endpoint, used as the client baseURL
			//   - other text   -> a named AIKit provider (resolved by OpenAIProviders)
			// The ~/.openai key file is used ONLY for the default OpenAI provider.
			var $providerName : Text:=String:C10($ctrl.provider)
			var $client : cs:C1710.AIKit.OpenAI
			Case of 
				: ($providerName="")
					$client:=cs:C1710.AIKit.OpenAI.new()
					If ((Length:C16($client.apiKey)=0) && (Folder:C1567(fk home folder:K87:24).file(".openai").exists))
						var $key : Text:=Folder:C1567(fk home folder:K87:24).file(".openai").getText()
						$client.apiKey:=Replace string:C233(Replace string:C233($key; Char:C90(13); ""); Char:C90(10); "")
					End if 
				: ((Position:C15("http://"; $providerName)=1) || (Position:C15("https://"; $providerName)=1))
					$client:=cs:C1710.AIKit.OpenAI.new()
					$client.baseURL:=$providerName
				Else 
					var $providers : cs:C1710.AIKit.OpenAIProviders:=cs:C1710.AIKit.OpenAIProviders.new()
					var $providerData : Object:=$providers.get($providerName)
					If ($providerData=Null:C1517)
						throw:C1805(1; "Unknown provider: \""+$providerName+"\"")
					End if 
					$client:=cs:C1710.AIKit.OpenAI.new($providerData)
			End case 
			
			var $runner : cs:C1710.PromptRunner:=cs:C1710.PromptRunner.new($client; $store)
			If (String:C10($ctrl.model)#"")
				$runner.model:=String:C10($ctrl.model)
			End if 
			
			var $result : cs:C1710.PromptResult:=$runner.run(String:C10($ctrl.prompt); $input; $options)
			If ($result.success)
				$payload:=$result.text
			Else 
				$exit:=1
				$payload:=PK_errorsToText($result.errors)
			End if 
	End case 
	
Catch
	$exit:=1
	$payload:=PK_errorsToText(Last errors:C1799)
End try

// MARK:- emit the framed result on the system standard output.
// LOG EVENT does not append a newline, so the whole block (markers + payload) is
// built with explicit line breaks and emitted in a single call. The CLI extracts
// the payload between the BEGIN/END markers and reads the EXIT code.
var $eol : Text:=Char:C90(10)
var $block : Text:=$nonce+":OUT:BEGIN"+$eol
$block:=$block+$payload+$eol
$block:=$block+$nonce+":OUT:END"+$eol
$block:=$block+$nonce+":EXIT:"+String:C10($exit)+$eol
LOG EVENT:C667(Into system standard outputs:K38:9; $block; Information message:K38:1)

QUIT 4D:C291
