# (PREVIEW) Automatic Zone Placement

## Introduction 
Welcome to the onboarding guide for Automatic Zone Placement, an exciting new feature in Azure Compute that enables greater flexibility and resilience in your VM deployments. This document will walk you through the essentials of this feature, highlight its benefits, and provide a step-by-step guide on how to utilize it effectively.

## Supportability
- Currently we are previewing sign-up for previewing New/Existing Disk(s), New/Existing IP attach scenarios with Automatic Zone Placement VM: [Sign-up here](https://aka.ms/automatic-zone-placement)
- **Unsupported scenarios:** Proximity Placement Groups (PPG), Dedicated Host & Capacity Reservation groups are not supported to be created with an  Automatic Zone Placement VM as of now (they will be included in the future)

## What is Automatic Zone Placement?
Automatic Zone Placement allows you to create a VM without the overhead of zone selection. VM Create API will accept a new param value zonePlacementPolicy=’auto’ during Single Instance VM creation. (Customers don’t have to specify ‘zones’ property with this feature.) This will let Azure pick the most optimal landing zone for the VM during creation (initial allocation) & re-allocation, based on multiple infrastructure constraints including compute & storage capacity.
### VM PUT REST API new property:
**Placement Property Sample:**
```json
"placement": {
		"zonePlacementPolicy": "Auto",
		"excludeZones": [
			"2"
		]
		"includeZones": [
			"1","3"
		]
	}
```
**Description of Placement Property:**
- zonePlacementPolicy (required): will accept the value “Auto” indicating Azure will pick the most optimal zone during  creation (initial allocation) & re-allocation
- excludeZones (optional): to specify if any particular zone(s) need to be avoided while Azure selects the landing zone for the VM
- includeZones (optional): to specify if any sub-set of zone(s) ONLY need to be used
> [!NOTE]
 > - Only one of the zone='n' or zonePlacementPolicy can be provided at a time during VM create. If both are provided at the same time, an error will be thrown.
 > - Only one of includeZones/excludeZones can be provided at a time. If both are provided at the same time, an error will be thrown.
 > - The scope of this Private Preview allows SI VM creation via REST API or ARM template in EastUS2EUAP region

## Benefits of Automatic Zone Placement
This will improve customers’ regional deployment experience in comparison to current explicit selection of zone (1/2/3). Azure will attempt to select the most optimal zone and aid in improved VM allocation success rate! 

## Creating VM using Azure Selected Zone via REST API
### Step 1: Subscription allowlisting
Get your intended Azure Subscription that will be used for preview to be allowlisted by the Product PoCs below (if not already). Or fill [this form](https://aka.ms/automatic-zone-placement) & the team will get back in 1-2 business days.
> [!NOTE]
> Contact: asz-support@microsoft.com for allowlisting assistance
### Step 2: Create a Network Interface
In the Azure portal, select "Network Interface" resource create. Provide the following details:
- Subscription: Allowlisted Subscription
- Resource Group: Create New (preferably) & note this for later steps
- Region: East US2 EUAP
- Name: Give any name and note this for later steps
Review & create the Network Interface
Network Interface can also be created API, PowerShell, CLI by following [Create Network Interface](https://learn.microsoft.com/en-us/azure/virtual-network/virtual-network-network-interface?tabs=azure-portal#create-a-network-interface)
### Step 3: Create a Managed Disk
In the Azure portal, select "Managed Disks" resource create. Provide the following details:
- Subscription: Allowlisted Subscription
- Resource Group: Same resource group that is used for Network Interface creation
- Name: Give any name and note this for later steps
- Region: East US2 EUAP
- Availability Zone: No infrastructure redundancy required (create regional disk to get the best validation for Azure Selected Zone VM)
Review & create the Managed Disk
Managed Disk can also be created API, PowerShell, CLI by following [Overview of Azure Disk Storage - Azure Virtual Machines | Microsoft Learn](https://learn.microsoft.com/en-us/azure/virtual-machines/managed-disks-overview)
### Step 4: Create VM using Azure Selected Zone via REST API call
- PUT Request latest API URI: (make edits where the URI is **{}**)
```log
https://management.azure.com/subscriptions/{ProvideWhitelistedSubIdHere}/resourceGroups/{ProvideResourceGroupCreatedInStep2Here}/providers/Microsoft.Compute/virtualMachines/{GiveAVMNameHere}?api-version=2024-11-01
```
- Request Body Json Sample: (make edits where **{}**)
```json
{
	"name": "{GiveAVMNameHere}",
	"location": "East US 2 EUAP",
  "placement": {
		"zonePlacementPolicy": "Auto",
	},
	"properties": {
		"hardwareProfile": {
			"vmSize": "Standard_DS1_v2"
		},
		"storageProfile": {
			"imageReference": {
				"publisher": "canonical",
				"offer": "0001-com-ubuntu-server-focal",
				"sku": "20_04-lts-gen2",
				"version": "20.04.202405130"
			},
			"osDisk": {
				"createOption": "FromImage",
				"caching": "ReadWrite",
				"managedDisk": {
					"storageAccountType": "Premium_LRS"
				},
				"deleteOption": "Detach",
				"diskSizeGB": 30
			},
			"dataDisks": [
				{
					"lun": 0,
					"name": "{Get Disk Name from the Disk created in Step 3 and paste here}",
					"createOption": "Attach",
					"managedDisk": {
						"id": "{Get Disk ResourceID from the Disk created in Step3 and paste here}"
					}
				},
				{
					"lun": 1,
					"name": "ImplicitAnyZoneDisk",
					"createOption": "Empty",
					"managedDisk": {
						"storageAccountType": "Premium_LRS"
					},
					"deleteOption": "Detach",
					"diskSizeGB": 30
				}
			] 
		},
		"osProfile": {
			"computerName": "{giveNameofChoice}",
			"adminUsername": "{GiveUsernameofChoice}",
			"adminPassword": "{GivePasswordofChoice}"
		},
		"networkProfile": {
			"networkInterfaces": [
				{
					"id": "{Get Network Interface ResourceID from the NIC created in Step2 and paste here} "
				}
			]
		}
	}
}
```
### Step 5: Send the REST API PUT request
- Provide the required authentication token
- Send the REST API request from the API tool
### Step 6: Review the created VM
After few moments of response preview, verify if the VM was created with the Name provided in the API Call:

## Creating VM using Automatic Zone Placement via ARM template
### Step 1: Download the template, parameters & deploy raw files from below: 
1. [template.json](./template.json)
2. [parameters.json](./parameters.json)
3. [deploy.ps1](./deploy.ps1)

### Step 2:  Review the template & parameters files
Template & parameters files are pre-populated with sample values. Please modify as desired. 
### Step 3. Run deploy.ps1 in PowerShell
Upload the files is Cloud Shell is being used. Else store the above files in a location from where the PowerShell commands are run: (make edits where **{}**)
```log
Run the script: > .\deploy.ps1 -Location ‘eastus2euap’ -SubscriptionId ‘{WhitelistedSubscriptionID}’ -ResourceGroupName ‘{giveDesiredRGName}’ -TemplateParameterFile ‘parameters.json’ -TemplateFile ‘template.json’ -VirtualMachineName ‘{giveDesiredVMName}’ -VirtualNetworkName ‘{giveDesiredNICName}’
```
### Step 4: Review the created VM
After few moments of response preview, verify if the VM was created with the Name provided in the API Call.

## Troubleshooting
Feel free to reach out to (asz-support@microsoft.com) for any questions & issues

