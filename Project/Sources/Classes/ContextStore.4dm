// Loads named contexts (plain text prepended to the system message) from a folder.
// Contexts are user-provided; by default the folder is Resources/contexts (may not exist).

// Root folder containing one text file per context (<name>.md or <name>).
property folder : 4D:C1709.Folder
// Cache of already loaded contexts, keyed by name.
property _cache : Object:={}

Class constructor($folder : 4D:C1709.Folder)
	If ($folder#Null:C1517)
		This:C1470.folder:=$folder
	Else 
		This:C1470.folder:=This:C1470._defaultFolder()
	End if 
	
	// Default to the Resources/contexts folder
Function _defaultFolder() : 4D:C1709.Folder
	return Folder:C1567(fk resources folder:K87:11; *).folder("contexts")
	
	// Resolve the file backing a context name (.md or no extension). Null if none.
Function _file($name : Text) : 4D:C1709.File
	If (Length:C16(String:C10($name))=0)
		return Null:C1517
	End if 
	var $md : 4D:C1709.File:=This:C1470.folder.file($name+".md")
	If ($md.exists)
		return $md
	End if 
	var $plain : 4D:C1709.File:=This:C1470.folder.file($name)
	If ($plain.exists)
		return $plain
	End if 
	return Null:C1517
	
	// Return true if a context with this name exists.
Function exists($name : Text) : Boolean
	return This:C1470._file($name)#Null:C1517
	
	// Load and return the text content of a context. Throws if not found.
Function get($name : Text) : Text
	If (This:C1470._cache[$name]#Null:C1517)
		return This:C1470._cache[$name]
	End if 
	
	var $file : 4D:C1709.File:=This:C1470._file($name)
	If ($file=Null:C1517)
		throw:C1805(1; "Context not found: \""+String:C10($name)+"\" (in "+This:C1470.folder.path+")")
		return ""
	End if 
	
	var $content : Text:=$file.getText()
	This:C1470._cache[$name]:=$content
	return $content
	
	// Return the sorted collection of available context names.
Function list() : Collection
	If (Not:C34(This:C1470.folder.exists))
		return []
	End if 
	var $names : Collection:=[]
	var $file : 4D:C1709.File
	For each ($file; This:C1470.folder.files())
		$names.push($file.name)
	End for each 
	return $names.orderBy()
	