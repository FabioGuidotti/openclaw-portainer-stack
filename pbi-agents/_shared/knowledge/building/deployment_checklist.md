# Deployment Checklist

## Pre-Deployment
- [ ] Model validated by ModelArchitect
- [ ] DAX measures validated by DAXSpecialist
- [ ] Visuals validated by VisualDesigner
- [ ] Supervisor has approved all components
- [ ] Test data refresh works locally

## Deployment Steps
1. [ ] Publish to Power BI Service workspace
2. [ ] Configure data gateway connection (if on-premise)
3. [ ] Set scheduled refresh (time, frequency)
4. [ ] Configure credentials for data sources
5. [ ] Set up Row-Level Security (if applicable)
6. [ ] Configure alerts and subscriptions

## Post-Deployment
- [ ] Verify data refresh succeeds
- [ ] Verify RLS works for each role
- [ ] Test report in browser and mobile
- [ ] Share with stakeholders
- [ ] Document access and refresh schedule

## Rollback Plan
1. Keep previous version in a separate workspace
2. Document what changed in this deployment
3. If issues found, revert to previous uploaded PBIX
