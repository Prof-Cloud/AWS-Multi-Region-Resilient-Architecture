import boto3
import os
import time

def lambda_handler(event, context):
    # Initialize the RDS client
    rds = boto3.client('rds', region_name='us-east-1')
    
    # Retrieve environment variables
    global_cluster_id = os.environ['GLOBAL_CLUSTER_ID']
    target_cluster_arn = os.environ['TARGET_CLUSTER_ARN']
    
    print(f"Starting failover for Global Cluster: {global_cluster_id}")
    print(f"Promoting Target Cluster: {target_cluster_arn}")

    try:
        # 1. Trigger the Failover
        response = rds.failover_global_cluster(
            GlobalClusterIdentifier=global_cluster_id,
            TargetDbClusterIdentifier=target_cluster_arn
        )
        print("Failover command sent successfully. Waiting for completion...")

        # 2. Wait for the failover to complete
        # We loop and check if the target cluster has become the writer
        max_retries = 30  # Wait up to 5 minutes (30 * 10s)
        for i in range(max_retries):
            # specific call to describe the global cluster status
            cluster_info = rds.describe_global_clusters(
                GlobalClusterIdentifier=global_cluster_id
            )
            
            # Extract member clusters
            members = cluster_info['GlobalClusters'][0]['GlobalClusterMembers']
            
            # Find our target cluster in the list
            target_member = next((m for m in members if m['DBClusterArn'] == target_cluster_arn), None)
            
            if target_member:
                # Check if it is now the writer
                if target_member['IsWriter']:
                    print(f"SUCCESS: {target_cluster_arn} is now the Primary Writer.")
                    return {
                        "status": "success", 
                        "message": "Failover complete. London is now the writer."
                    }
                else:
                    print(f"Attempt {i+1}: Target is still a reader. Waiting...")
            else:
                print(f"Attempt {i+1}: Target cluster not found in global members yet...")

            # Sleep before checking again
            time.sleep(10)

        # 3. Timeout if loop finishes without success
        raise Exception("Timed out waiting for failover validation.")

    except Exception as e:
        print(f"ERROR: {str(e)}")
        return {
            "status": "error", 
            "message": str(e)
        }