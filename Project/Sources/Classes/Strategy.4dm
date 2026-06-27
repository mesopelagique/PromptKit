// A reasoning strategy: a named prompt prepended to the system message.
// e.g. Chain-of-Thought, Tree-of-Thought.

// Strategy name (the json file name in the strategy store).
property name : Text
// Human readable description.
property description : Text
// The prompt prepended to the system message.
property prompt : Text

Class constructor($data : Object)
	If ($data=Null:C1517)
		return
	End if
	This:C1470.name:=String:C10($data.name)
	This:C1470.description:=String:C10($data.description)
	This:C1470.prompt:=String:C10($data.prompt)
