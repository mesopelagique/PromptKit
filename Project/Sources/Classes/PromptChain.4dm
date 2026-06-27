// An ordered sequence of prompts. The output of each step is piped as the input of the next.
//
// Usage:
//   var $chain:=$runner.newChain()
//   $chain.prompt("extract_wisdom").prompt("summarize")
//   var $res:=$chain.run($inputText)

// The runner used to execute each step.
property runner : cs:C1710.PromptRunner
// Ordered steps. Each step is {name: Text; options: Object}.
property steps : Collection:=[]

Class constructor($runner : cs:C1710.PromptRunner)
	This:C1470.runner:=$runner

	// Add a prompt step. Returns This to allow fluent chaining.
	// $options may contain {variables: Object; parameters: OpenAIChatCompletionsParameters|Object}.
Function prompt($name : Text; $options : Object) : cs:C1710.PromptChain
	This:C1470.steps.push({name: $name; options: $options})
	return This:C1470

	// Run the chain: pipe $input through each prompt in order.
	// Stops at the first failing step. $variables are merged into every step (step-level wins).
Function run($input : Text; $variables : Object) : cs:C1710.PromptChainResult
	var $chainResult : cs:C1710.PromptChainResult:=cs:C1710.PromptChainResult.new()
	var $current : Text:=$input

	var $step : Object
	var $options : Object
	var $merged : Object
	var $key : Text
	var $result : cs:C1710.PromptResult
	For each ($step; This:C1470.steps)
		$options:=($step.options=Null:C1517) ? {} : OB Copy:C1225($step.options)

		// Merge chain-level variables with step-level variables (step wins).
		If ($variables#Null:C1517)
			$merged:=OB Copy:C1225($variables)
			If ($options.variables#Null:C1517)
				For each ($key; $options.variables)
					$merged[$key]:=$options.variables[$key]
				End for each
			End if
			$options.variables:=$merged
		End if

		$result:=This:C1470.runner.run($step.name; $current; $options)
		$chainResult._push($result)

		If (Not:C34($result.success))
			break
		End if

		$current:=$result.text
	End for each

	return $chainResult
