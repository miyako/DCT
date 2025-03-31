property _folder : 4D:C1709.Folder

Class constructor
	
	This:C1470._folder:=Folder:C1567(fk logs folder:K87:17; *).folder("DCT")
	
Function _fileForDataStore($name : Text; $isRemote : Boolean; $extension : Text) : 4D:C1709.File
	
	var $folder : 4D:C1709.Folder
	$folder:=This:C1470._folder
	$folder.create()
	
	If ($isRemote)
		$file:=$folder.file("remote-"+$name+$extension)
	Else 
		$file:=$folder.file("local"+$extension)
	End if 
	
	return $file
	
Function logFileForDataStore($name : Text; $isRemote : Boolean) : 4D:C1709.File
	
	return This:C1470._fileForDataStore($name; $isRemote; ".log")
	
Function stampFileForDataStore($name : Text; $isRemote : Boolean) : 4D:C1709.File
	
	return This:C1470._fileForDataStore($name; $isRemote; ".txt")
	
Function openLogFileForDataStore($name : Text; $isRemote : Boolean) : 4D:C1709.FileHandle
	
	var $file : 4D:C1709.File
	$file:=This:C1470.logFileForDataStore($name; $isRemote)
	
	return $file.open("append")
	
Function getStampForDataStore($name : Text; $isRemote : Boolean) : Real
	
	var $file : 4D:C1709.File
	$file:=This:C1470.stampFileForDataStore($name; $isRemote)
	
	If ($file.exists)
		return Num:C11($file.getText())
	End if 
	
	return -1
	
Function setStampForDataStore($stamp : Real; $name : Text; $isRemote : Boolean)
	
	var $file : 4D:C1709.File
	$file:=This:C1470.stampFileForDataStore($name; $isRemote)
	$file.setText(String:C10($stamp))