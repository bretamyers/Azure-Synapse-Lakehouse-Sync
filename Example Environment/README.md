# Azure Synapse Lakehouse Sync: Example Environment

Whether you're new to the data lake & lakehouse pattern, or exploring how Synapse Lakehouse Sync would work in your environment, this will deploy an end-to-end example environment. We wanted to provide an easy option for you to evaluate and understand how Azure Synapse Lakehouse Sync works with little effort.


# How to Deploy

### "Easy Button" Deployment
The following commands should be executed from the Azure Cloud Shell at https://shell.azure.com using Bash:

```
@Azure:~$ git clone https://github.com/bretamyers/Azure-Synapse-Lakehouse-Sync
@Azure:~$ cd Azure-Synapse-Lakehouse-Sync
@Azure:~$ cd Example Environment
@Azure:~$ bash deploySynapseSync.sh 
```

## What's Deployed

### Azure Synapse Analytics Workspace
- DW1000 Dedicated SQL Pool
- Azure Synapse Lakehouse Sync Pipelines

### Azure Databricks Workspace
- Small Cluster
- Azure Synapse Lakehouse Sync Notebooks

### Azure Data Lake Storage Gen2
- <b>config</b> container for Azure Synapse Analytics Workspace
- <b>data</b> container for sample data which acts as your "data lake"

### Azure Key Vault
- Secure storage for Azure Data Lake access keys and used by Databricks for authentication

## What's Configured
The deploySynapseSync.sh script will execute a Bicep deployment for the environment and then configure the environment with the Azure Synapse Lakehouse Sync artifacts including: 

- Synapse Workspace Pipelines
- Synapse Workspace Linked Services
- Synapse Workspace Datasets
- Synapse Dedicated SQL Pool
- Databricks Workspace Notebooks
- Databricks Workspace Cluster
- Azure Key Vault / Azure Data Lake Storage Access Keys
- Databricks Workspace / Azure Key Vault Secret Scope
- Sample Data

# How to use Azure Synapse Lakehouse Sync Tutorial