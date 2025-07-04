# rekt-exporter
⏺ Complete solution for temporary instance logging:

  Integration into AMI Init Script

  Add this to your AMI init script:

  # In your AMI init script
  cd /path/to/rekt-exporter
  export GAME_ENV="production"  # or "staging", "dev", etc.
  chmod +x start-logging.sh
  ./start-logging.sh

  Key Features

  1. Dynamic AWS Metadata - Automatically fetches instance ID and region
  2. Enhanced Labels - Logs tagged with:
    - aws_instance_id - EC2 instance ID
    - aws_region - AWS region
    - game_env - Your game environment
    - log_session - Timestamp for this session
  3. Grafana Filtering - Use queries like:
    - {aws_instance_id="i-1234567890abcdef0"} - Specific instance
    - {aws_region="us-east-1", game_env="production"} - All prod instances in region
    - {log_session="20250703_105430"} - Specific session

  Benefits for Temporary Instances

  - Persistent Logs - Logs remain in Loki after instance termination
  - Easy Organization - Filter by instance, region, environment
  - Session Tracking - Each instance startup gets unique session ID
  - Scalable - Works with any number of temporary instances

  Usage

  1. Deploy: Include in your AMI
  2. Start: Run ./start-logging.sh on instance startup
  3. Monitor: Use Grafana queries to filter logs by instance/region/env
  4. Archive: Logs persist for analysis after instance termination

  Your temporary instances will now have organized, searchable logs with full traceability!