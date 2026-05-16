# Cost Optimization Summary

**Date**: October 24, 2025

## Changes Applied

### 1. ALB Minimum Capacity Reduction
- **Before**: 25 capacity units
- **After**: 10 capacity units
- **Savings**: ~60% reduction in ALB baseline costs
- **Impact**: Suitable for low-traffic workloads (up to ~25 requests/second)

### 2. Health Check Interval Increase
- **Before**: 15 seconds
- **After**: 30 seconds
- **Savings**: 50% reduction in health check costs
- **Impact**: Slightly slower failure detection (30s vs 15s)

### 3. Container Insights Disabled
- **Before**: Enabled
- **After**: Disabled
- **Savings**: ~$10/month per cluster (4 clusters = $40/month)
- **Impact**: No detailed container metrics (CPU, memory, network per container)
- **Alternative**: Use CloudWatch Logs and basic ECS metrics

### 4. Log Retention Reduced
- **Before**: 7 days
- **After**: 1 day
- **Savings**: ~86% reduction in log storage costs
- **Impact**: Only 24 hours of log history for debugging

### 5. Existing Optimizations (Maintained)
- ✅ **Fargate Spot**: 100% allocation (~70% savings vs on-demand)
- ✅ **Minimal Task Size**: 256 CPU / 512 MB memory
- ✅ **Auto-scaling to Zero**: Min capacity = 0
- ✅ **Deployment Strategy**: 0% minimum healthy for faster scale-down

## Estimated Monthly Costs

### Per Team (4 teams total)
**Compute (Fargate Spot - 1 task running 24/7)**:
- Frontend: 0.25 vCPU, 0.5 GB = ~$3.60/month
- Backend: 0.25 vCPU, 0.5 GB = ~$3.60/month
- **Subtotal per team**: ~$7.20/month

**Shared Resources**:
- ALB (10 capacity units): ~$16/month
- Data transfer: Variable
- CloudWatch Logs (1 day retention): ~$1/month

**Total Estimated Cost**: ~$46/month
- 4 teams × $7.20 = $28.80
- ALB = $16
- Logs = $1

## Cost Breakdown by Service

| Service | Configuration | Monthly Cost |
|---------|--------------|--------------|
| ALB | 10 capacity units | ~$16 |
| ECS Fargate Spot (8 tasks) | 256 CPU / 512 MB each | ~$29 |
| CloudWatch Logs | 1 day retention | ~$1 |
| ECR | 8 repositories | Free tier |
| **Total** | | **~$46/month** |

## Trade-offs

### What You Lose
1. **Container Insights**: No detailed per-container metrics
2. **Longer Health Checks**: 30s interval means slower failure detection
3. **Short Log History**: Only 1 day of logs retained
4. **Lower ALB Capacity**: May need manual increase for traffic spikes

### What You Keep
1. **Auto-scaling**: Still scales 0-3 instances per service
2. **High Availability**: Fargate Spot with automatic replacement
3. **Multi-team Isolation**: Full security group and IAM separation
4. **Performance Features**: HTTP/2, cross-zone load balancing

## Monitoring Without Container Insights

Use these alternatives:
1. **ECS Service Metrics** (free):
   - CPUUtilization
   - MemoryUtilization
   - DesiredTaskCount
   - RunningTaskCount

2. **ALB Metrics** (free):
   - TargetResponseTime
   - RequestCount
   - HTTPCode_Target_2XX_Count
   - UnHealthyHostCount

3. **CloudWatch Logs** (retained):
   - Application logs
   - Error tracking
   - Request/response logging

## When to Increase Capacity

### ALB Capacity
Increase from 10 to 25+ units if:
- Sustained traffic > 25 requests/second
- Response times increase
- ALB throttling errors appear

### Task Resources
Increase from 256/512 if:
- CPU utilization consistently > 80%
- Memory utilization consistently > 80%
- Application performance degrades

### Log Retention
Increase from 1 to 7+ days if:
- Need longer debugging history
- Compliance requirements
- Incident investigation needs

## Reverting Changes

To restore previous settings:

```hcl
# alb.tf
minimum_load_balancer_capacity = {
  capacity_units = 25
}

# alb.tf - health_check
interval = 15

# ecs-clusters.tf
setting = [{
  name  = "containerInsights"
  value = "enabled"
}]

# variables.tf
default = 7  # log_retention_days
```

## Cost Monitoring

Track costs using AWS Cost Explorer with these filters:
- Service: ECS, Elastic Load Balancing, CloudWatch
- Tag: `Project = "awsugsg"`
- Tag: `Environment = "dev"`

Set up billing alerts:
- Alert at $30/month (60% of estimate)
- Alert at $50/month (100% of estimate)
- Alert at $75/month (150% of estimate)
