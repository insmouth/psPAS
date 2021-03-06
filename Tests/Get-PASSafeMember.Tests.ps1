Describe $($PSCommandPath -Replace ".Tests.ps1") {

	BeforeAll {
		#Get Current Directory
		$Here = Split-Path -Parent $PSCommandPath

		#Assume ModuleName from Repository Root folder
		$ModuleName = Split-Path (Split-Path $Here -Parent) -Leaf

		#Resolve Path to Module Directory
		$ModulePath = Resolve-Path "$Here\..\$ModuleName"

		#Define Path to Module Manifest
		$ManifestPath = Join-Path "$ModulePath" "$ModuleName.psd1"

		if ( -not (Get-Module -Name $ModuleName -All)) {

			Import-Module -Name "$ManifestPath" -ArgumentList $true -Force -ErrorAction Stop

		}

		$Script:RequestBody = $null
		$Script:BaseURI = "https://SomeURL/SomeApp"
		$Script:ExternalVersion = "0.0"
		$Script:WebSession = New-Object Microsoft.PowerShell.Commands.WebRequestSession

	}


	AfterAll {

		$Script:RequestBody = $null

	}

	InModuleScope $(Split-Path (Split-Path (Split-Path -Parent $PSCommandPath) -Parent) -Leaf ) {

		Context "Input" {

			BeforeEach {

				Mock Invoke-PASRestMethod -MockWith { }

				$InputObj = [pscustomobject]@{
					"SafeName" = "SomeSafe"

				}

				$response = Get-PASSafeMember -SafeName SomeSafe

			}

			It "sends request" {

				Assert-MockCalled Invoke-PASRestMethod -Times 1 -Exactly -Scope It

			}

			It "sends request to expected endpoint" {

				Assert-MockCalled Invoke-PASRestMethod -ParameterFilter {

					$URI -eq "$($Script:BaseURI)/WebServices/PIMServices.svc/Safes/SomeSafe/Members"

				} -Times 1 -Exactly -Scope It

			}

			It "sends request to expected endpoint" {

				$response = $InputObj | Get-PASSafeMember -MemberName SomeMember

				Assert-MockCalled Invoke-PASRestMethod -ParameterFilter {

					$URI -eq "$($Script:BaseURI)/WebServices/PIMServices.svc/Safes/SomeSafe/Members/SomeMember"

				} -Times 1 -Exactly -Scope It

			}

			It "uses expected GET method" {

				Assert-MockCalled Invoke-PASRestMethod -ParameterFilter { $Method -match 'GET' } -Times 1 -Exactly -Scope It

			}

			It "uses expected PUT method" {

				$response = Get-PASSafeMember -SafeName SomeSafe -MemberName SomeMember

				Assert-MockCalled Invoke-PASRestMethod -ParameterFilter { $Method -match 'PUT' } -Times 1 -Exactly -Scope It

			}

			It "sends request with no body" {

				Assert-MockCalled Invoke-PASRestMethod -ParameterFilter { $Body -eq $null } -Times 1 -Exactly -Scope It

			}

		}

		Context "Output" {

			BeforeEach {

				Mock Invoke-PASRestMethod -MockWith {
					[PSCustomObject]@{
						"members" = [PSCustomObject]@{
							"UserName"    = "SomeMember"
							"Permissions" = [pscustomobject]@{
								"Key1"            = $true
								"Key2"            = $true
								"FalseKey"        = $false
								"AnotherKey"      = $true
								"AnotherFalseKey" = $false
								"IntegerKey"      = 1
							}
						}
					}

				}

				$InputObj = [pscustomobject]@{
					"SafeName" = "SomeSafe"

				}

				$response = $InputObj | Get-PASSafeMember

			}

			it "provides output" {

				$response | Should -Not -BeNullOrEmpty

			}

			It "has output with expected number of properties" {

				($response | Get-Member -MemberType NoteProperty).length | Should -Be 3

			}

			It "has expected number of nested permission properties" {

				($response.permissions | Get-Member -MemberType NoteProperty).count | Should -Be 6

			}

			It "has expected boolean false property value" {

				$response.permissions.FalseKey | Should -Be $False


			}

			It "has expected boolean true property value" {


				$response.permissions.Key1 | Should -Be $True

			}

			It "has expected integer property value" {


				$response.permissions.IntegerKey | Should -Be 1

			}

			it "outputs object with expected typename" {

				$response | get-member | select-object -expandproperty typename -Unique | Should -Be psPAS.CyberArk.Vault.Safe.Member

			}

			it "outputs object with expected safename property" {

				$response.SafeName | Should -Be "SomeSafe"

			}

			it "outputs object with expected username property" {

				Mock Invoke-PASRestMethod -MockWith {
					[PSCustomObject]@{
						"member" = [PSCustomObject]@{
							"Permissions" = @(
								[pscustomobject]@{
									"Key"   = "Key1"
									"Value" = $true
								},
								[pscustomobject]@{
									"Key"   = "Key2"
									"Value" = $true
								},
								[pscustomobject]@{
									"Key"   = "TrueKey"
									"Value" = $true
								},
								[pscustomobject]@{
									"Key"   = "FalseKey"
									"Value" = $false
								},
								[pscustomobject]@{
									"Key"   = "AnotherKey"
									"Value" = $true
								},
								[pscustomobject]@{
									"Key"   = "AnotherFalseKey"
									"Value" = $false
								}


							)
						}
					}

				}

				$response = $InputObj | Get-PASSafeMember -MemberName SomeMember

				$response.UserName | Should -Be "SomeMember"

			}



		}

	}

}