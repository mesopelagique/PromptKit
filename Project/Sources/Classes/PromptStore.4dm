// Loads prompts from a folder. Two layouts are supported:
//   - system-style: a sub-folder <name> containing a system.md (and an optional user.md)
//   - VS Code-style: a single <name>.prompt.md file (https://code.visualstudio.com/docs/agent-customization/prompt-files)
// In both cases an optional leading YAML frontmatter is stripped from the content sent to the AI
// and kept on the prompt's `metadata`.

// Root folder containing one sub-folder per prompt.
property folder : 4D:C1709.Folder
// Cache of already loaded prompts, keyed by name.
property _cache : Object:={}

Class constructor($folder : 4D:C1709.Folder)
	If ($folder#Null:C1517)
		This:C1470.folder:=$folder
	Else 
		This:C1470.folder:=This:C1470._defaultFolder()
	End if 
	
	// Default to the Resources/prompts folder.
Function _defaultFolder() : 4D:C1709.Folder
	var $candidates : Collection:=[]
	$candidates.push(Folder:C1567(fk resources folder:K87:11; *).folder("prompts"))
	$candidates.push(Folder:C1567(fk resources folder:K87:11).folder("prompts"))
	
	var $candidate : 4D:C1709.Folder
	For each ($candidate; $candidates)
		If ($candidate.exists)
			return $candidate
		End if 
	End for each 
	return $candidates.first()
	
	
	
	// Return true if a prompt with this name exists (folder/system.md or <name>.prompt.md).
Function exists($name : Text) : Boolean
	If (Length:C16(String:C10($name))=0)
		return False:C215
	End if 
	If (This:C1470.folder.folder($name).file("system.md").exists)
		return True:C214
	End if 
	return This:C1470.folder.file($name+".prompt.md").exists
	
	// Load and return a prompt by name. Throws if not found.
Function get($name : Text) : cs:C1710.Prompt
	If (This:C1470._cache[$name]#Null:C1517)
		return This:C1470._cache[$name]
	End if 
	
	var $promptFolder : 4D:C1709.Folder:=This:C1470.folder.folder($name)
	var $systemFile : 4D:C1709.File:=$promptFolder.file("system.md")
	var $promptFile : 4D:C1709.File:=This:C1470.folder.file($name+".prompt.md")
	
	var $data : Object
	var $parsed : Object
	var $userFile : 4D:C1709.File
	Case of 
		: ($systemFile.exists)
			// system-style folder: system.md (frontmatter stripped) + optional user.md
			$parsed:=cs:C1710._Frontmatter.me.parse($systemFile.getText())
			$data:={name: $name; system: $parsed.body; metadata: $parsed.frontmatter}
			$userFile:=$promptFolder.file("user.md")
			If ($userFile.exists)
				$data.user:=$userFile.getText()
			End if 
		: ($promptFile.exists)
			// VS Code-style single file: <name>.prompt.md (frontmatter stripped into metadata)
			$parsed:=cs:C1710._Frontmatter.me.parse($promptFile.getText())
			$data:={name: $name; system: $parsed.body; metadata: $parsed.frontmatter}
		Else 
			throw:C1805(1; "Prompt not found: \""+String:C10($name)+"\" (no "+$name+"/system.md or "+$name+".prompt.md in "+This:C1470.folder.path+")")
			return Null:C1517
	End case 
	
	var $prompt : cs:C1710.Prompt:=cs:C1710.Prompt.new($data)
	This:C1470._cache[$name]:=$prompt
	return $prompt
	
	// Return the sorted collection of available prompt names (both layouts, de-duplicated).
Function list() : Collection
	If (Not:C34(This:C1470.folder.exists))
		return []
	End if 
	var $names : Object:={}
	
	var $sub : 4D:C1709.Folder
	For each ($sub; This:C1470.folder.folders())
		If ($sub.file("system.md").exists)
			$names[$sub.name]:=True:C214
		End if 
	End for each 
	
	var $file : 4D:C1709.File
	For each ($file; This:C1470.folder.files())
		If (This:C1470._isPromptFile($file))
			$names[This:C1470._promptFileName($file)]:=True:C214
		End if 
	End for each 
	
	return OB Keys:C1719($names).orderBy()
	
	// True if the file is a VS Code-style <name>.prompt.md file.
Function _isPromptFile($file : 4D:C1709.File) : Boolean
	return (Length:C16($file.fullName)>10) && (Substring:C12($file.fullName; Length:C16($file.fullName)-9)=".prompt.md")
	
	// The prompt name for a <name>.prompt.md file (without the .prompt.md suffix).
Function _promptFileName($file : 4D:C1709.File) : Text
	return Substring:C12($file.fullName; 1; Length:C16($file.fullName)-10)
	