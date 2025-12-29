import boto3  
import os     

def lambda_handler(event, context):
    # Lambda looking at Aurora db in Virginia
    rds = boto3.client('rds', region_name='us-east-1')
    
    # Getting IDs for the databases
    global_cluster_id = os.environ['GLOBAL_CLUSTER_ID']
    target_cluster_arn = os.environ['TARGET_CLUSTER_ARN']
    
    try:
        # Flipping the switch to make London the Writer 
        response = rds.failover_global_cluster(
            GlobalClusterIdentifier=global_cluster_id,
            TargetDbClusterIdentifier=target_cluster_arn
        )
        return {"status": "success"}
    except Exception as e:
        # Report error if something goes wrong
        return {"status": "error", "message": str(e)}