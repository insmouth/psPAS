﻿function Get-PASUser {
	<#
.SYNOPSIS
Returns details of a user

.DESCRIPTION
Returns information on specific vault user.

.PARAMETER id
The numeric id of the user to return details of.
Requires CyberArk version 10.10+

.PARAMETER Search
Search string.
Requires CyberArk version 10.9+

.PARAMETER UserType
The type of the user.
Requires CyberArk version 10.9+

.PARAMETER ComponentUser
Whether the user is a known component or not.
Requires CyberArk version 10.9+

.PARAMETER UserName
The user's name

.EXAMPLE
Get-PASUser

Returns information for all found Users

.EXAMPLE
Get-PASUser -id 123

Returns information on User with id 123

.EXAMPLE
Get-PASUser -search SearchTerm -ComponentUser $False

Returns information for all matching Users

.EXAMPLE
Get-PASUser -UserName Target_User

Displays information on Target_User
#>
	[CmdletBinding(DefaultParameterSetName = "10_9")]
	param(

		[parameter(
			Mandatory = $true,
			ValueFromPipelinebyPropertyName = $true,
			ParameterSetName = "10_10"
		)]
		[int]$id,

		[parameter(
			Mandatory = $false,
			ValueFromPipelinebyPropertyName = $true,
			ParameterSetName = "10_9"
		)]
		[string]$Search,


		[parameter(
			Mandatory = $false,
			ValueFromPipelinebyPropertyName = $true,
			ParameterSetName = "10_9"
		)]
		[string]$UserType,


		[parameter(
			Mandatory = $false,
			ValueFromPipelinebyPropertyName = $true,
			ParameterSetName = "10_9"
		)]
		[boolean]$ComponentUser,

		[parameter(
			Mandatory = $true,
			ValueFromPipelinebyPropertyName = $true,
			ParameterSetName = "legacy"
		)]
		[string]$UserName
	)

	BEGIN {
		$MinimumVersion = [System.Version]"10.9"
		$RequiredVersion = [System.Version]"10.10"
	}#begin

	PROCESS {

		#Create URL for request
		$URI = "$Script:BaseURI/api/Users"

		If ($PSCmdlet.ParameterSetName -eq "10_10") {

			Assert-VersionRequirement -ExternalVersion $Script:ExternalVersion -RequiredVersion $RequiredVersion

			$URI = "$URI/$id"

		} ElseIf ($PSCmdlet.ParameterSetName -eq "10_9") {

			Assert-VersionRequirement -ExternalVersion $Script:ExternalVersion -RequiredVersion $MinimumVersion

			#Get Parameters to include in request
			$boundParameters = $PSBoundParameters | Get-PASParameter

			#Create Query String, escaped for inclusion in request URL
			$queryString = ($boundParameters.keys | ForEach-Object {

					"$_=$($boundParameters[$_] | Get-EscapedString)"

				}) -join '&'

			#Build URL from base URL
			$URI = "$URI`?$queryString"

		}

		ElseIf ($PSCmdlet.ParameterSetName -eq "legacy") {

			#Create URL for request
			$URI = "$Script:BaseURI/WebServices/PIMServices.svc/Users/$($UserName | Get-EscapedString)"

		}

		#send request to web service
		$result = Invoke-PASRestMethod -Uri $URI -Method GET -WebSession $Script:WebSession

		#Handle V10 return
		if ($result.Users) {

			$result.Users | Add-ObjectDetail -typename psPAS.CyberArk.Vault.User.Extended

		}

		#Handle legacy return
		ElseIf ($result) {

			If ($PSCmdlet.ParameterSetName -eq "10_10") {

				$result | Add-ObjectDetail -typename psPAS.CyberArk.Vault.User.Extended

			} ElseIf ($PSCmdlet.ParameterSetName -eq "legacy") {

				$result | Add-ObjectDetail -typename psPAS.CyberArk.Vault.User

			}

		}


	}#process

	END { }#end

}