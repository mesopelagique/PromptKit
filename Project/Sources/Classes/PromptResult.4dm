// Result of running a single prompt through a PromptRunner.

// Underlying chat completion result.
property result : cs:C1710.AIKit.OpenAIChatCompletionsResult
// Name of the prompt that produced this result.
property prompt : Text
// Frontmatter metadata of the prompt that produced this result (e.g. from a .prompt.md file).
property metadata : Object

Class constructor($prompt : Text; $result : cs:C1710.AIKit.OpenAIChatCompletionsResult; $metadata : Object)
	This:C1470.prompt:=$prompt
	This:C1470.result:=$result
	This:C1470.metadata:=$metadata
	
	// The output text produced by the prompt.
Function get text : Text
	If (This:C1470.result=Null:C1517)
		return ""
	End if 
	var $choice:=This:C1470.result.choice
	If (($choice=Null:C1517) || ($choice.message=Null:C1517))
		return ""
	End if 
	return String:C10($choice.message.text)
	
	// True if the underlying request succeeded.
Function get success : Boolean
	return (This:C1470.result#Null:C1517) && (This:C1470.result.success)
	
	// Collection of OpenAIError, if any.
Function get errors : Collection
	If (This:C1470.result=Null:C1517)
		return []
	End if 
	return This:C1470.result.errors
	