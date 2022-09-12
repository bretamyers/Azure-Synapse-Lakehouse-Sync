# Azure Synapse Lakehouse Sync: Tutorial Environment

Whether you're new to the data lake & lakehouse pattern, or exploring how Synapse Lakehouse Sync would work in your environment, this will deploy an end-to-end tutorial environment. We wanted to provide an easy option for you to evaluate and understand how Azure Synapse Lakehouse Sync works with little effort.


# How to Deploy

### "Easy Button" Deployment
The following commands should be executed from the Azure Cloud Shell at https://shell.azure.com using Bash:

```
@Azure:~$ git clone https://github.com/bretamyers/Azure-Synapse-Lakehouse-Sync
@Azure:~$ cd Azure-Synapse-Lakehouse-Sync
@Azure:~$ cd Tutorial Environment
@Azure:~$ bash deployTutorial.sh 
```

## What's Deployed

### Azure Synapse Analytics Workspace
- **DW1000 Dedicated SQL Pool:** Primary data warehouse Enterprise Data Lake Gold Zone changes are synchronized to
- **DW100 Dedicated SQL Pool:** Example of a second data warehouse were only some tables are synchronized but from the same Enterprise Data Lake Gold Zone
- Azure Synapse Lakehouse Sync Pipelines

### Azure Databricks Workspace
- Small Cluster
- Azure Synapse Lakehouse Sync Notebooks

### Azure Data Lake Storage Gen2: Synapse Workspace
- **workspace:** Container for the Azure Synapse Analytics Workspace
- **<b>**synapsesync:**</b>** Container for Azure Synapse Lakehouse Sync change history from the Enterprise Data Lake Gold Zone

### Azure Data Lake Storage Gen2: Enterprise Data Lake
- **gold:** Container for the Enterprise Data Lake Gold Zone

### Azure Key Vault
- Secure storage for Azure Data Lake access keys and used by Databricks for authentication

## What's Configured
The **deployTutorial.sh** script will execute a Bicep deployment for the environment and then configure the environment with the Azure Synapse Lakehouse Sync artifacts including: 

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