# package/packer/azure-arm

## Setup

Select a project in Hetzner Cloud console and create an API token:

Security --> API Tokens --> Generate API token (Read & Write permisions)

Copy token

## Build

``` shell
export HCLOUD_TOKEN="TOKEN" # Token from Setup
packer build template.json
```

## Deploy

``` powershell
az vm create `
    --resource-group rg-k3os `
    --name vm-k3os `
    --image /subscriptions/$env:PKR_VAR_subscription_id/resourceGroups/rg-packer-images/providers/Microsoft.Compute/images/mimg-k3os-v0.11.1 `
    --size Standard_B1s `
    --admin-username rancher `
    --enable-agent false `
    --custom-data .\user-data.txt
```
