//%attributes = {"invisible":true}
// Turn a collection of error objects (AIKit OpenAIError or 4D Last errors) into a
// human-readable, single-block message for the `pk` CLI. $1 is the error collection.
#DECLARE($errors : Collection) : Text

var $lines : Collection:=[]
If ($errors#Null)
	var $error : Object
	For each ($error; $errors)
		var $message : Text:=String($error.message)
		If ($message="")
			$message:=JSON Stringify($error)
		End if
		var $code : Text:=""
		If ($error.errCode#Null)
			$code:=" ("+String($error.errCode)+")"
		End if
		$lines.push("pk: "+$message+$code)
	End for each
End if

If ($lines.length=0)
	return "pk: unknown error"
End if
return $lines.join("\n")
