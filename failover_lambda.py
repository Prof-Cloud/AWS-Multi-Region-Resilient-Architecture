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
    # Changed: Target is easier to track via Identifier name than full ARN in logs
    target_cluster_id = os.environ.get("TARGET_CLUSTER_ID")

    if not global_cluster_id or not target_cluster_id:
        logger.error("Missing required environment variables")
        return {"status": "error", "message": "Missing environment variables"}

    logger.info(f"Failover initiated for Global Cluster: {global_cluster_id}")

    try:
        # 1. Trigger Managed Failover
        # This synchronizes the secondary cluster before promoting it
        rds.failover_global_cluster(
            GlobalClusterIdentifier=global_cluster_id,
            TargetDbClusterIdentifier=target_cluster_id
        )

        logger.info("Failover command submitted. Monitoring promotion...")

        max_checks = 45  # Increased to ~7.5 minutes as managed failover can be slow
        for attempt in range(1, max_checks + 1):
            response = rds.describe_global_clusters(
                GlobalClusterIdentifier=global_cluster_id
            )

            members = response["GlobalClusters"][0]["GlobalClusterMembers"]
            
            # Find the member matching our target identifier
            target = next(
                (m for m in members if m["DBClusterArn"].split(':')[-1] == target_cluster_id or m["DBClusterArn"] == target_cluster_id),
                None
            )

            if target and target.get("IsWriter"):
                logger.info("FAILOVER COMPLETE — Secondary region is now the writer")
                return {"status": "success"}
            
            logger.info(f"Attempt {attempt}/{max_checks}: Cluster is still transitioning...")
            time.sleep(10)

        raise TimeoutError("Failover did not complete within the expected window")

    except Exception as exc:
        logger.exception("Failover failed")
        return {"status": "error", "message": str(exc)}