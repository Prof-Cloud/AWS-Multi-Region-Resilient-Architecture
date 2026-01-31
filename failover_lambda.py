# failover_lambda.py
import boto3
import os
import time
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    rds = boto3.client("rds")

    global_cluster_id = os.environ.get("GLOBAL_CLUSTER_ID")
    target_cluster_id_input = os.environ.get("TARGET_CLUSTER_ID")

    if not global_cluster_id or not target_cluster_id_input:
        logger.error("Missing required environment variables")
        return {"status": "error", "message": "Missing environment variables"}

    logger.info(f"Failover requested for Global Cluster: {global_cluster_id}")

    try:
        # --- NEW STEP: Get the full ARN ---
        # The failover_global_cluster API requires the full ARN for the target,
        # but we likely only have the short name (Identifier) in the env var.
        
        response = rds.describe_global_clusters(
            GlobalClusterIdentifier=global_cluster_id
        )
        members = response["GlobalClusters"][0]["GlobalClusterMembers"]

        # Find the member whose ARN ends with our target name (e.g., 'vanish-secondary-cluster')
        target_member = next(
            (m for m in members if m["DBClusterArn"].endswith(f":cluster:{target_cluster_id_input}")),
            None
        )

        if not target_member:
            raise ValueError(f"Could not find a cluster member matching identifier: {target_cluster_id_input}")

        target_cluster_arn = target_member["DBClusterArn"]
        logger.info(f"Resolved Target ARN: {target_cluster_arn}")
        # ----------------------------------

        # 1. Trigger Managed Failover using the ARN
        rds.failover_global_cluster(
            GlobalClusterIdentifier=global_cluster_id,
            TargetDbClusterIdentifier=target_cluster_arn 
        )

        logger.info("Failover command submitted successfully. Monitoring promotion...")

        max_checks = 45  # ~7.5 minutes
        for attempt in range(1, max_checks + 1):
            response = rds.describe_global_clusters(
                GlobalClusterIdentifier=global_cluster_id
            )

            current_members = response["GlobalClusters"][0]["GlobalClusterMembers"]
            
            # Check if the specific target ARN is now the writer
            active_target = next(
                (m for m in current_members if m["DBClusterArn"] == target_cluster_arn),
                None
            )

            if active_target and active_target.get("IsWriter"):
                logger.info("FAILOVER COMPLETE — Secondary region is now the writer")
                return {"status": "success"}
            
            logger.info(f"Attempt {attempt}/{max_checks}: Cluster is still transitioning...")
            time.sleep(10)

        raise TimeoutError("Failover did not complete within the expected window")

    except Exception as exc:
        logger.exception("Failover failed")
        return {"status": "error", "message": str(exc)}