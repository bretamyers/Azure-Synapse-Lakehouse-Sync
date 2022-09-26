# Azure Synapse Lakehouse Sync: Tutorial Environment

Whether you're new to the data lake & lakehouse pattern, or exploring how Synapse Lakehouse Sync would work in your environment, this will deploy an end-to-end tutorial environment. We wanted to provide an easy option for you to evaluate and understand how Azure Synapse Lakehouse Sync works with little effort.


# How to Deploy

The following commands should be executed from the Azure Cloud Shell at https://shell.azure.com using Bash. This will deploy the full tutorial environment with no additional configuration needed.

```
@Azure:~$ git clone https://github.com/bretamyers/Azure-Synapse-Lakehouse-Sync
@Azure:~$ cd Azure-Synapse-Lakehouse-Sync
@Azure:~$ cd Tutorial Environment
@Azure:~$ bash deployTutorial.sh 
```

# What's Deployed

#### Azure Synapse Analytics Workspace
- **DW1000 Dedicated SQL Pool:** Primary data warehouse Enterprise Data Lake Gold Zone changes are synchronized to
- **DW100 Dedicated SQL Pool:** Example of a second data warehouse where only some tables are synchronized from the same Enterprise Data Lake Gold Zone
- Azure Synapse Lakehouse Sync Pipelines

#### Azure Databricks Workspace
- Small Cluster
- Azure Synapse Lakehouse Sync Notebooks

#### Azure Data Lake Storage Gen2: Synapse Workspace
- **workspace:** Container for the Azure Synapse Analytics Workspace
- **synapsesync:** Container for Azure Synapse Lakehouse Sync change history from the Enterprise Data Lake Gold Zone. It also contains the **Synapse_Lakehouse_Sync_Metadata.csv** file which instructs Azure Synapse Lakehouse Sync on the tables that need to be synchronized.

#### Azure Data Lake Storage Gen2: Enterprise Data Lake
- **gold:** Container for the Enterprise Data Lake Gold Zone which includes the sample data

#### Azure Key Vault
- Secure storage for Azure Data Lake access keys and used by Databricks for authentication

# What's Configured
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
- After the deployment of the example environment through the Azure Cloud Shell has completed successfully, make note of the Synapse workspace name that was created and  navigate to the synapse workspace by going [web.azuresynapse.net](web.azuresynapse.net) and selecting the newly deployed workspace from the drop downs.
![image](https://user-images.githubusercontent.com/14877390/192293164-3a99cef1-c0ae-448c-9d17-9dbbf408c496.png)
- Once in the Synapse workspace, navigate to the <b>Integrate</b> tab on the toolbar to the left and drill down to the <b>SynapseLakehouseSync_Tutorial</b> pipeline in the <b>Synapse Lakehouse Sync Tutorial</b> folder.
![image](https://user-images.githubusercontent.com/14877390/192293954-8dee54db-aec4-4e39-9096-936545d2cd94.png)
![image](https://user-images.githubusercontent.com/14877390/192295166-2f908cd8-674d-484c-b723-48226b57c89e.png)
- In the <b>SynapseLakehouseSync_Tutorial</b> pipeline, click on the <b>Add trigger</b> button in the top toolbar and select <b>Trigger now</b> and hit <b>OK<b> in the popup window. This will trigger the execution of the tutorial pipeline.
![image](https://user-images.githubusercontent.com/14877390/192295875-d731ed9c-1ce1-43f8-8bc9-c187ca60448b.png)
![image](https://user-images.githubusercontent.com/14877390/192296498-197f406b-c144-4bfe-a848-2f2ac3cea9cc.png)



