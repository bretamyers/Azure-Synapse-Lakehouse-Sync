# Description

Feel free to reference this Bicep template and use it for your own purposes, but deploying the Azure Synapse Lakehouse Sync tutorial environment should be done via the deployTutorial.sh bash script. The Bash script will deploy this Bicep template therefore the tutorial environment, but also artifacts which Bicep cannot deploy such as Synapse Workspace pipelines and Databricks Workspace notebooks.

```
@Azure:~$ git clone https://github.com/bretamyers/Azure-Synapse-Lakehouse-Sync
@Azure:~$ cd 'Azure-Synapse-Lakehouse-Sync/Tutorial Environment'
@Azure:~$ bash deployTutorial.sh 
```
