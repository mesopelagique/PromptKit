// A reusable AI prompt : a system prompt and an optional user template.

// Prompt name (the folder name in the prompt store).
property name : Text
// System prompt (content of system.md).
property system : Text
// Optional user template (content of user.md). May be empty.
property user : Text
// Frontmatter metadata (e.g. from a VS Code .prompt.md file: description, mode, model, tools). {} when none.
property metadata : Object:={}

Class constructor($data : Object)
	If ($data=Null:C1517)
		return
	End if
	This:C1470.name:=String:C10($data.name)
	This:C1470.system:=String:C10($data.system)
	This:C1470.user:=String:C10($data.user)
	If (Value type:C1509($data.metadata)=Is object:K8:27)
		This:C1470.metadata:=$data.metadata
	End if

	// Convenience accessor for the frontmatter description (if any).
Function get description : Text
	return String:C10(This:C1470.metadata.description)

	// Build the chat messages for this prompt given an input and optional template variables.
	// Returns a collection of {role; content} ready for chat.completions.create.
Function buildMessages($input : Text; $variables : Object) : Collection
	var $vars : Object:=($variables=Null:C1517) ? {} : OB Copy:C1225($variables)
	If ($vars.input=Null:C1517)
		$vars.input:=$input
	End if

	var $systemContent : Text:=This:C1470._substitute(This:C1470.system; $vars)

	var $userContent : Text
	Case of
		: (Length:C16(String:C10(This:C1470.user))=0)
			// No user template: the input is sent as the user message.
			$userContent:=$input
		: ((Position:C15("{{"; This:C1470.user)>0) || (Position:C15("${"; This:C1470.user)>0))
			// Templated user message: substitute {{input}} / ${input:...} and any provided variables.
			$userContent:=This:C1470._substitute(This:C1470.user; $vars)
		Else
			// Static user template: prepend it to the input.
			$userContent:=This:C1470.user+"\n"+$input
	End case

	return [{role: "system"; content: $systemContent}; {role: "user"; content: $userContent}]

	// Substitute template variables in $text.
	// Supports both the {{key}} form and the VS Code ${input:key} / ${input:key:placeholder} / ${key} forms.
Function _substitute($text : Text; $vars : Object) : Text
	If ($text=Null:C1517)
		return ""
	End if
	var $vars2 : Object:=($vars=Null:C1517) ? {} : $vars
	var $result : Text:=String:C10($text)

	// {{key}} form
	var $key : Text
	For each ($key; $vars2)
		$result:=Replace string:C233($result; "{{"+$key+"}}"; String:C10($vars2[$key]))
	End for each

	// VS Code ${...} form
	$result:=This:C1470._injectVSCodeVariables($result; $vars2)

	return $result

	// Resolve VS Code-style ${...} variable references against $vars.
	// ${input:name} / ${input:name:placeholder} -> $vars[name] (or placeholder); ${input} -> $vars.input;
	// ${name} -> $vars[name]. Unresolved references are left untouched.
Function _injectVSCodeVariables($text : Text; $vars : Object) : Text
	var $result : Text:=String:C10($text)
	If (Position:C15("${"; $result)=0)
		return $result
	End if

	var $searchFrom : Integer:=1
	var $guard : Integer:=0
	var $open : Integer:=Position:C15("${"; $result; $searchFrom)
	While (($open>0) && ($guard<10000))
		$guard+=1
		var $close : Integer:=Position:C15("}"; $result; $open+2)
		If ($close=0)
			break
		End if
		var $token : Text:=Substring:C12($result; $open; $close-$open+1)
		var $replacement : Variant:=This:C1470._resolveVSCodeToken($token; $vars)
		Case of
			: ($replacement#Null:C1517)
				$result:=Substring:C12($result; 1; $open-1)+String:C10($replacement)+Substring:C12($result; $close+1)
				$searchFrom:=$open+Length:C16(String:C10($replacement))
			Else
				$searchFrom:=$close+1  // leave unresolved reference untouched
		End case
		$open:=Position:C15("${"; $result; $searchFrom)
	End while
	return $result

	// Resolve a single ${...} token. Returns the replacement Text, or Null when it cannot be resolved.
Function _resolveVSCodeToken($token : Text; $vars : Object) : Variant
	If (Length:C16($token)<3)
		return Null:C1517
	End if
	var $inner : Text:=Substring:C12($token; 3; Length:C16($token)-3)  // strip ${ and }
	var $parts : Collection:=Split string:C1554($inner; ":")
	If ($parts.length=0)
		return Null:C1517
	End if

	If ($parts[0]="input")
		If ($parts.length=1)
			// ${input} -> the main input
			If ($vars.input#Null:C1517)
				return String:C10($vars.input)
			End if
			return Null:C1517
		End if
		var $name : Text:=$parts[1]
		If (($name#"") && ($vars[$name]#Null:C1517))
			return String:C10($vars[$name])
		End if
		If ($parts.length>=3)
			return $parts.slice(2).join(":")  // ${input:name:placeholder} fallback
		End if
		return Null:C1517
	End if

	// ${name} -> from vars if provided (e.g. selection/file supplied by the caller)
	If ($vars[$inner]#Null:C1517)
		return String:C10($vars[$inner])
	End if
	return Null:C1517
