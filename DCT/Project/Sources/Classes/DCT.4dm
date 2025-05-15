property version : Text
property name : Text
property isThrowAvailable : Boolean
property isDataChangeTrackingAvailable : Boolean
property isDataChangeTrackingEnabled : Boolean
property isRemoteGlobalStampAvailable : Boolean
property dataClasses : Collection
property ds : 4D:C1709.DataStoreImplementation  //the remote ds
property localStamp : Real
property remoteStamp : Real

property _major : Integer
property _minor : Integer
property _patch : Integer
property _name : Text
property _ds : 4D:C1709.DataStoreImplementation
property _isRemoteGlobalStampAvailable : Boolean
property _isThrowAvailable : Boolean
property _isDataChangeTrackingEnabled : Boolean
property _isDataChangeTrackingAvailable : Boolean
property _dataClasses : Collection

Class constructor
	
	This:C1470._major:=0
	This:C1470._minor:=0
	This:C1470._patch:=1
	
	var $build : Integer
	var $version : Text
	$version:=Application version:C493($build)
	This:C1470._isThrowAvailable:=($version>="2020")
	This:C1470._isDataChangeTrackingAvailable:=($version>="2030")
	
	This:C1470._dataClasses:=[]
	
	This:C1470._isDataChangeTrackingEnabled:=(OB Instance of:C1731(ds:C1482["__DeletedRecords"]; 4D:C1709.DataClass))
	
	If (This:C1470.isDataChangeTrackingAvailable) && (This:C1470.isDataChangeTrackingEnabled)
		
		var $dataClassName : Text
		var $dataClass : 4D:C1709.DataClass
		For each ($dataClassName; ds:C1482)
			If ($dataClassName="__DeletedRecords")
				continue
			End if 
			$dataClass:=ds:C1482[$dataClassName]
			If ($dataClass.__GlobalStamp#Null:C1517)
				This:C1470._dataClasses.push($dataClass)
			End if 
		End for each 
	End if 
	
Function connect($connectionInfo : Object; $name : Text) : Boolean
	
	If ($name="")  //name 
		$name:=$connectionInfo.hostname
	End if 
	
	var $ds : 4D:C1709.DataStoreImplementation
	If (ds:C1482($name)#Null:C1517)  //we already have a proxy connection
		$ds:=ds:C1482($name)
	Else 
		$ds:=Open datastore:C1452($connectionInfo; $name)
	End if 
	
	If ($ds#Null:C1517)
		This:C1470._isRemoteGlobalStampAvailable:=(OB Instance of:C1731($ds.getRemoteGlobalStamp; 4D:C1709.Function))
		This:C1470._ds:=$ds
		This:C1470._name:=$name
		return True:C214
	End if 
	
	return False:C215
	
Function sync($dataClasses : Collection)
	
	var $nextLocalStamp; $nextRemoteStamp : Real
	$nextLocalStamp:=This:C1470.getLocalGlobalStamp()
	$nextRemoteStamp:=This:C1470.getRemoteGlobalStamp()
	
	var $localStamp; $remoteStamp : Real
	$localStamp:=This:C1470.localStamp
	$remoteStamp:=This:C1470.remoteStamp
	
	//if none specified, sync all tables
	If ($dataClasses=Null:C1517) || ($dataClasses.length=0)
		$dataClasses:=This:C1470.dataClasses
	End if 
	
/*
prepare to log sync errors
the files are create locally, not on the server
*/
	var $settings : cs:C1710._Settings
	$settings:=cs:C1710._Settings.new()
	
	var $localLogFile; $remoteLogFile : 4D:C1709.FileHandle
	$remoteLogFile:=$settings.openLogFileForDataStore(This:C1470.name; True:C214)
	$localLogFile:=$settings.openLogFileForDataStore(This:C1470.name)
	
	var $ds : 4D:C1709.DataStoreImplementation
	$ds:=This:C1470.ds
	
	//1: local ---> remote
	
	If (This:C1470.isDataChangeTrackingAvailable) && (This:C1470.isDataChangeTrackingEnabled)
		
		var $dataClass : 4D:C1709.DataClass
		var $dataClassName; $attributeName : Text
		var $remoteDataClass; $localDataClass : 4D:C1709.DataClass
		var $remoteEntity; $localEntity : 4D:C1709.Entity
		var $entitySelection : 4D:C1709.EntitySelection
		For each ($dataClass; $dataClasses)
			$dataClassName:=$dataClass.getInfo().name
			
			$remoteDataClass:=$ds[$dataClassName]
			If (Not:C34(OB Instance of:C1731($remoteDataClass; 4D:C1709.DataClass)))
				If (This:C1470.isThrowAvailable)
					//:C1805({componentSignature: "DCT"; errCode: 3; target: "remote dataclass"; name: $dataClassName; deferred: True})
				End if 
				continue
			End if 
			
			$localDataClass:=ds:C1482[$dataClassName]
			If (Not:C34(OB Instance of:C1731($localDataClass; 4D:C1709.DataClass)))
				If (This:C1470.isThrowAvailable)
					//:C1805({componentSignature: "DCT"; errCode: 3; target: "local dataclass"; name: $dataClassName; deferred: True})
				End if 
				continue
			End if 
			
			Case of 
				: ($dataClassName="__DeletedRecords")
					$entitySelection:=ds:C1482["__DeletedRecords"].query("__Stamp >= :1"; $localStamp)
					For each ($localEntity; $entitySelection)
						$remoteEntity:=$ds[$localEntity.__TableName].get($localEntity.__PrimaryKey)
						If ($remoteEntity#Null:C1517)
							$status:=$remoteEntity.drop()
							If (Not:C34($status.success))
								If ($remoteLogFile#Null:C1517)
									$remoteLogFile.writeLine(JSON Stringify:C1217($status; *))
								End if 
							Else 
								//no need to care about deletion bouncing back, it no longer exists locally
							End if 
						End if 
					End for each 
				Else 
					$entitySelection:=$localDataClass.query("__GlobalStamp >= :1"; $localStamp)
					For each ($localEntity; $entitySelection)
						$remoteEntity:=$remoteDataClass.get($localEntity.getKey())
						If ($remoteEntity=Null:C1517)
							$remoteEntity:=$remoteDataClass.new()
						End if 
						For each ($attributeName; $localEntity)
							If ($localDataClass[$attributeName].kind="storage") && ($attributeName#"__GlobalStamp")
								$remoteEntity[$attributeName]:=$localEntity[$attributeName]
							End if 
						End for each 
						$status:=$remoteEntity.save(dk auto merge:K85:24)
						If (Not:C34($status.success))
							If ($remoteLogFile#Null:C1517)
								$remoteLogFile.writeLine(JSON Stringify:C1217($status; *))
								$remoteLogFile.writeLine(JSON Stringify:C1217($localEntity.toObject(); *))
							End if 
							This:C1470._touchLocalEntity($localEntity)
						Else 
							
							//increment the stamp to avoid the operation bouncing back
							If ($remoteEntity.__GlobalStamp#Null:C1517)
								$nextRemoteStamp:=$remoteEntity.__GlobalStamp+1
							End if 
							
						End if 
					End for each 
			End case 
		End for each 
		
	End if 
	
	//2: remote ---> local
	
	For each ($dataClass; $dataClasses)
		$dataClassName:=$dataClass.getInfo().name
		$remoteDataClass:=$ds[$dataClassName]
		If (Not:C34(OB Instance of:C1731($remoteDataClass; 4D:C1709.DataClass)))
			If (This:C1470.isThrowAvailable)
				//:C1805({componentSignature: "DCT"; errCode: 3; target: "remote dataclass"; name: $dataClassName; deferred: True})
			End if 
			continue
		End if 
		
		$localDataClass:=ds:C1482[$dataClassName]
		If (Not:C34(OB Instance of:C1731($localDataClass; 4D:C1709.DataClass)))
			If (This:C1470.isThrowAvailable)
				//:C1805({componentSignature: "DCT"; errCode: 3; target: "local dataclass"; name: $dataClassName; deferred: True})
			End if 
			continue
		End if 
		
		Case of 
			: ($dataClassName="__DeletedRecords")
				$entitySelection:=$ds.__DeletedRecords.query("__Stamp >= :1"; $remoteStamp)
				For each ($remoteEntity; $entitySelection)
					$localEntity:=ds:C1482[$remoteEntity.__TableName].get($remoteEntity.__PrimaryKey)
					If ($localEntity#Null:C1517)
						$status:=$localEntity.drop()
						If (Not:C34($status.success))
							If ($localLogFile#Null:C1517)
								$localLogFile.writeLine(JSON Stringify:C1217($status; *))
							End if 
						Else 
							//no need to care about deletion bouncing back, it no longer exists locally
						End if 
					End if 
				End for each 
			Else 
				$entitySelection:=$remoteDataClass.query("__GlobalStamp >= :1"; $remoteStamp)
				For each ($remoteEntity; $entitySelection)
					$localEntity:=$localDataClass.get($remoteEntity.getKey())
					If ($localEntity=Null:C1517)
						$localEntity:=$localDataClass.new()
					End if 
					For each ($attributeName; $remoteEntity)
						If ($localDataClass[$attributeName].kind="storage") && ($attributeName#"__GlobalStamp")
							$localEntity[$attributeName]:=$remoteEntity[$attributeName]
						End if 
					End for each 
					$status:=$localEntity.save(dk auto merge:K85:24)
					If (Not:C34($status.success))
						If ($localLogFile#Null:C1517)
							$localLogFile.writeLine(JSON Stringify:C1217($status; *))
							$localLogFile.writeLine(JSON Stringify:C1217($localEntity.toObject(); *))
						End if 
						This:C1470._touchRemoteEntity($remoteEntity)
					Else 
						
						//increment the stamp to avoid the operation bouncing back
						If ($localEntity.__GlobalStamp#Null:C1517)
							$nextLocalStamp:=$localEntity.__GlobalStamp+1
						End if 
						
					End if 
				End for each 
		End case 
	End for each 
	
	saveLocalGlobalStamp($nextLocalStamp; This:C1470.name)
	saveRemoteGlobalStamp($nextRemoteStamp; This:C1470.name)
	
	$localLogFile:=Null:C1517
	$remoteLogFile:=Null:C1517
	
	//MARK: stamp functions (public)
	
Function getLocalGlobalStamp() : Real
	
	If (This:C1470.isDataChangeTrackingAvailable)
		//%W-550.2
		return ds:C1482.getGlobalStamp()
		//%W+550.2
	End if 
	
	return -1
	
Function getRemoteGlobalStamp() : Real
	
	If (This:C1470.isRemoteGlobalStampAvailable)
		//%W-550.2
		return This:C1470.ds.getRemoteGlobalStamp()
		//%W+550.2
	End if 
	
	return -1
	
	//MARK: touch functions (private)
	
Function _touchLocalEntity($localEntity : 4D:C1709.Entity) : Object
	
	If ($localEntity=Null:C1517)\
		 || (Not:C34(OB Instance of:C1731($localEntity; 4D:C1709.Entity)))\
		 || ($localEntity.__GlobalStamp=Null:C1517)
		If (This:C1470.isThrowAvailable)
			//:C1805({componentSignature: "DCT"; errCode: 1; target: "the entity"; deferred: True})
		End if 
		return 
	End if 
	
/*
we need to touch the entity in order to increment the global stamp
every table with DCT enabled has a "__GlobalStamp" attribute
*/
	
	$localEntity.__GlobalStamp:=$localEntity.__GlobalStamp
	return $localEntity.save(dk auto merge:K85:24)
	
Function _touchRemoteEntity($remoteEntity : 4D:C1709.Entity) : Object
	
	If ($remoteEntity=Null:C1517)\
		 || (Not:C34(OB Instance of:C1731($remoteEntity; 4D:C1709.Entity)))\
		 || ($remoteEntity.__GlobalStamp=Null:C1517)
		If (This:C1470.isThrowAvailable)
			//:C1805({componentSignature: "DCT"; errCode: 1; target: "the entity"; deferred: True})
		End if 
		return 
	End if 
	
/*
we need to touch the entity in order to increment the global stamp
but touching the "__GlobalStamp" attribute doesn't cut it...
presumably because of "open datastore" network optimisation
fortunately with ORDA every table has a non-composite primary key
so let's use that instead
*/
	
	var $primaryKey : Text
	$primaryKey:=$remoteEntity.getDataClass().getInfo().primaryKey
	$remoteEntity[$primaryKey]:=$remoteEntity[$primaryKey]
	return $remoteEntity.save(dk auto merge:K85:24)
	
	//MARK: const properties
	
Function get isDataChangeTrackingAvailable() : Boolean
	
	return This:C1470._isDataChangeTrackingAvailable
	
Function get isDataChangeTrackingEnabled() : Boolean
	
	return This:C1470._isDataChangeTrackingEnabled
	
Function get isThrowAvailable() : Boolean
	
	return This:C1470._isThrowAvailable
	
Function get isRemoteGlobalStampAvailable() : Boolean
	
	return This:C1470._isRemoteGlobalStampAvailable
	
Function get dataClasses() : Collection
	
	return This:C1470._dataClasses
	
Function get ds() : 4D:C1709.DataStoreImplementation
	
	If (This:C1470._ds=Null:C1517)
		If (This:C1470.isThrowAvailable)
			//:C1805({componentSignature: "DCT"; errCode: 2; deferred: True})
		End if 
	End if 
	
	return This:C1470._ds
	
Function get name() : Text
	
	return This:C1470._name
	
Function get version() : Text
	
	return [This:C1470._major; This:C1470._minor; This:C1470._patch].join(".")
	
Function get localStamp() : Real
	
	return loadLocalGlobalStamp(This:C1470.name)
	
Function get remoteStamp() : Real
	
	return loadRemoteGlobalStamp(This:C1470.name)