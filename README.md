# Azure Synapse Lakehouse Sync


#### Disclaimer
*This solution was built for demoing the art of the possible when combining the best of spark with the best of data warehousing. It is not intended to be used in production environments.*

#### Description
TODO

Azure Synapse Lakehouse Sync provides an easy solution to synchronizing modeled Gold Zone data from your data lake, to your Synapse Analytics Data Warehouse. Through a series of Databricks notebooks and Synapse Analytics pipelines, it offers a working example of how to continually synchronize your tables.

Additionally, it leverages the new [Change Data Feed](https://docs.delta.io/2.0.0rc1/delta-change-data-feed.html) capabilities in the Delta 2.x format to better track changes to your Gold Zone tables. This allows for significantly easier and more performant extracts of changed data. Best practices are then used to stage, ingest, and store data in the most performant and optimized way within Azure Synapse Dedicated SQL. The synchronization schedule can be configured for whatever interval works best for your environment, whether it's every 10 minutes or daily.

Azure Synapse Lakehouse Sync is designed to be a fully automated, self-healing, and hands-off approach to continually synchronize your data lake with your data warehouse.

https://user-images.githubusercontent.com/16770830/192058619-0c5a4664-0662-4e9b-92f2-dbc093dfea6f.mp4

<br>

## Using Azure Synapse Lakehouse Sync

[Self Deployment](/Azure%20Synapse%20Lakehouse%20Sync): Instructions for deploying, configuring, and using Azure Synapse Lakehouse Sync in your own environment.

[Tutorial Environment](/Tutorial%20Environment): Deploys a fully working Azure Synapse Lakehouse Sync tutorial environment in your Azure Subscription. This is a great way to experience how Azure Synapse Lakehouse Sync works end-to-end.
