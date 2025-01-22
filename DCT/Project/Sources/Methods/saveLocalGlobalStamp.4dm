//%attributes = {"invisible":true,"executedOnServer":true,"preemptive":"capable"}
#DECLARE($stamp : Real)

/*
execute on server: true
*/

cs:C1710._Settings.new().setStampForDataStore($stamp)