# package/packer/azure

See also: [How to use Packer to create Linux virtual machine images in Azure](https://docs.microsoft.com/en-us/azure/virtual-machines/linux/build-image-with-packer)

## Create Service Principal

```shell
az ad sp create-for-rbac --query "{ client_id: appId, client_secret: password, tenant_id: tenant }"
```

## Get Subscription ID

```shell
az account show --query "{ subscription_id: id }"
```

## Create Resource Group

Create Azure resource group for Packer images:

```shell
az group create --name packer-images-rg
```

## Set Template Variables

Create `./variables.json` file and replace values accordingly:

```json
{
  "client_id": "REPLACE",
  "client_secret": "REPLACE",
  "tenant_id": "REPLACE",
  "subscription_id": "REPLACE"
}
```

## Build

```shell
packer build -var-file=variables.json template.pkr.hcl
```

## Deploy

Create `./user-data.txt` file:

```text
ssh_authorized_keys:
- github:schnerring
```

Make sure to `export` the `subscription_id`, then deploy:

```shell
az group create --name k3os-test-rg
az vm create \
    --resource-group k3os-test-rg \
    --name k3os-test-vm \
    --image "/subscriptions/${subscription_id}/resourceGroups/packer-images-rg/providers/Microsoft.Compute/images/k3os-v0.19.4-dev.5-mimg" \
    --size Standard_B1s \
    --admin-username rancher \
    --custom-data ./user-data.txt
```

`--admin-username rancher` reports the VM's only correct username `rancher` to the Azure platform, since k3OS doesn't allow changing it.
