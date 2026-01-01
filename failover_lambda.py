import boto3
import os
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    # Initialize RDS client in the Primary region to manage the Global Cluster
    rds = boto3.client('rds', region_name='us-east-1')
    
    global_cluster_id = os.environ['GLOBAL_CLUSTER_ID']
    target_cluster_arn = os.environ['TARGET_CLUSTER_ARN']
    
    try:
        # 1. Safety Check: Is London already the writer?
        response = rds.describe_global_clusters(GlobalClusterIdentifier=global_cluster_id)
        cluster_members = response['GlobalClusters'][0]['GlobalClusterMembers']
        
        for member in cluster_members:
            if member['DBClusterArn'] == target_cluster_arn and member.get('IsWriter', False):
                logger.info(f"Safety Check: {target_cluster_arn} is already the Writer. No action needed.")
                return {"status": "skipped", "message": "Cluster is already Primary"}

        # 2. Trigger Failover
        logger.info(f"Initiating failover for Global Cluster: {global_cluster_id}")
        rds.failover_global_cluster(
            GlobalClusterIdentifier=global_cluster_id,
            TargetDbClusterIdentifier=target_cluster_arn
        )
        
        logger.info("Failover command accepted. Migration in progress.")
        return {"status": "success", "message": "Promotion initiated"}

    except Exception as e:
        logger.error(f"FAILOVER ERROR: {str(e)}")
        return {"status": "error", "message": str(e)}