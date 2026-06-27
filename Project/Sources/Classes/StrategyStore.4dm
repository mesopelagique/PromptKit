// Loads reasoning strategies from a folder of JSON files ({description, prompt}).
// A library of strategies is bundled in the component's Resources/strategies folder.

// Root folder containing one <name>.json per strategy.
property folder : 4D:C1709.Folder
// Cache of already loaded strategies, keyed by name.
property _cache : Object:={}

Class constructor($folder : 4D:C1709.Folder)
	If ($folder#Null:C1517)
		This:C1470.folder:=$folder
	Else 
		This:C1470.folder:=This:C1470._defaultFolder()
	End if 
	
	// Default to the Resources/strategies folder .
Function _defaultFolder() : 4D:C1709.Folder
	var $candidates : Collection:=[]
	$candidates.push(Folder:C1567(fk resources folder:K87:11; *).folder("strategies"))
	$candidates.push(Folder:C1567(fk resources folder:K87:11).folder("strategies"))
	
	var $candidate : 4D:C1709.Folder
	For each ($candidate; $candidates)
		If ($candidate.exists)
			return $candidate
		End if 
	End for each 
	return $candidates.first()
	
	// Return true if a strategy with this name exists.
Function exists($name : Text) : Boolean
	If (Length:C16(String:C10($name))=0)
		return False:C215
	End if 
	return This:C1470.folder.file($name+".json").exists
	
	// Load and return a strategy by name. Throws if not found.
Function get($name : Text) : cs:C1710.Strategy
	If (This:C1470._cache[$name]#Null:C1517)
		return This:C1470._cache[$name]
	End if 
	
	var $file : 4D:C1709.File:=This:C1470.folder.file($name+".json")
	If (Not:C34($file.exists))
		throw:C1805(1; "Strategy not found: \""+String:C10($name)+"\" (no "+$name+".json in "+This:C1470.folder.path+")")
		return Null:C1517
	End if 
	
	var $data : Object:=Try(JSON Parse:C1218($file.getText()))
	If ($data=Null:C1517)
		$data:={}
	End if 
	$data.name:=$name
	
	var $strategy : cs:C1710.Strategy:=cs:C1710.Strategy.new($data)
	This:C1470._cache[$name]:=$strategy
	return $strategy
	
	// Return the sorted collection of available strategy names.
Function list() : Collection
	If (Not:C34(This:C1470.folder.exists))
		return []
	End if 
	var $names : Collection:=[]
	var $file : 4D:C1709.File
	For each ($file; This:C1470.folder.files())
		If ($file.extension=".json")
			$names.push($file.name)
		End if 
	End for each 
	return $names.orderBy()
	