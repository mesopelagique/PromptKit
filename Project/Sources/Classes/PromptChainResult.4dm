// Result of running a chain of prompts. Holds each step's result and output.

// Collection of cs.PromptResult, one per executed step.
property results : Collection:=[]
// Collection of Text outputs, one per executed step.
property outputs : Collection:=[]

	// The final output text of the chain.
Function get text : Text
	If (This:C1470.outputs.length=0)
		return ""
	End if
	return String:C10(This:C1470.outputs.last())

	// True if every executed step succeeded.
Function get success : Boolean
	If (This:C1470.results.length=0)
		return False:C215
	End if
	return Not:C34(This:C1470.results.some(Formula:C1597(Not:C34($1.value.success))))

	// Errors from the first failed step (if any).
Function get errors : Collection
	var $failed : Variant:=This:C1470.results.find(Formula:C1597(Not:C34($1.value.success)))
	If ($failed=Null:C1517)
		return []
	End if
	return $failed.errors

	// Append a step result to the chain result.
Function _push($result : cs:C1710.PromptResult)
	This:C1470.results.push($result)
	This:C1470.outputs.push($result.text)
