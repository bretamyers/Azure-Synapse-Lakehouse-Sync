#!/bin/bash
#
# This script is in two parts; Environment Deployment and Post-Deployment Configuration. While there appears
# to be alot going on here, it's mostly error handling for various scenarios that can arise. We're really
# just deploying the environment via Bicep, running a few queries against Synapse, and deploying a few
# Synapse pipeline and Databricks artifacts.
#
#   Part 1: Environment Deployment
#
#       This performs a Bicep template deployment if it wasn't done manually. The Bicep template creates a 
#       Databricks Workspace, Azure Data Lake Storage Gen2, and a Synapse Analytics Workspace.
#
#   Part 2: Post-Deployment Configuration
#
#       These are post-deployment configurations done at the data plan level which is beyond the scope of what  
#       Bicep is capable of managing or would normally manage. Database settings are made, sample data is copied, 
#       notebooks are copied, and pipelines are created.
#
#       These steps to make use of other dependencies such as Azure CLI and sqlcmd hence why it's easier to 
#       execute via the Azure Cloud Shell.
#
#   This script should be executed via the Azure Cloud Shell (https://shell.azure.com):
#
#       @Azure:~/Azure-Synapse-Lakehouse-Sync$ bash deploySynapseSync.sh
#

################################################################################
# Part 1: Environment Deployment                                               #
################################################################################

bicepDeploymentName="Azure-Synapse-Lakehouse-Sync"
deploymentLogFile="deploySynapseSync.log"

declare -A accountDetails
declare -A bicepDeploymentDetails

# Function to check the Bicep deployment state since we check multiple times
checkBicepDeploymentState () {
    bicepDeploymentCheck=$(az deployment sub show --name ${bicepDeploymentName} --query properties.provisioningState --output tsv 2>&1 | sed 's/[[:space:]]*//g')
    if [ "$bicepDeploymentCheck" = "Succeeded" ]; then
        echo "Succeeded"
    elif [ "$bicepDeploymentCheck" = "Failed" ] || [ "$bicepDeploymentCheck" = "Canceled" ]; then
        echo "Failed"
    elif [[ $bicepDeploymentCheck == *"DeploymentNotFound"* ]]; then
        echo "DeploymentNotFound"
    fi
}

# Function to output messages to both the user terminal and the log file
function userOutput () {
    echo "$(date) [${1}] ${2}" >> $deploymentLogFile
    echo "${2}" > /dev/tty
}

# Try and determine if we're executing from within the Azure Cloud Shell
if [ ! "${AZUREPS_HOST_ENVIRONMENT}" = "cloud-shell/1.0" ]; then
    output "ERROR" "It doesn't appear you are executing this from the Azure Cloud Shell. Please use the Azure Cloud Shell at https://shell.azure.com"
    exit 1;
fi

# Try and get a token to validate that we're logged into Azure CLI
aadToken=$(az account get-access-token --resource=https://dev.azuresynapse.net --query accessToken --output tsv 2>&1 | sed 's/[[:space:]]*//g')
if [[ $aadToken == *"ERROR"* ]]; then
    userOutput "ERROR" "You don't appear to be logged in to Azure CLI. Please login to the Azure CLI using 'az login'"
    exit 1;
fi

# Get environment details
accountDetails[azureSubscriptionName]=$(az account show --query name --output tsv 2>&1 | sed 's/[[:space:]]*//g')
accountDetails[azureSubscriptionID]=$(az account show --query id --output tsv 2>&1 | sed 's/[[:space:]]*//g')
accountDetails[azureUsername]=$(az account show --query user.name --output tsv 2>&1 | sed 's/[[:space:]]*//g')
accountDetails[azureUsernameObjectId]=$(az ad user show --id ${accountDetails[azureUsername]} --query id --output tsv 2>&1 | sed 's/[[:space:]]*//g')

for value in "${accountDetails[@]}"; do 
    if [ "${value}" = "" ]; then
        userOutput "ERROR" "Unable to get Azure account details needed for deployment."
        exit 1;
    fi
done

# Display some environment details to the user
userOutput "INFO" "Azure Subscription: ${accountDetails[azureSubscriptionName]}"
userOutput "INFO" "Azure Subscription ID: ${accountDetails[azureSubscriptionID]}"
userOutput "INFO" "Azure AD Username: ${accountDetails[azureUsername]}"
userOutput "INFO" "Azure AD User Object Id: ${accountDetails[azureUsernameObjectId]}"

# Update a Bicep variable if it isn't configured by the user. This allows Bicep to add the user Object Id
# to the Storage Blob Data Contributor role on the Azure Data Lake Storage Gen2 account, which allows Synapse
# Serverless SQL to query files on storage.
sed -i "s/REPLACE_SYNAPSE_AZURE_AD_ADMIN_OBJECT_ID/${accountDetails[azureUsernameObjectId]}/g" Bicep/main.parameters.json 2>&1

# Check to see if the Bicep deployment was already completed manually. If not, lets do it.
if [ $(checkBicepDeploymentState) = "DeploymentNotFound" ]; then
    # Get the Azure Region from the Bicep main.parameters.json
    bicepAzureRegion=$(jq -r .parameters.azureRegion.value Bicep/main.parameters.json 2>&1 | sed 's/[[:space:]]*//g')

    # Bicep deployment via Azure CLI
    userOutput "INFO" "Deploying environment via Bicep. This will take several minutes..."
    bicepDeploy=$(az deployment sub create --template-file Bicep/main.bicep --parameters Bicep/main.parameters.json --name ${bicepDeploymentName} --location ${bicepAzureRegion} 2>&1 | tee -a $deploymentLogFile)
else
    userOutput "INFO" "It appears the Bicep deployment was done manually. Skipping..."
fi

# Make sure the Bicep deployment was successful 
if [ $(checkBicepDeploymentState) = "Failed" ]; then
    userOutput "ERROR" "It looks like a Bicep deployment was attempted but failed."
    exit 1;
fi

################################################################################
# Part 2: Post-Deployment Configuration                                        #
################################################################################

bicepOutputVariables=("resourceGroup" "synapseAnalyticsWorkspaceName" "synapseSQLPoolName" "synapseSQLAdministratorLogin" "databricksWorkspaceName" "databricksWorkspaceUrl" "databricksWorkspaceId" "datalakeName" "keyVaultVaultUri" "keyVaultId")

# Get the output variables from the Bicep deployment
for bicepVariable in "${bicepOutputVariables[@]}"; do 
    bicepDeploymentDetails[${bicepVariable}]=$(az deployment sub show --name ${bicepDeploymentName} --query properties.outputs.${bicepVariable}.value --output tsv 2>&1 | sed 's/[[:space:]]*//g')
done

# Get the Synapse AQL Administrator Login Password from the Bicep main.parameters.json
bicepDeploymentDetails[synapseSQLAdministratorLoginPassword]=$(jq -r .parameters.synapseSQLAdministratorLoginPassword.value Bicep/main.parameters.json 2>&1 | sed 's/[[:space:]]*//g')

# Get the Databricks Workspace Azure AD accessToken for authentication
databricksAccessToken=$(az account get-access-token --resource 2ff814a6-3304-4ab8-85cb-cd0e6f879c1d --output tsv --query accessToken 2>&1 | sed 's/[[:space:]]*//g')

# Display the deployment details to the user
userOutput "INFO" "Resource Group: ${bicepDeploymentDetails[resourceGroup]}"
userOutput "INFO" "Synapse Analytics Workspace: ${bicepDeploymentDetails[synapseAnalyticsWorkspaceName]}"
userOutput "INFO" "Synapse Analytics SQL Admin: ${bicepDeploymentDetails[synapseSQLAdministratorLogin]}"
userOutput "INFO" "Databricks Workspace: ${bicepDeploymentDetails[databricksWorkspaceName]}"
userOutput "INFO" "Data Lake Name: ${bicepDeploymentDetails[datalakeName]}"

################################################################################
# Databricks Workspace Settings                                                #
################################################################################

# Create the Azure Key Vault Scope in the Databricks Workspace
userOutput "INFO" "Creating the Databricks Workspace Azure Key Vault Scope..."
createDatabricksKeyVaultScope=$(az rest --method post --url https://${bicepDeploymentDetails[databricksWorkspaceUrl]}/api/2.0/secrets/scopes/create --body "{ \"scope\": \"DataLakeStorageKey\", \"scope_backend_type\": \"AZURE_KEYVAULT\", \"backend_azure_keyvault\": { \"resource_id\": \"${bicepDeploymentDetails[keyVaultId]}\", \"dns_name\": \"${bicepDeploymentDetails[keyVaultVaultUri]}\" }, \"initial_manage_principal\": \"users\" }" --headers "{\"Authorization\":\"Bearer ${databricksAccessToken}\"}" 2>&1 | tee -a $deploymentLogFile)

# Create the Databricks Cluster
userOutput "INFO" "Creating the Databricks Workspace Cluster definition..."
createDatabricksCluster=$(az rest --method post --url https://${bicepDeploymentDetails[databricksWorkspaceUrl]}/api/2.0/clusters/create --body "@../Azure Synapse Lakehouse Sync/Databricks/Cluster Definition/SynapseLakehouseSyncCluster.json" --headers "{\"Authorization\":\"Bearer ${databricksAccessToken}\"}" --query cluster_id --output tsv 2>&1 | sed 's/[[:space:]]*//g')

################################################################################
# Databricks Workspace Notebooks                                               #
################################################################################

userOutput "INFO" "Creating the Databricks Workspace Notebooks..."

# Create the Databricks Workspace folders for the notebooks
for databricksNotebookFolder in '../Azure Synapse Lakehouse Sync/Databricks/Notebooks'/*/
do
    workspaceFolder=$(awk -F/ '{ print $(NF-1) }' <<< ${databricksNotebookFolder})
    databricksNotebookCreate=$(az rest --method post --url https://${bicepDeploymentDetails[databricksWorkspaceUrl]}/api/2.0/workspace/mkdirs --body "{ \"path\": \"/${workspaceFolder}\" }" --headers "{ \"Authorization\": \"Bearer ${databricksAccessToken}\", \"Content-Type\": \"application/json\" }" 2>&1 | tee -a $deploymentLogFile)
done

# Create the Databricks Workspace notebooks
for databricksNotebook in '../Azure Synapse Lakehouse Sync/Databricks/Notebooks'/*/*.dbc
do
    # Parse out the notebook file and path names
    databricksNotebookPath=${databricksNotebook%/*}
    databricksNotebookFolder=$(awk -F/ '{ print $(NF-1) }' <<< ${databricksNotebook})
    databricksNotebookName=$(basename "${databricksNotebook}" .dbc)

    # Base64 encode the notebook and POST to the Databricks Workspace API
    databricksNotebookBase64=$(base64 -w 0 "${databricksNotebook}" 2>&1 | sed 's/[[:space:]]*//g')
    echo "{ \"path\": \"/${databricksNotebookFolder}/${databricksNotebookName}\", \"content\": \"${databricksNotebookBase64}\", \"format\": \"DBC\" }" > "${databricksNotebook}.json.tmp"
    databricksNotebookCreate=$(az rest --method post --url https://${bicepDeploymentDetails[databricksWorkspaceUrl]}/api/2.0/workspace/import --body "@${databricksNotebook}.json.tmp" --headers "{ \"Authorization\": \"Bearer ${databricksAccessToken}\", \"Content-Type\": \"application/json\" }" 2>&1 | tee -a $deploymentLogFile)
    rm "${databricksNotebook}.json.tmp"
done

################################################################################
# Synapse Queries                                                              #
################################################################################

userOutput "INFO" "Executing Synapse Queries..."

# Execute one query against master
executeQuery=$(sqlcmd -U ${bicepDeploymentDetails[synapseSQLAdministratorLogin]} -P ${bicepDeploymentDetails[synapseSQLAdministratorLoginPassword]} -S tcp:${bicepDeploymentDetails[synapseAnalyticsWorkspaceName]}.sql.azuresynapse.net -d master -I -Q "ALTER DATABASE ${bicepDeploymentDetails[synapseSQLPoolName]} SET RESULT_SET_CACHING ON;" 2>&1 | tee -a $deploymentLogFile)

# Validate the Synapse Dedicated SQL Pool is running and we were able to establish a connection
if [[ $executeQuery == *"Cannot connect to database when it is paused"* ]]; then
    userOutput "ERROR" "The Synapse Dedicated SQL Pool is paused. Please resume the pool and run this script again."
    exit 1;
elif [[ $executeQuery == *"Login timeout expired"* ]]; then
    userOutput "ERROR" "Unable to connect to the Synapse Dedicated SQL Pool. The exact reason is unknown."
    exit 1;
fi

# Execute all other queries against the new database
for synapseQuery in '../Azure Synapse Lakehouse Sync/Synapse/Queries'/*.sql
do
    executeQuery=$(sqlcmd -U ${bicepDeploymentDetails[synapseSQLAdministratorLogin]} -P ${bicepDeploymentDetails[synapseSQLAdministratorLoginPassword]} -S tcp:${bicepDeploymentDetails[synapseAnalyticsWorkspaceName]}.sql.azuresynapse.net -d ${bicepDeploymentDetails[synapseSQLPoolName]} -I -i "${synapseQuery}" 2>&1 | tee -a $deploymentLogFile)
done

################################################################################
# Synapse Workspace Linked Services                                            #
################################################################################

userOutput "INFO" "Creating the Synapse Workspace Linked Services..."

for synapseLinkedService in '../Azure Synapse Lakehouse Sync/Synapse/Linked Services'/*.json
do
    # Parse out the Link Service file and path names
    synapseLinkedServicePath=${synapseLinkedService%/*}
    synapseLinkedServiceName=$(basename "${synapseLinkedService}" .json)

    cp "${synapseLinkedService}" "${synapseLinkedService}.tmp" 2>&1
    sed -i "s|REPLACE_DATABRICKS_WORKSPACE_URL|https://${bicepDeploymentDetails[databricksWorkspaceUrl]}|g" "${synapseLinkedService}.tmp"
    sed -i "s|REPLACE_DATABRICKS_WORKSPACE_ID|${bicepDeploymentDetails[databricksWorkspaceId]}|g" "${synapseLinkedService}.tmp"
    sed -i "s|REPLACE_DATABRICKS_CLUSTER_ID|${createDatabricksCluster}|g" "${synapseLinkedService}.tmp"

    createLinkedService=$(az synapse linked-service create --workspace-name ${bicepDeploymentDetails[synapseAnalyticsWorkspaceName]} --name "${synapseLinkedServiceName}" --file @"${synapseLinkedService}.tmp" 2>&1 | tee -a $deploymentLogFile)
    rm "${synapseLinkedService}.tmp"
done

################################################################################
# Synapse Workspace Datasets                                                   #
################################################################################

userOutput "INFO" "Creating the Synapse Workspace Datasets..."

for synapseDataSet in '../Azure Synapse Lakehouse Sync/Synapse/Datasets'/*.json
do
    # Parse out the Dataset file and path names
    synapseDataSetPath=${synapseDataSet%/*}
    synapseDataSeteName=$(basename "${synapseDataSet}" .json)

    createDataSet=$(az synapse dataset create --workspace-name ${bicepDeploymentDetails[synapseAnalyticsWorkspaceName]} --name "${synapseDataSeteName}" --file @"${synapseDataSet}" 2>&1 | tee -a $deploymentLogFile)
done

################################################################################
# Synapse Workspace Pipelines                                                  #
################################################################################

userOutput "INFO" "Creating the Synapse Lakehouse Sync Pipelines..."

for synapsePipeline in '../Azure Synapse Lakehouse Sync/Synapse/Pipelines'/*.json
do
    # Parse out the Pipeline file and path names
    synapsePipelineName=$(jq -r .name "${synapsePipeline}" 2>&1 | sed 's/[[:space:]]*//g')

    cp "${synapsePipeline}" "${synapsePipeline}.tmp" 2>&1
    sed -i "s|REPLACE_DATALAKE_NAME|${bicepDeploymentDetails[datalakeName]}|g" "${synapsePipeline}.tmp"
    sed -i "s|REPLACE_SYNAPSE_ANALYTICS_SQL_POOL_NAME|${bicepDeploymentDetails[synapseSQLPoolName]}|g" "${synapsePipeline}.tmp"

    createLinkedService=$(az synapse pipeline create --workspace-name ${bicepDeploymentDetails[synapseAnalyticsWorkspaceName]} --name "${synapsePipelineName}" --file @"${synapsePipeline}.tmp" 2>&1 | tee -a $deploymentLogFile)
    rm "${synapsePipeline}.tmp"
done

################################################################################
# Sample Data                                                                  #
################################################################################

# Generate a SAS for the data lake so we can upload some files
tomorrowsDate=$(date --date="tomorrow" +%Y-%m-%d)
destinationStorageSAS=$(az storage container generate-sas --account-name ${bicepDeploymentDetails[datalakeName]} --name data --permissions rwal --expiry ${tomorrowsDate} --only-show-errors --output tsv 2>&1 | sed 's/[[:space:]]*//g')
sampleDataStorageSAS="?sv=2021-06-08&st=2022-08-01T04%3A00%3A00Z&se=2023-08-01T04%3A00%3A00Z&sr=c&sp=rl&sig=DjC4dPo5AKYkNFplik2v6sH%2Fjhl2k1WTzna%2F1eV%2BFv0%3D"

# Copy sample data
userOutput "INFO" "Copying the sample data..."
sampleDataCopy=$(az storage copy -s "https://synapseanalyticspocdata.blob.core.windows.net/sample/Synapse Lakehouse Sync/AdventureWorks_changes/${sampleDataStorageSAS}" -d "https://${bicepDeploymentDetails[datalakeName]}.blob.core.windows.net/data/Sample?${destinationStorageSAS}" --recursive 2>&1 >> $deploymentLogFile)
sampleDataCopy=$(az storage copy -s "https://synapseanalyticspocdata.blob.core.windows.net/sample/Synapse Lakehouse Sync/AdventureWorks_parquet/${sampleDataStorageSAS}" -d "https://${bicepDeploymentDetails[datalakeName]}.blob.core.windows.net/data/Sample?${destinationStorageSAS}" --recursive 2>&1 >> $deploymentLogFile)

# Update the Auto Loader Metadata file template with the correct storage account and then upload it
sed -i "s/REPLACE_DATALAKE_NAME/${bicepDeploymentDetails[datalakeName]}/g" "../Azure Synapse Lakehouse Sync/Synapse/Synapse_Lakehouse_Sync_Metadata.csv"
sampleDataCopy=$(az storage copy -s "../Azure Synapse Lakehouse Sync/Synapse/Synapse_Lakehouse_Sync_Metadata.csv" -d "https://${bicepDeploymentDetails[datalakeName]}.blob.core.windows.net/data?${destinationStorageSAS}" 2>&1 >> $deploymentLogFile)

userOutput "INFO" "Deployment Complete!"
