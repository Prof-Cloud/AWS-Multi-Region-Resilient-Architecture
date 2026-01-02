import boto3
import os
import time
import logging

# Configure structured logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    rds = boto3.client("rds")

    global_cluster_id = os.environ.get("GLOBAL_CLUSTER_ID")
    target_cluster_arn = os.environ.get("TARGET_CLUSTER_ARN")

    if not global_cluster_id or not target_cluster_arn:
        logger.error("Missing required environment variables")
        return {"status": "error", "message": "Missing environment variables"}

    logger.info("Failover initiated")
    logger.info("Global Cluster: %s", global_cluster_id)
    logger.info("Target Cluster ARN: %s", target_cluster_arn)

    try:
        # 1. Trigger Failover
        rds.failover_global_cluster(
            GlobalClusterIdentifier=global_cluster_id,
            TargetDbClusterIdentifier=target_cluster_arn
        )

        logger.info("Failover command submitted")

        # 2. Wait for promotion
        max_checks = 30  # ~5 minutes
        for attempt in range(1, max_checks + 1):
            response = rds.describe_global_clusters(
                GlobalClusterIdentifier=global_cluster_id
            )

            members = response["GlobalClusters"][0]["GlobalClusterMembers"]

            target = next(
                (m for m in members if m["DBClusterArn"] == target_cluster_arn),
                None
            )

            if not target:
                logger.warning(
                    "Attempt %s/%s: Target cluster not visible yet",
                    attempt, max_checks
                )
            elif target.get("IsWriter"):
                logger.info("FAILOVER COMPLETE — London is now the writer")
                return {
                    "status": "success",
                    "message": "Failover completed successfully"
                }
            else:
                logger.info(
                    "Attempt %s/%s: Target still reader — waiting",
                    attempt, max_checks
                )

            time.sleep(10)

        raise TimeoutError("Failover timed out after 5 minutes")

    except Exception as exc:
        logger.exception("Failover failed")
        return {
            "status": "error",
            "message": str(exc)
        }
