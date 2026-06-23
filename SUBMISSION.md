# Submission


## What I changed and why

### App

- Removed User/Pass prompt from the log in page. 
- Added a status code to failed log in for better error tracking
- Updated settings.py: 
    - Set debug to false per recommendations
    - Pull sensitive values into env vars
    - Updated database to postgres
    - Updated sessions to use db (allows load balancing)
- Added gunicorn.conf.py file to auto instrument opentelemetry

### Docker

- Created a two step docker file
    - Build static assets separately 
    - Build the app container
- Created a docker compose file
    - Pulls known postgres version and configures from .env file
    - Runs migrate and seed using a short lived container
    - Pulls open-telemetry collector
        - This can then be configured to push or be scraped to an observability back end
    - Pulls latest app image from github
        - Configures using .env
        - Shares volume for static files
        - 2 replicas for some load balancing
    - Pull nginx image
        - pulls in conf from file
        - shared file to share static images
        - load balances requests to x number of web instances

### CI

- Added a build step to create the docker image
- Added a code scaning step using open source tools
- Added push to store
    - tags with latest to work by default
    - but also tags with sha and branch to allow roll back to older versions if needed

## Tradeoffs

- Focused more on architecture and availability options so there is likely more to be done of the app side
- Used auto instrumentation on the observability side
    - Con: Gives less customization and flexibility
    - Pro: allowed really quick frameworking
- Grabbed an opensource sca and used llm to generate the gha for it
    - knew I wanted one and it would be helpful but didn't have a ton of time to research or play around with options
- Managed migrations/seeding in docker compose would like to have a better option to production use cases
    - have used liquibase in the past
    - not sure on best practices for a django migrate file at scale

## What I'd do with another day

- Further tune error logs/codes to better track issues
    - look into adding a structured logging library depending on how the auto instrument telemetry behaves
- Look into retry logic on the database calls in case service is unavailable
- Hook up an open source observability platform to grab and centralize metrics and logs
    - See what is getting captured with auto instrumtation 
    - Look for any short falls and add additional sdks to capture
- Better DB management
    - Replication/backups
    - Better research/answers into data retention
    - Better management of the migration scripts 
    - User roles and permissions on the db
        - ie the app role shouldn't be able to alter or drop tables
    - Preformance monitoring, as is I feel like DB health is a weaker spot on the app
- secret generation
    - Mostly pushed them into a .env file to offload onto the user for simplisity 
    - More randomized and externally stored passwords/api keys would be needed for production

## How to run
Create a .env file:
```bash
SECRET_KEY=
POSTGRES_DB=
POSTGRES_USER=
POSTGRES_PASS=
```
Then run with:
```bash
 docker-compose up
 ```

## Deployment plan

> How would you take this from `docker compose up` on your laptop to a safe, production-ready deployment? You do not need to actually deploy it — we want your reasoning. Cover at least: where it runs, how secrets reach it, rollout + rollback, migrations, logs/metrics/alerts, and anything you'd want in place before a real user touched it.

### Where to Run
- AWS is where I'm most comfortable
  - likely ECS since it's already containerized and fairly simple
  - Best practicesgive simple solutions for a lot of the follow up questions
- Could move PostgresDB to either EC2 or RDS since it's stateful
  - Implement some replication and backups
  - Move read (notes_list) to replica db
- Move static files to s3
- Move from docker compose to terraform

### Secrets
- Leverage Secrets Manager
- Using ECS can pull value from arn
- Using terraform can set and pass in arn easily

### Rollout strategy
- Manage deployments through terraform by enabling force_new_deployment = true in ecs service definition
- control versions using the sha tag
- By having it all defined in iac we can easily roll back to the previous commit

### Database Migration
- Require new columns or tables to have default values so old versions of app can still work on newer dbs
    - I've always worked in a fail forward env.
    - Apply DB migration first if it fails, fix and try again
    - Apply app update second, if it fails since previous version still runs on the currently updated DB, team can fix without downtime
- Alternatively, require rollback scripts that can be ran in case of migration failure

### Log, metrics, alerts
- App is auto-instrumented with otel to expose logs and metrics
- Any tool can scrape this data or use built in otel capabilities
    - Can go with an open source stack prom, jaeger, loki > Grafana
        - Pro: lower cost, high flexibility
        - Con: high set up and maintance efforts
    - Or a paid all in one solution like datadog or new relic
        - Pro: essentially plug and play
        - Con: Usually much higher cost
- Alerts (send notifications)
  - Failed health checks
  - Increased errors
  - Increased latency
    - leverage anomaly detection on p95
- Monitor (track but maybe doesn't notify)
  - CPU/Memory
  - These tend to fluxuate and can run high in normal activity
  - Alerts tend to be noisy
  - Instead track so metrics can be correlated to actual issues

### Improvements pre real users:
- Ideally everything in that extra day list
- SSL/HTTPS
- Limits on # of uploads (total and/or rate)
  - enables tiering if desired
  - blocks malicious users driving up cost
