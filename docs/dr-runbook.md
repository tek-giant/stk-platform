# Database disaster recovery runbook

## What protects the data
- RDS PostgreSQL 16, encrypted with the project KMS key.
- Automated backups kept 7 days, giving point-in-time recovery (RPO about 5 minutes while the instance exists).
- Single AZ (multi_az = false), a deliberate dev cost decision.
- Dev setting: skip_final_snapshot = true, so destroying the instance also deletes its automated backups. Production needs deletion_protection = true and a final snapshot.

## Targets
| Scenario | RPO | RTO |
| --- | --- | --- |
| Bad deploy or accidental delete | about 5 minutes | about 8 minutes (measured, see below) |
| AZ outage (Multi-AZ off) | about 5 minutes | same, since it is a restore |
| Region loss | last copied snapshot | not built, not measured |

## Drill, 1 Nov 2026
1. Applied dev-data (7 resources).
2. Took a manual snapshot (stk-dev-drill-1); it became available and encrypted.
3. Restored it to a new instance (db.t4g.micro, same subnet group, not public, single AZ).
4. Start 14:50:54, instance available 14:59:01: 8 minutes 7 seconds.
5. Deleted the restored instance and the snapshot, destroyed dev-data, ran scripts/bash/check-running-costs.sh (exit 0).

## Limits of the measurement
- Small dev database (20 GB); a production database would take longer.
- Measured instance recovery only: no security group was attached, and DNS, secret and application reconnect were not tested.
- The data inside the restored copy was not queried.
- Cross-region snapshot copy and Multi-AZ failover are not built.

## To restore
1. aws rds create-db-snapshot (or choose a restore time), then restore-db-instance-from-db-snapshot into the stk-dev-db subnet group.
2. Attach the database security group, point the application at the new endpoint and secret.
3. Delete anything created by hand when finished and run the cost check.
