//%attributes = {}
// Integration tests for PromptRunner (single run + chaining). Requires an API key.

var $client:=TestOpenAI()
If (($client=Null:C1517) || (Length:C16($client.apiKey)=0))
	return   // skip test when no API key is configured
End if 

var $runner:=cs:C1710.PromptRunner.new($client)

var $input:="4D is an application development platform with an integrated database and a programming language. It lets developers build desktop, web and mobile business applications."

// MARK:- single prompt run

var $res:=$runner.run("summarize"; $input)
If (Asserted:C1132(Bool:C1537($res.success); "Cannot run prompt : "+JSON Stringify:C1217($res.errors)))
	ASSERT:C1129(Length:C16($res.text)>0; "prompt run should return a non-empty text")
End if 

// MARK:- chain two prompts (output of the first is piped as input of the second)

var $chainRes:=$runner.chain(["extract_wisdom"; "summarize"]).run($input)
If (Asserted:C1132(Bool:C1537($chainRes.success); "Cannot run chain : "+JSON Stringify:C1217($chainRes.errors)))
	ASSERT:C1129($chainRes.results.length=2; "chain should have run 2 steps")
	ASSERT:C1129($chainRes.outputs.length=2; "chain should have 2 outputs")
	ASSERT:C1129(Length:C16($chainRes.text)>0; "chain final text should not be empty")
End if 

// MARK:- strategy + session do not break a run

var $session:=$runner.session("unit_integration")
$session.reset()
var $sres:=$runner.run("summarize"; $input; {strategy: "cot"; session: $session})
If (Asserted:C1132(Bool:C1537($sres.success); "strategy+session run failed : "+JSON Stringify:C1217($sres.errors)))
	ASSERT:C1129($session.messages.length=2; "session should hold the user + assistant messages")
End if 
$session.reset()
