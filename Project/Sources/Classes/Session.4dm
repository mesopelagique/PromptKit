// A persistent conversation history: a named, ordered list of
// {role; content} messages, optionally loaded from / saved to a JSON file.

// Session name (the json file name when persisted).
property name : Text
// Ordered conversation messages (plain {role; content; ...} objects).
property messages : Collection:=[]
// Folder where the session is persisted. If Null, the session stays in memory only.
property folder : 4D:C1709.Folder

Class constructor($name : Text; $folder : 4D:C1709.Folder)
	This:C1470.name:=String:C10($name)
	This:C1470.folder:=$folder
	This:C1470.load()
	
	// The file backing this session, or Null if it cannot be persisted.
Function get _file : 4D:C1709.File
	If ((This:C1470.folder=Null:C1517) || (Length:C16(This:C1470.name)=0))
		return Null:C1517
	End if 
	return This:C1470.folder.file(This:C1470.name+".json")
	
	// True if the session has no messages.
Function isEmpty() : Boolean
	return (This:C1470.messages=Null:C1517) || (This:C1470.messages.length=0)
	
	// Load messages from the backing file (if any).
Function load()
	var $file : 4D:C1709.File:=This:C1470._file
	If (($file#Null:C1517) && ($file.exists))
		var $data : Variant:=Try(JSON Parse:C1218($file.getText()))
		If (Value type:C1509($data)=Is collection:K8:32)
			This:C1470.messages:=$data
		End if 
	End if 
	
	// Append a message (OpenAIMessage or {role; content} object) to the history.
Function append($message : Variant)
	If ($message=Null:C1517)
		return 
	End if 
	Case of 
		: (OB Instance of:C1731($message; cs:C1710.AIKit.OpenAIMessage))
			This:C1470.messages.push($message._toBody())
		: (Value type:C1509($message)=Is object:K8:27)
			This:C1470.messages.push($message)
	End case 
	
	// Persist the session to its backing file (creating the folder if needed).
Function save()
	var $file : 4D:C1709.File:=This:C1470._file
	If ($file=Null:C1517)
		return 
	End if 
	If (Not:C34($file.parent.exists))
		$file.parent.create()
	End if 
	$file.setText(JSON Stringify:C1217(This:C1470.messages; *))
	
	// Clear the history and remove the backing file.
Function reset()
	This:C1470.messages:=[]
	var $file : 4D:C1709.File:=This:C1470._file
	If (($file#Null:C1517) && ($file.exists))
		$file.delete()
	End if 
	