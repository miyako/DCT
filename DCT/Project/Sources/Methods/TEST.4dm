//%attributes = {}
var $DCT : cs:C1710.DCT

$DCT:=cs:C1710.DCT.new()

If ($DCT.connect({hostname: "localhost"; idleTimeout: 100}))
	
	var $ds : 4D:C1709.DataStoreImplementation
	$ds:=$DCT.ds
	
	var $status : Object
	//%W-550.2
	$status:=$ds.authentify({secret: "demo-demo-2025-0123"})
	//%W+550.2
	
	If ($status.success)
		
		$DCT.sync()
		
	End if 
	
End if 