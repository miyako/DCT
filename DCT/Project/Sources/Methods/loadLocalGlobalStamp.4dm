//%attributes = {"invisible":true,"executedOnServer":true,"preemptive":"capable"}
#DECLARE($name : Text) : Real

/*
execute on server: true
*/

return cs:C1710._Settings.new().getStampForDataStore($name)