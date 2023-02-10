#!/bin/bash
#
# This script is in two parts; Tutorial Environment Deployment and Post-Deployment Configuration. While there appears
# to be alot going on here, it's mostly error handling for various scenarios that can arise. We're really
# just deploying the environment via Bicep, running a few queries against Synapse, and deploying a few
# Synapse pipeline and Databricks artifacts.
#
#   Part 1: Tutorial Environment Deployment
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
#       @Azure:~/Azure-Synapse-Lakehouse-Sync$ bash deployTutorial.sh
#

################################################################################
# Part 1: Tutorial Environment Deployment                                      #
################################################################################

bicepDeploymentName="Azure-Synapse-Lakehouse-Sync"
deploymentLogFile="deployment.log"
synapseDeployFlag=${1:-no}

declare -A accountDetails
declare -A bicepDeploymentDetails

# Function to check the Bicep deployment state since we check multiple times
checkBicepDeploymentState () {
    bicepDeploymentCheck=$(az deployment sub show --name ${bicepDeploymentName} --query properties.provisioningState --output tsv 2>&1 | sed 's/[[:space:]]*//g')
    if [ "${bicepDeploymentCheck}" = "Succeeded" ]; then
        echo "Succeeded"
    elif [ "${bicepDeploymentCheck}" = "Failed" ] || [ "${bicepDeploymentCheck}" = "Canceled" ]; then
        echo "Failed"
    elif [[ "${bicepDeploymentCheck}" == *"DeploymentNotFound"* ]]; then
        echo "DeploymentNotFound"
    fi
}

# Function to check if Azure Key Vault was deleted but not purged
checkKeyVaultDeploymentState () {
    keyVaultName=$(az deployment sub show --name ${bicepDeploymentName} --query properties.outputs.keyVaultName.value --output tsv 2>&1 | sed 's/[[:space:]]*//g')
    keyVaultState=$(az keyvault list-deleted --query "[?name=='${keyVaultName}'].{name:name}" --output tsv 2>&1 | sed 's/[[:space:]]*//g')

    if [[ ! "${keyVaultName}" == *"DeploymentNotFound"* ]] && [ ! "${keyVaultName}" = "" ]; then
        if [ "${keyVaultState}" = "${keyVaultName}" ]; then
            echo "DeletedNotPurged" "${keyVaultName}"
        else
            echo "NotDeletedNotPurged"
        fi
    else
        echo "DoesNotExist"
    fi
}

# Function to output messages to both the user terminal and the log file
function userOutput () {
    CLEAR="\e[0m"
    BLUE_BOLD="\e[1;34m"
    RED_BOLD="\e[1;31m"
    GREEN_BOLD="\e[1;32m"

    # Log file output
    echo "$(date) [${1}] ${2} ${3}" >> $deploymentLogFile

    # Terminal output
    if [ "${1}" = "ERROR" ]; then
        echo -e "${RED_BOLD}ERROR:${CLEAR} ${2}" > /dev/tty
    elif [ "${1}" = "STATUS" ]; then
        echo -e "${2}" > /dev/tty
    elif [ "${1}" = "RESULT" ]; then
        echo -e "${BLUE_BOLD}${2}${CLEAR} ${3}" > /dev/tty
    elif [ "${1}" = "DEPLOYMENT" ]; then
        echo -e "\n${BLUE_BOLD}${2}${GREEN_BOLD} ${3}" > /dev/tty
    fi
}

# Validate if the passed value is a GUID
function validateGUID () {
    if [[ ${1} =~ ^\{?[A-F0-9a-f]{8}-[A-F0-9a-f]{4}-[A-F0-9a-f]{4}-[A-F0-9a-f]{4}-[A-F0-9a-f]{12}\}?$ ]]; then
        echo "true"
    else
        echo "false"
    fi
}

# Try and determine if we're executing from within the Azure Cloud Shell
if [ ! "${AZUREPS_HOST_ENVIRONMENT}" = "cloud-shell/1.0" ]; then
    output "ERROR" "It doesn't appear you are executing this from the Azure Cloud Shell. Please use Bash in the Azure Cloud Shell at https://shell.azure.com"
    exit 1;
fi

# Try and get a token to validate that we're logged into Azure CLI
aadToken=$(az account get-access-token --resource=https://dev.azuresynapse.net --query accessToken --output tsv 2>&1 | sed 's/[[:space:]]*//g')
if [[ "${aadToken}" == *"ERROR"* ]]; then
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

# Get the users Azure AD Object Id from the Bicep main.parameters.json
#azureUsernameObjectId=$(jq -r .parameters.synapseAzureADAdminObjectId.value bicep/main.parameters.json 2>&1 | sed 's/[[:space:]]*//g')

# Validate the users Azure AD Object Id is a valid GUID or that the value was manually set in main.parameters.json
#if [ $(validateGUID ${accountDetails[azureUsernameObjectId]}) = "false" ]; then
#    if [ $(validateGUID ${azureUsernameObjectId}) = "false" ]; then
    if [ $(validateGUID ${accountDetails[azureUsernameObjectId]}) = "false" ]; then
        userOutput "ERROR" "Unable to fetch the Azure AD Object Id for your user. Are you using an Azure AD Guest/External Account? This is not currently supported."
        exit 1;
    fi
#    else
#        accountDetails[azureUsernameObjectId]=${azureUsernameObjectId}
#    fi
#fi

# Display some environment details to the user
userOutput "RESULT" "Azure Subscription:" ${accountDetails[azureSubscriptionName]}
userOutput "RESULT" "Azure Subscription ID:" ${accountDetails[azureSubscriptionID]}
userOutput "RESULT" "Azure AD Username:" ${accountDetails[azureUsername]}
userOutput "RESULT" "Azure AD User Object Id:" ${accountDetails[azureUsernameObjectId]}

# Copy bicep parameters files to a temp location
cp bicep/main.parameters.json bicep/main.parameters_tmp.json 2>&1

# Update a Bicep variable if it isn't configured by the user. This allows Bicep to add the user Object Id
# to the Storage Blob Data Contributor role on the Azure Data Lake Storage Gen2 account, which allows Synapse
# Serverless SQL to query files on storage.
sed -i "s/REPLACE_SYNAPSE_AZURE_AD_ADMIN_OBJECT_ID/${accountDetails[azureUsernameObjectId]}/g" bicep/main.parameters.json 2>&1

# Update a Bicep variable to determine if its a Synapse only and Synapse and Databricks deployment.
sed -i "s/REPLACE_SYNAPSE_DEPLOY_FLAG/${synapseDeployFlag}/g" bicep/main.parameters.json 2>&1


# Make sure Azure Key Vault was not deleted but also not purged. Bicep will throw an error if it's in the purged state.
read keyVaultState keyVaultName < <(checkKeyVaultDeploymentState)
if [ "${keyVaultState}" = "DeletedNotPurged" ]; then
    userOutput "ERROR" "Azure Key Vault was previously created by this deployment and deleted, but not purged. You must manually purge the previous Key Vault via 'az keyvault purge --name ${keyVaultName}' before it can be deployed again."
    exit 1;
fi

# Get the Azure Region from the Bicep main.parameters.json
bicepAzureRegion=$(jq -r .parameters.azureRegion.value bicep/main.parameters.json 2>&1 | sed 's/[[:space:]]*//g')

# Bicep deployment via Azure CLI
userOutput "STATUS" "Deploying environment via Bicep. This may take several minutes..."
bicepDeploy=$(az deployment sub create --template-file bicep/main.bicep --parameters bicep/main.parameters.json --name ${bicepDeploymentName} --location ${bicepAzureRegion} 2>&1 | tee -a $deploymentLogFile)

# Make sure the Bicep deployment was successful 
if [ $(checkBicepDeploymentState) = "Failed" ]; then
    userOutput "ERROR" "The Bicep deployment was attempted but failed. You can view further details by going to Subscriptions -> ${accountDetails[azureSubscriptionName]} -> Deployments in the Azure portal."
    exit 1;
fi

################################################################################
# Part 2: Post-Deployment Configuration                                        #
################################################################################

bicepOutputVariables=("resourceGroup" "synapseAnalyticsWorkspaceName" "synapseStorageAccountName" "enterpriseDataLakeStorageAccountName" "synapseSQLPoolName" "synapseSQLSecondPoolName" "synapseSparkPoolName" "synapseSQLAdministratorLogin" "databricksWorkspaceName" "databricksWorkspaceUrl" "databricksWorkspaceId" "keyVaultVaultUri" "keyVaultId")

# Get the output variables from the Bicep deployment
for bicepVariable in "${bicepOutputVariables[@]}"; do 
    bicepDeploymentDetails[${bicepVariable}]=$(az deployment sub show --name ${bicepDeploymentName} --query properties.outputs.${bicepVariable}.value --output tsv 2>&1 | sed 's/[[:space:]]*//g')
done

for value in "${bicepDeploymentDetails[@]}"; do 
    if [ "${value}" = "" ]; then
        userOutput "ERROR" "Unable to get Bicep deployment details."
        exit 1;
    fi
done

# Get the Synapse AQL Administrator Login Password from the Bicep main.parameters.json
bicepDeploymentDetails[synapseSQLAdministratorLoginPassword]=$(jq -r .parameters.synapseSQLAdministratorLoginPassword.value bicep/main.parameters.json 2>&1 | sed 's/[[:space:]]*//g')

if [ $synapseDeployFlag = 'no' ];
then
    # Get the Databricks Workspace Azure AD accessToken for authentication
    databricksAccessToken=$(az account get-access-token --resource 2ff814a6-3304-4ab8-85cb-cd0e6f879c1d --output tsv --query accessToken 2>&1 | sed 's/[[:space:]]*//g')

    ################################################################################
    # Databricks Workspace Settings                                                #
    ################################################################################

    # Create the Azure Key Vault Scope in the Databricks Workspace
    userOutput "STATUS" "Creating the Databricks Workspace Azure Key Vault Scope..."
    databricksScopeName="AzureKeyVaultScope"
    createDatabricksKeyVaultScope=$(az rest --method post --url https://${bicepDeploymentDetails[databricksWorkspaceUrl]}/api/2.0/secrets/scopes/create --body "{ \"scope\": \"${databricksScopeName}\", \"scope_backend_type\": \"AZURE_KEYVAULT\", \"backend_azure_keyvault\": { \"resource_id\": \"${bicepDeploymentDetails[keyVaultId]}\", \"dns_name\": \"${bicepDeploymentDetails[keyVaultVaultUri]}\" }, \"initial_manage_principal\": \"users\" }" --headers "{\"Authorization\":\"Bearer ${databricksAccessToken}\"}" 2>&1 | tee -a $deploymentLogFile)

    # Create the Databricks Cluster
    userOutput "STATUS" "Creating the Databricks Workspace Cluster definition..."
    createDatabricksCluster=$(az rest --method post --url https://${bicepDeploymentDetails[databricksWorkspaceUrl]}/api/2.0/clusters/create --body "@../Azure Synapse Lakehouse Sync/Databricks/Cluster Definition/SynapseLakehouseSyncCluster.json" --headers "{\"Authorization\":\"Bearer ${databricksAccessToken}\"}" --query cluster_id --output tsv 2>&1 | sed 's/[[:space:]]*//g')

    ################################################################################
    # Databricks Workspace Notebooks                                               #
    ################################################################################

    userOutput "STATUS" "Creating the Databricks Workspace Notebooks..."

    # Create the Databricks Workspace folders for the notebooks
    for databricksNotebookFolder in '../Azure Synapse Lakehouse Sync/Databricks Version/Databricks/Notebooks'/*/
    do
        workspaceFolder=$(awk -F/ '{ print $(NF-1) }' <<< ${databricksNotebookFolder})
        databricksNotebookCreate=$(az rest --method post --url https://${bicepDeploymentDetails[databricksWorkspaceUrl]}/api/2.0/workspace/mkdirs --body "{ \"path\": \"/${workspaceFolder}\" }" --headers "{ \"Authorization\": \"Bearer ${databricksAccessToken}\", \"Content-Type\": \"application/json\" }" 2>&1 | tee -a $deploymentLogFile)
    done

    # Create the Databricks Workspace notebooks
    for databricksNotebook in '../Azure Synapse Lakehouse Sync/Databricks Version/Databricks/Notebooks'/*/*.dbc
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
fi

################################################################################
# Synapse Queries                                                              #
################################################################################

userOutput "STATUS" "Executing Synapse Queries..."

# Execute one query against master
executeQuery=$(sqlcmd -U ${bicepDeploymentDetails[synapseSQLAdministratorLogin]} -P ${bicepDeploymentDetails[synapseSQLAdministratorLoginPassword]} -S tcp:${bicepDeploymentDetails[synapseAnalyticsWorkspaceName]}.sql.azuresynapse.net -d master -I -Q "ALTER DATABASE ${bicepDeploymentDetails[synapseSQLPoolName]} SET RESULT_SET_CACHING ON;" 2>&1 | tee -a $deploymentLogFile)
executeQuery=$(sqlcmd -U ${bicepDeploymentDetails[synapseSQLAdministratorLogin]} -P ${bicepDeploymentDetails[synapseSQLAdministratorLoginPassword]} -S tcp:${bicepDeploymentDetails[synapseAnalyticsWorkspaceName]}.sql.azuresynapse.net -d master -I -Q "ALTER DATABASE ${bicepDeploymentDetails[synapseSQLSecondPoolName]} SET RESULT_SET_CACHING ON;" 2>&1 | tee -a $deploymentLogFile)

# Validate the Synapse Dedicated SQL Pool is running and we were able to establish a connection
if [[ "${executeQuery}" == *"Cannot connect to database when it is paused"* ]]; then
    userOutput "ERROR" "The Synapse Dedicated SQL Pool is paused. Please resume the pool and run this script again."
    exit 1;
elif [[ "${executeQuery}" == *"Login timeout expired"* ]]; then
    userOutput "ERROR" "Unable to connect to the Synapse Dedicated SQL Pool. The exact reason is unknown but you can check ${deploymentLogFile} for details."
    exit 1;
fi

# Execute all other queries against the new database
if [ $synapseDeployFlag == 'no' ]; then
    version='Databricks Version'
else
    version='Synapse Version'
fi
for synapseQuery in "../Azure Synapse Lakehouse Sync/$version/Synapse/Queries/"*.sql
do
    executeQuery=$(sqlcmd -U ${bicepDeploymentDetails[synapseSQLAdministratorLogin]} -P ${bicepDeploymentDetails[synapseSQLAdministratorLoginPassword]} -S tcp:${bicepDeploymentDetails[synapseAnalyticsWorkspaceName]}.sql.azuresynapse.net -d ${bicepDeploymentDetails[synapseSQLPoolName]} -I -i "${synapseQuery}" 2>&1 | tee -a $deploymentLogFile)
    executeQuery=$(sqlcmd -U ${bicepDeploymentDetails[synapseSQLAdministratorLogin]} -P ${bicepDeploymentDetails[synapseSQLAdministratorLoginPassword]} -S tcp:${bicepDeploymentDetails[synapseAnalyticsWorkspaceName]}.sql.azuresynapse.net -d ${bicepDeploymentDetails[synapseSQLSecondPoolName]} -I -i "${synapseQuery}" 2>&1 | tee -a $deploymentLogFile)
done

################################################################################
# Synapse Workspace Linked Services                                            #
################################################################################

userOutput "STATUS" "Creating the Synapse Workspace Linked Services..."

if [ $synapseDeployFlag = 'no' ];
then
    for synapseLinkedService in "../Azure Synapse Lakehouse Sync/$version/Synapse/Linked Services/"*.json
    do
        # Get the Link Service name from the JSON, not the filename
        synapseLinkedServiceName=$(jq -r .name "${synapseLinkedService}" 2>&1 | sed 's/^[ \t]*//;s/[ \t]*$//')

        cp "${synapseLinkedService}" "${synapseLinkedService}.tmp" 2>&1
        sed -i "s|REPLACE_DATABRICKS_WORKSPACE_URL|https://${bicepDeploymentDetails[databricksWorkspaceUrl]}|g" "${synapseLinkedService}.tmp"
        sed -i "s|REPLACE_DATABRICKS_WORKSPACE_ID|${bicepDeploymentDetails[databricksWorkspaceId]}|g" "${synapseLinkedService}.tmp"
        sed -i "s|REPLACE_DATABRICKS_CLUSTER_ID|${createDatabricksCluster}|g" "${synapseLinkedService}.tmp"
        sed -i "s|REPLACE_ENTERPRISE_DATALAKE_STORAGE_ACCOUNT_NAME|${bicepDeploymentDetails[enterpriseDataLakeStorageAccountName]}|g" "${synapseLinkedService}.tmp"

        createLinkedService=$(az synapse linked-service create --workspace-name ${bicepDeploymentDetails[synapseAnalyticsWorkspaceName]} --name "${synapseLinkedServiceName}" --file @"${synapseLinkedService}.tmp" 2>&1 | tee -a $deploymentLogFile)
        rm "${synapseLinkedService}.tmp"
    done
else
    for synapseLinkedService in "../Azure Synapse Lakehouse Sync/$version/Synapse/Linked Services/"*.json
    do
        # Get the Link Service name from the JSON, not the filename
        synapseLinkedServiceName=$(jq -r .name "${synapseLinkedService}" 2>&1 | sed 's/^[ \t]*//;s/[ \t]*$//')

        cp "${synapseLinkedService}" "${synapseLinkedService}.tmp" 2>&1
        sed -i "s|REPLACE_ENTERPRISE_DATALAKE_STORAGE_ACCOUNT_NAME|${bicepDeploymentDetails[enterpriseDataLakeStorageAccountName]}|g" "${synapseLinkedService}.tmp"

        createLinkedService=$(az synapse linked-service create --workspace-name ${bicepDeploymentDetails[synapseAnalyticsWorkspaceName]} --name "${synapseLinkedServiceName}" --file @"${synapseLinkedService}.tmp" 2>&1 | tee -a $deploymentLogFile)
        rm "${synapseLinkedService}.tmp"
    done
fi

################################################################################
# Synapse Workspace Datasets                                                   #
################################################################################

userOutput "STATUS" "Creating the Synapse Workspace Datasets..."

for synapseDataSet in "../Azure Synapse Lakehouse Sync/$version/Synapse/Datasets/"*.json
do
    # Get the Dataset name from the JSON, not the filename
    synapseDataSetName=$(jq -r .name "${synapseDataSet}" 2>&1 | sed 's/^[ \t]*//;s/[ \t]*$//')

    createDataSet=$(az synapse dataset create --workspace-name ${bicepDeploymentDetails[synapseAnalyticsWorkspaceName]} --name "${synapseDataSetName}" --file @"${synapseDataSet}" 2>&1 | tee -a $deploymentLogFile)
done

################################################################################
# Synapse Workspace Notebook                                                  #
################################################################################

if [ $synapseDeployFlag = 'yes' ];
    then
    userOutput "STATUS" "Creating the Synapse Lakehouse Sync Notebooks..."

    for synapseNotebook in "../Azure Synapse Lakehouse Sync/Synapse Version/Synapse/Notebooks/"*/*.ipynb
    do
        synapseNotebookName=$(basename "$synapseNotebook" ".ipynb")
        folderPath=$(echo $synapseNotebook | cut -f 6 -d "/" );
        createSynapseNotebook=$(az synapse notebook import --workspace-name ${bicepDeploymentDetails[synapseAnalyticsWorkspaceName]} --name "${synapseNotebookName}" --file @"${synapseNotebook}" --folder-path "${folderPath}" 2>&1 | tee -a $deploymentLogFile)
        # createSynapseNotebook=$(az synapse notebook import --workspace-name ${bicepDeploymentDetails[synapseAnalyticsWorkspaceName]} --name "${synapseNotebookName}" --file @"${synapseNotebook}" --spark-pool-name "$synapseSparkPoolName" 2>&1 | tee -a $deploymentLogFile)
    done
fi

################################################################################
# Synapse Workspace Pipelines                                                  #
################################################################################

userOutput "STATUS" "Creating the Synapse Lakehouse Sync Pipelines..."

if [ $synapseDeployFlag = 'no' ];
then
    for synapsePipeline in "../Azure Synapse Lakehouse Sync/Databricks Version/Synapse/Pipelines/"*.json
    do
        # Get the Pipeline name from the JSON, not the filename
        synapsePipelineName=$(jq -r .name "${synapsePipeline}" 2>&1 | sed 's/^[ \t]*//;s/[ \t]*$//')

        createLinkedService=$(az synapse pipeline create --workspace-name ${bicepDeploymentDetails[synapseAnalyticsWorkspaceName]} --name "${synapsePipelineName}" --file @"${synapsePipeline}" 2>&1 | tee -a $deploymentLogFile)
    done
else
    for synapsePipeline in "../Azure Synapse Lakehouse Sync/Synapse Version/Synapse/Pipelines/"*.json
    do
        # Get the Pipeline name from the JSON, not the filename
        synapsePipelineName=$(jq -r .name "${synapsePipeline}" 2>&1 | sed 's/^[ \t]*//;s/[ \t]*$//')

        createLinkedService=$(az synapse pipeline create --workspace-name ${bicepDeploymentDetails[synapseAnalyticsWorkspaceName]} --name "${synapsePipelineName}" --file @"${synapsePipeline}" 2>&1 | tee -a $deploymentLogFile)
    done
fi

################################################################################
# Sample Data                                                                  #
################################################################################

# Generate a SAS for the data lake so we can upload some files
tomorrowsDate=$(date --date="tomorrow" +%Y-%m-%d)
synapseStorageAccountSAS=$(az storage container generate-sas --account-name ${bicepDeploymentDetails[synapseStorageAccountName]} --name synapsesync --permissions rwal --expiry ${tomorrowsDate} --only-show-errors --output tsv 2>&1 | sed 's/[[:space:]]*//g')
enterpriseDataLakeStorageAccountSAS=$(az storage container generate-sas --account-name ${bicepDeploymentDetails[enterpriseDataLakeStorageAccountName]} --name gold --permissions rwal --expiry ${tomorrowsDate} --only-show-errors --output tsv 2>&1 | sed 's/[[:space:]]*//g')

# Source Sample Data Storage Account
sampleDataStorageAccount="synapseacceleratorsdata"
sampleDataStorageSAS="?sv=2021-04-10&st=2022-10-01T04%3A00%3A00Z&se=2023-12-01T05%3A00%3A00Z&sr=c&sp=rl&sig=eorb8V3hDel5dR4%2Ft2JsWVwTBawsxIOUYADj4RiKeDo%3D"

# Copy sample data
userOutput "STATUS" "Copying the sample data..."
sampleDataCopy=$(az storage copy -s "https://${sampleDataStorageAccount}.blob.core.windows.net/sample/Synapse Lakehouse Sync/AdventureWorks_changes/${sampleDataStorageSAS}" -d "https://${bicepDeploymentDetails[enterpriseDataLakeStorageAccountName]}.blob.core.windows.net/gold/Sample?${enterpriseDataLakeStorageAccountSAS}" --recursive 2>&1 >> $deploymentLogFile)
sampleDataCopy=$(az storage copy -s "https://${sampleDataStorageAccount}.blob.core.windows.net/sample/Synapse Lakehouse Sync/AdventureWorks_parquet/${sampleDataStorageSAS}" -d "https://${bicepDeploymentDetails[enterpriseDataLakeStorageAccountName]}.blob.core.windows.net/gold/Sample?${enterpriseDataLakeStorageAccountSAS}" --recursive 2>&1 >> $deploymentLogFile)

# Update the Auto Loader Metadata file template with the correct storage account and then upload it
enterpriseDataLakeScopeSecretName="EnterpriseDataLakeAccountKey"
synapseStorageScopeSecretName="SynapseStorageAccountKey"
sed -i "s/REPLACE_ENTERPRISE_DATALAKE_STORAGE_ACCOUNT_NAME/${bicepDeploymentDetails[enterpriseDataLakeStorageAccountName]}/g" "../Azure Synapse Lakehouse Sync/$version/Synapse/Synapse_Lakehouse_Sync_Metadata.csv"
sed -i "s/REPLACE_SYNAPSE_STORAGE_ACCOUNT_NAME/${bicepDeploymentDetails[synapseStorageAccountName]}/g" "../Azure Synapse Lakehouse Sync/$version/Synapse/Synapse_Lakehouse_Sync_Metadata.csv"
sed -i "s/REPLACE_DATABRICKS_SCOPE_NAME/${databricksScopeName}/g" "../Azure Synapse Lakehouse Sync/$version/Synapse/Synapse_Lakehouse_Sync_Metadata.csv"
sed -i "s/REPLACE_ENTERPRISE_DATALAKE_SCOPE_SECRET_NAME/${enterpriseDataLakeScopeSecretName}/g" "../Azure Synapse Lakehouse Sync/$version/Synapse/Synapse_Lakehouse_Sync_Metadata.csv"
sed -i "s/REPLACE_SYNAPSE_STORAGE_SCOPE_SECRET_NAME/${synapseStorageScopeSecretName}/g" "../Azure Synapse Lakehouse Sync/$version/Synapse/Synapse_Lakehouse_Sync_Metadata.csv"
sampleDataCopy=$(az storage copy -s "../Azure Synapse Lakehouse Sync/$version/Synapse/Synapse_Lakehouse_Sync_Metadata.csv" -d "https://${bicepDeploymentDetails[synapseStorageAccountName]}.blob.core.windows.net/synapsesync?${synapseStorageAccountSAS}" 2>&1 >> $deploymentLogFile)

#Reset the deploy flag in the parameter file
mv bicep/main.parameters_tmp.json bicep/main.parameters.json 2>&1

# Display the deployment details to the user
userOutput "DEPLOYMENT" "Deployment:" "Complete"
userOutput "RESULT" "Resource Group:" ${bicepDeploymentDetails[resourceGroup]}
userOutput "RESULT" "Synapse Analytics Workspace Name:" ${bicepDeploymentDetails[synapseAnalyticsWorkspaceName]}
userOutput "RESULT" "Synapse Analytics SQL Admin:" ${bicepDeploymentDetails[synapseSQLAdministratorLogin]}
userOutput "RESULT" "Synapse Analytics Storage Account Name:" ${bicepDeploymentDetails[synapseStorageAccountName]}
userOutput "RESULT" "Enterprise Data Lake Storage Account Name:" ${bicepDeploymentDetails[enterpriseDataLakeStorageAccountName]}
userOutput "RESULT" "Databricks Workspace Name:" ${bicepDeploymentDetails[databricksWorkspaceName]}
userOutput "RESULT" "Synapse Analytics Workspace:" "https://web.azuresynapse.net"
userOutput "RESULT" "Databricks Workspace:" "https://${bicepDeploymentDetails[databricksWorkspaceUrl]}"