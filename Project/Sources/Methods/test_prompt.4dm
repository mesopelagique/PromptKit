//%attributes = {}
// Offline tests for the prompt store and message building (no API call).

var $store:=cs:C1710.PromptStore.new()

// MARK:- store should find the bundled prompts

var $names:=$store.list()
If (Asserted:C1132($names.length>0; "No prompts found in store folder "+String:C10($store.folder.path)))
	
	ASSERT:C1129($store.exists("summarize"); "Expected bundled prompt \"summarize\" to exist")
	ASSERT:C1129(Not:C34($store.exists("this_prompt_does_not_exist")); "Non-existing prompt should not exist")
	
	// MARK:- get should load a prompt with a non-empty system prompt
	
	var $prompt:=$store.get("summarize")
	ASSERT:C1129(Length:C16($prompt.system)>0; "Prompt system prompt should not be empty")
	
	// empty user template -> the user message is the raw input
	var $messages:=$prompt.buildMessages("HELLO INPUT"; Null:C1517)
	ASSERT:C1129($messages.length=2; "buildMessages should return system + user")
	ASSERT:C1129($messages[0].role="system"; "first message should be system")
	ASSERT:C1129($messages[1].role="user"; "second message should be user")
	ASSERT:C1129($messages[1].content="HELLO INPUT"; "user content should be the raw input when no template")
	
End if 

// MARK:- {{variable}} substitution

var $custom:=cs:C1710.Prompt.new({name: "_t"; system: "Translate to {{lang}}."; user: "{{input}}"})
var $m2:=$custom.buildMessages("bonjour"; {lang: "English"})
ASSERT:C1129($m2[0].content="Translate to English."; "system {{lang}} should be substituted")
ASSERT:C1129($m2[1].content="bonjour"; "user {{input}} should be substituted")

// MARK:- static user template (no placeholder) -> template + input

var $custom2:=cs:C1710.Prompt.new({name: "_t2"; system: "S"; user: "PREFIX:"})
var $m3:=$custom2.buildMessages("X"; Null:C1517)
ASSERT:C1129($m3[1].content="PREFIX:\nX"; "static user template should be prepended to input")

// MARK:- strategies

var $strategies:=cs:C1710.StrategyStore.new()
If (Asserted:C1132($strategies.list().length>0; "No strategies bundled in "+String:C10($strategies.folder.path)))
	ASSERT:C1129($strategies.exists("cot"); "Expected bundled strategy \"cot\" to exist")
	ASSERT:C1129(Length:C16($strategies.get("cot").prompt)>0; "strategy prompt should not be empty")
End if 

// MARK:- system composition (strategy + context + prompt system, in that order)

var $runner:=cs:C1710.PromptRunner.new(cs:C1710.AIKit.OpenAI.new())
var $system:=$runner._composeSystem("PATTERN_SYS"; {strategy: "cot"; context: "EXTRA_CONTEXT"})
ASSERT:C1129(Position:C15("EXTRA_CONTEXT"; $system)>0; "composed system should contain the context")
ASSERT:C1129(Position:C15("PATTERN_SYS"; $system)>0; "composed system should contain the prompt system")
ASSERT:C1129(Position:C15("EXTRA_CONTEXT"; $system)<Position:C15("PATTERN_SYS"; $system); "context should come before the prompt system")
var $cotPrompt:=$strategies.get("cot").prompt
ASSERT:C1129(Position:C15($cotPrompt; $system)=1; "strategy prompt should be first in the composed system")

// MARK:- session roundtrip (in a temp folder)

var $tmp:=Folder:C1567(fk database folder:K87:14).folder("_tmp_test_sessions")
If ($tmp.exists)
	If ($tmp.file("unit.json").exists)
		$tmp.file("unit.json").delete()
	End if 
	$tmp.delete()
End if 
var $session:=cs:C1710.Session.new("unit"; $tmp)
ASSERT:C1129($session.isEmpty(); "new session should be empty")
$session.append({role: "user"; content: "hi"})
$session.append({role: "assistant"; content: "hello"})
$session.save()
var $reloaded:=cs:C1710.Session.new("unit"; $tmp)
ASSERT:C1129($reloaded.messages.length=2; "reloaded session should have 2 messages")
ASSERT:C1129($reloaded.messages[1].content="hello"; "reloaded session should keep message content")
$reloaded.reset()
ASSERT:C1129($reloaded.isEmpty(); "reset session should be empty")
ASSERT:C1129(Not:C34($tmp.file("unit.json").exists); "reset should remove the session file")
If ($tmp.exists)
	$tmp.delete()
End if 

// MARK:- frontmatter parsing (VS Code .prompt.md)

var $fmText:="---\ndescription: \"A test prompt\"\nmode: agent\nmodel: GPT-4o\ntools: ['githubRepo', 'codebase']\n---\nDo the thing with {{input}}."
var $fm:=cs:C1710._Frontmatter.me.parse($fmText)
ASSERT:C1129($fm.frontmatter.description="A test prompt"; "frontmatter description parsed")
ASSERT:C1129($fm.frontmatter.mode="agent"; "frontmatter mode parsed")
ASSERT:C1129($fm.frontmatter.model="GPT-4o"; "frontmatter model parsed (non-numeric stays text)")
ASSERT:C1129((Value type:C1509($fm.frontmatter.tools)=Is collection:K8:32) && ($fm.frontmatter.tools.length=2); "frontmatter tools is a 2-item array")
ASSERT:C1129($fm.frontmatter.tools[0]="githubRepo"; "first tool parsed")
ASSERT:C1129(Position:C15("---"; $fm.body)=0; "frontmatter delimiters removed from body")
ASSERT:C1129(Position:C15("Do the thing"; $fm.body)>0; "body preserved after frontmatter")

var $plain:=cs:C1710._Frontmatter.me.parse("Just a plain prompt.")
ASSERT:C1129($plain.body="Just a plain prompt."; "plain text body unchanged (no frontmatter)")
ASSERT:C1129(OB Is empty:C1297($plain.frontmatter); "plain text has empty frontmatter")

// MARK:- PromptStore loading a VS Code .prompt.md file

var $ptmp:=Folder:C1567(fk database folder:K87:14).folder("_tmp_test_prompts")
var $existing : 4D:C1709.File
If ($ptmp.exists)
	For each ($existing; $ptmp.files())
		$existing.delete()
	End for each 
	$ptmp.delete()
End if 
$ptmp.create()
$ptmp.file("greet.prompt.md").setText($fmText)

var $pstore:=cs:C1710.PromptStore.new($ptmp)
ASSERT:C1129($pstore.exists("greet"); "store should find the .prompt.md by name")
ASSERT:C1129($pstore.list().includes("greet"); "list should include the .prompt.md prompt")
var $gp:=$pstore.get("greet")
ASSERT:C1129(Position:C15("---"; $gp.system)=0; "loaded prompt system should have frontmatter stripped")
ASSERT:C1129(Position:C15("Do the thing"; $gp.system)>0; "loaded prompt system should keep the body")
ASSERT:C1129($gp.metadata.model="GPT-4o"; "loaded prompt should expose frontmatter metadata")
ASSERT:C1129($gp.description="A test prompt"; "prompt.description convenience should work")
var $gmsgs:=$gp.buildMessages("HELLO"; Null:C1517)
ASSERT:C1129(Position:C15("HELLO"; $gmsgs[0].content)>0; "{{input}} in the body should be substituted in the system message")

For each ($existing; $ptmp.files())
	$existing.delete()
End for each 
$ptmp.delete()

// MARK:- VS Code ${...} variable injection

var $vp:=cs:C1710.Prompt.new({name: "_vs"; system: "Role: ${input:role}. Task on ${input}. Missing: ${input:none:fallback}. Editor: ${selection}."})
var $vsys : Text:=String:C10($vp.buildMessages("THE_INPUT"; {role: "expert"; selection: "SEL"})[0].content)
ASSERT:C1129(Position:C15("Role: expert"; $vsys)>0; "${input:role} should resolve from variables")
ASSERT:C1129(Position:C15("Task on THE_INPUT"; $vsys)>0; "${input} should resolve to the main input")
ASSERT:C1129(Position:C15("Missing: fallback"; $vsys)>0; "${input:name:placeholder} should use the placeholder when the var is missing")
ASSERT:C1129(Position:C15("Editor: SEL"; $vsys)>0; "${selection} should resolve from a supplied variable")

var $vp2:=cs:C1710.Prompt.new({name: "_vs2"; system: "Keep ${unknownThing} literal."})
ASSERT:C1129(Position:C15("${unknownThing}"; $vp2.buildMessages("x"; Null:C1517)[0].content)>0; "unresolved ${...} should be left untouched")
