// Runs prompts against an OpenAI (or OpenAI-compatible) client, and chains them together.
// Supports strategies (reasoning prompts), contexts (extra system text) and sessions (persistent history).
//
// Usage:
//   var $runner:=cs.PromptKit.PromptRunner.new($client)
//   var $res:=$runner.run("summarize"; $inputText)
//   var $res:=$runner.run("summarize"; $inputText; {strategy: "cot"; context: "myContext"})
//   var $res:=$runner.chain(["extract_wisdom"; "summarize"]).run($inputText)

// The OpenAI client used to perform completions.
property client : cs:C1710.AIKit.OpenAI
// The prompt store used to resolve prompt names.
property store : cs:C1710.PromptStore
// The strategy store used to resolve strategy names.
property strategies : cs:C1710.StrategyStore
// The context store used to resolve context names.
property contexts : cs:C1710.ContextStore
// Folder where named sessions are persisted (may be Null when not writable).
property sessionsFolder : 4D:C1709.Folder
// Default model used when a call does not specify one.
property model : Text:="gpt-4o-mini"

Class constructor($client : cs:C1710.AIKit.OpenAI; $store : cs:C1710.PromptStore)
	This:C1470.client:=$client
	This:C1470.store:=($store#Null:C1517) ? $store : cs:C1710.PromptStore.new()
	This:C1470.strategies:=cs:C1710.StrategyStore.new()
	This:C1470.contexts:=cs:C1710.ContextStore.new()
	This:C1470.sessionsFolder:=This:C1470._defaultSessionsFolder()
	
	// Default sessions folder: the host data folder (writable). Null if unavailable.
Function _defaultSessionsFolder() : 4D:C1709.Folder
	return Try(Folder:C1567(fk data folder:K87:12; *).folder("PromptKit").folder("sessions"))
	
	// Run a single prompt against $input.
	// $options may contain:
	//   {variables: Object; parameters: OpenAIChatCompletionsParameters|Object;
	//    strategy: Text|Strategy|Object; context: Text|Object; session: Text|Session}
Function run($name : Text; $input : Text; $options : Object) : cs:C1710.PromptResult
	If ($options=Null:C1517)
		$options:={}
	End if 
	
	var $prompt : cs:C1710.Prompt:=This:C1470.store.get($name)
	var $messages : Collection:=$prompt.buildMessages($input; $options.variables)  // [system; user]
	
	var $systemMessage : Object:=$messages[0]
	var $userMessage : Object:=$messages[1]
	
	// Compose the system message: strategy + context + prompt system.
	$systemMessage.content:=This:C1470._composeSystem($systemMessage.content; $options)
	
	// Resolve an optional session (persistent history).
	var $session : cs:C1710.Session:=This:C1470._resolveSession($options.session)
	
	// Build the final message list: [system] + history + [user].
	var $finalMessages : Collection:=[$systemMessage]
	If ($session#Null:C1517)
		var $historic : Object
		For each ($historic; $session.messages)
			$finalMessages.push($historic)
		End for each 
	End if 
	$finalMessages.push($userMessage)
	
	var $parameters : cs:C1710.AIKit.OpenAIChatCompletionsParameters:=This:C1470._buildParameters($options)
	var $result:=This:C1470.client.chat.completions.create($finalMessages; $parameters)
	var $promptResult : cs:C1710.PromptResult:=cs:C1710.PromptResult.new($name; $result; $prompt.metadata)
	
	// Persist the exchange to the session when successful.
	If (($session#Null:C1517) && ($promptResult.success))
		$session.append($userMessage)
		$session.append($result.choice.message)
		$session.save()
	End if 
	
	return $promptResult
	
	// Build a chain from a collection of prompt names.
Function chain($names : Collection) : cs:C1710.PromptChain
	var $chain : cs:C1710.PromptChain:=cs:C1710.PromptChain.new(This:C1470)
	If ($names#Null:C1517)
		var $name : Text
		For each ($name; $names)
			$chain.prompt($name)
		End for each 
	End if 
	return $chain
	
	// Create an empty chain, to build fluently with .prompt(...).
Function newChain() : cs:C1710.PromptChain
	return cs:C1710.PromptChain.new(This:C1470)
	
	// Create (and auto-load) a named session persisted in the runner's sessions folder.
Function session($name : Text) : cs:C1710.Session
	return cs:C1710.Session.new($name; This:C1470.sessionsFolder)
	
	// MARK:- internal helpers
	
	// Compose the system message from strategy + context + the prompt system prompt.
Function _composeSystem($systemContent : Text; $options : Object) : Text
	var $sections : Collection:=[]
	
	var $strategyPrompt : Text:=This:C1470._resolveStrategyPrompt($options.strategy)
	If (Length:C16($strategyPrompt)>0)
		$sections.push($strategyPrompt)
	End if 
	
	var $contextContent : Text:=This:C1470._resolveContext($options.context)
	If (Length:C16($contextContent)>0)
		$sections.push($contextContent)
	End if 
	
	If (Length:C16(String:C10($systemContent))>0)
		$sections.push($systemContent)
	End if 
	
	return $sections.join("\n\n")
	
	// Resolve a strategy option to its prompt text. Accepts a name, a Strategy, an object, or raw text.
Function _resolveStrategyPrompt($strategy : Variant) : Text
	Case of 
		: ($strategy=Null:C1517)
			return ""
		: (Value type:C1509($strategy)=Is text:K8:3)
			If (This:C1470.strategies.exists($strategy))
				return This:C1470.strategies.get($strategy).prompt
			End if 
			return $strategy  // treat unknown text as a literal strategy prompt
		: (Value type:C1509($strategy)=Is object:K8:27)
			return String:C10($strategy.prompt)  // Strategy instance or {prompt: ...}
	End case 
	return ""
	
	// Resolve a context option to its text. Accepts a name, an object {content}, or raw text.
Function _resolveContext($context : Variant) : Text
	Case of 
		: ($context=Null:C1517)
			return ""
		: (Value type:C1509($context)=Is object:K8:27)
			return String:C10($context.content)
		: (Value type:C1509($context)=Is text:K8:3)
			If (This:C1470.contexts.exists($context))
				return This:C1470.contexts.get($context)
			End if 
			return $context  // treat unknown text as literal context content
	End case 
	return ""
	
	// Resolve a session option to a Session instance. Accepts a name or a Session.
Function _resolveSession($session : Variant) : cs:C1710.Session
	Case of 
		: ($session=Null:C1517)
			return Null:C1517
		: (Value type:C1509($session)=Is text:K8:3)
			return This:C1470.session($session)
		: (OB Instance of:C1731($session; cs:C1710.Session))
			return $session
	End case 
	return Null:C1517
	
	// Build chat completion parameters, merging $options.parameters with the runner default model.
Function _buildParameters($options : Object) : cs:C1710.AIKit.OpenAIChatCompletionsParameters
	var $raw : Variant:=$options.parameters
	var $parameters : cs:C1710.AIKit.OpenAIChatCompletionsParameters
	Case of 
		: (OB Instance of:C1731($raw; cs:C1710.AIKit.OpenAIChatCompletionsParameters))
			$parameters:=$raw
		: (Value type:C1509($raw)=Is object:K8:27)
			$parameters:=cs:C1710.AIKit.OpenAIChatCompletionsParameters.new($raw)
			If ($raw.model=Null:C1517)
				$parameters.model:=This:C1470.model
			End if 
		Else 
			$parameters:=cs:C1710.AIKit.OpenAIChatCompletionsParameters.new({})
			$parameters.model:=This:C1470.model
	End case 
	return $parameters
	