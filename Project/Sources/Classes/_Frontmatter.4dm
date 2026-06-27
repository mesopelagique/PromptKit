// Singleton: parses optional YAML frontmatter from markdown (e.g. VS Code .prompt.md files).
// Usage: cs._Frontmatter.me.parse($text) -> {frontmatter: Object; body: Text}

singleton Class constructor()

	// Parse optional YAML frontmatter delimited by leading and closing "---" lines.
	// Returns {frontmatter: Object; body: Text}. Without frontmatter: {frontmatter: {}; body: $text}.
Function parse($text : Text) : Object
	var $result : Object:={frontmatter: {}; body: String:C10($text)}
	If (Length:C16(String:C10($text))=0)
		$result.body:=""
		return $result
	End if

	// normalize line endings for scanning
	var $normalized : Text:=Replace string:C233(String:C10($text); "\r\n"; "\n")
	$normalized:=Replace string:C233($normalized; "\r"; "\n")

	var $lines : Collection:=Split string:C1554($normalized; "\n")
	If (($lines.length=0) || (Not:C34(Match regex:C1019("^\\s*---\\s*$"; $lines[0]))))
		return $result  // no frontmatter
	End if

	// find the closing "---" fence
	var $close : Integer:=-1
	var $i : Integer:=1
	While ($i<$lines.length)
		If (Match regex:C1019("^\\s*---\\s*$"; $lines[$i]))
			$close:=$i
			break
		End if
		$i+=1
	End while
	If ($close=-1)
		return $result  // unterminated frontmatter -> treat as none
	End if

	$result.frontmatter:=This:C1470._parseYAML($lines.slice(1; $close))
	$result.body:=$lines.slice($close+1).join("\n")
	return $result

	// MARK:- internal minimal YAML

	// Parse a (small) subset of YAML: key: value, inline arrays, block lists, quotes, bool/number.
Function _parseYAML($lines : Collection) : Object
	var $obj : Object:={}
	var $currentKey : Text:=""
	var $line : Text
	var $item : Text
	var $colon : Integer
	var $key : Text
	var $rest : Text
	For each ($line; $lines)
		var $trimmed : Text:=This:C1470._trim($line)
		If ((Length:C16($trimmed)=0) || (Substring:C12($trimmed; 1; 1)="#"))
			continue
		End if

		// block list item: "- value" belonging to the current key
		If ((Substring:C12($trimmed; 1; 2)="- ") || ($trimmed="-"))
			If (Length:C16($currentKey)>0)
				If (Value type:C1509($obj[$currentKey])#Is collection:K8:32)
					$obj[$currentKey]:=[]
				End if
				$item:=This:C1470._unquote(This:C1470._trim(Substring:C12($trimmed; 2)))
				$obj[$currentKey].push(This:C1470._scalar($item))
			End if
			continue
		End if

		// key: value
		$colon:=Position:C15(":"; $trimmed)
		If ($colon<=0)
			continue
		End if
		$key:=This:C1470._trim(Substring:C12($trimmed; 1; $colon-1))
		$rest:=This:C1470._trim(Substring:C12($trimmed; $colon+1))
		If (Length:C16($key)=0)
			continue
		End if

		$currentKey:=$key
		Case of
			: (Length:C16($rest)=0)
				$obj[$key]:=""  // may become a block list if "- item" lines follow
			: (Substring:C12($rest; 1; 1)="[")
				$obj[$key]:=This:C1470._parseInlineArray($rest)
				$currentKey:=""
			Else
				$obj[$key]:=This:C1470._scalar(This:C1470._unquote($rest))
				$currentKey:=""
		End case
	End for each
	return $obj

	// Parse an inline array: [a, 'b', "c"]
Function _parseInlineArray($s : Text) : Collection
	var $result : Collection:=[]
	var $inner : Text:=This:C1470._trim($s)
	If (Substring:C12($inner; 1; 1)="[")
		$inner:=Substring:C12($inner; 2)
	End if
	If ((Length:C16($inner)>0) && (Substring:C12($inner; Length:C16($inner); 1)="]"))
		$inner:=Substring:C12($inner; 1; Length:C16($inner)-1)
	End if
	If (Length:C16(This:C1470._trim($inner))=0)
		return $result
	End if
	var $part : Text
	For each ($part; Split string:C1554($inner; ","))
		var $value : Text:=This:C1470._unquote(This:C1470._trim($part))
		If (Length:C16($value)>0)
			$result.push(This:C1470._scalar($value))
		End if
	End for each
	return $result

	// Coerce a scalar string to boolean / number / null / text.
Function _scalar($s : Text) : Variant
	Case of
		: ($s="true")
			return True:C214
		: ($s="false")
			return False:C215
		: ($s="null")
			return Null:C1517
		: (Match regex:C1019("^-?\\d+(\\.\\d+)?$"; $s))
			return Num:C11($s)
		Else
			return $s
	End case

	// Strip a single pair of surrounding single or double quotes.
Function _unquote($s : Text) : Text
	var $r : Text:=String:C10($s)
	If (Length:C16($r)>=2)
		var $first : Text:=Substring:C12($r; 1; 1)
		var $last : Text:=Substring:C12($r; Length:C16($r); 1)
		If (((($first="\"") && ($last="\""))) || (($first="'") && ($last="'")))
			$r:=Substring:C12($r; 2; Length:C16($r)-2)
		End if
	End if
	return $r

	// Trim spaces and tabs from both ends.
Function _trim($s : Text) : Text
	var $r : Text:=String:C10($s)
	While ((Length:C16($r)>0) && ((Substring:C12($r; 1; 1)=" ") || (Substring:C12($r; 1; 1)=Char:C90(9))))
		$r:=Substring:C12($r; 2)
	End while
	While ((Length:C16($r)>0) && ((Substring:C12($r; Length:C16($r); 1)=" ") || (Substring:C12($r; Length:C16($r); 1)=Char:C90(9))))
		$r:=Substring:C12($r; 1; Length:C16($r)-1)
	End while
	return $r
