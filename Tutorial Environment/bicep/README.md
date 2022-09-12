# Description

Feel free to reference this Bicep template and use it for your own purposes, but deploying the Azure Synapse Lakehouse Sync tutorial environment should be done via the deploySynapseSync.sh bash script. The Bash script will deploy this Bicep template and deploy the environment, but also deploy artifacts which Bicep cannot deploy such as Synapse Workspace pipelines and Databricks Workspace notebooks.

```
@Azure:~$ git clone https://github.com/bretamyers/Azure-Synapse-Lakehouse-Sync
@Azure:~$ cd Azure-Synapse-Lakehouse-Sync
@Azure:~$ cd Tutorial Environment
@Azure:~$ bash deployTutorial.sh 
```
