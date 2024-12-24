# About this example

This [example](https://github.com/paneq/pg_playground/blob/main/res_incremental_analytics/res_pg_incremental.rb) 
demonstrates how [pg_incremental](https://github.com/CrunchyData/pg_incremental) extension can
be used for processing domain events' data
coming from [Rails Event Store](https://railseventstore.org/)
to build materialized analytical time-series data.

The script publishes `UserRegistered` events and then pg_incremental processes 
them every minute to build a `registrations` read model which shows how many users
were registered in each minute and from which social network.

Artificial sleeps are added to transactions to make them last longer and to demonstrate
how pg_incremental processes them safely:

> The pipeline execution ensures that the range of sequence values is known to be
> safe, meaning that there are no more transactions that might produce sequence values
> that are within the range. This is ensured by waiting for concurrent write transactions
> before proceeding with the command. The size of the range is effectively the number of inserts
> since the last time the pipeline was executed up to the moment that the new pipeline
> execution started.

# Setup

```
bundle install
cd .. && docker compose up --build
```

# Running the example

```
bundle exec ruby res_pg_incremental.rb
```

# Example output

```
creating: 7830
creating: 871
creating: 7840
creating: 7850
creating: 7860
creating: 7870
creating: 7880
creating: 7890
creating: 7900
creating: 7910
Stopping writers
creating: 7920
creating: 881
Minute: 2024-12-23 13:18:00 UTC, Source: bsky, Total: 3
Minute: 2024-12-23 13:18:00 UTC, Source: facebook, Total: 41
Minute: 2024-12-23 13:18:00 UTC, Source: linkedin, Total: 365
++++
Total in read model: 409, Total in event store: 884
---- to stop workers run: kill -HUP 3153
creating: 52
Minute: 2024-12-23 13:18:00 UTC, Source: bsky, Total: 3
Minute: 2024-12-23 13:18:00 UTC, Source: facebook, Total: 41
Minute: 2024-12-23 13:18:00 UTC, Source: linkedin, Total: 365
++++
Total in read model: 409, Total in event store: 885
---- to stop workers run: kill -HUP 3153
Minute: 2024-12-23 13:19:00 UTC, Source: bsky, Total: 2
Minute: 2024-12-23 13:19:00 UTC, Source: facebook, Total: 47
Minute: 2024-12-23 13:19:00 UTC, Source: linkedin, Total: 427
Minute: 2024-12-23 13:18:00 UTC, Source: bsky, Total: 3
Minute: 2024-12-23 13:18:00 UTC, Source: facebook, Total: 41
Minute: 2024-12-23 13:18:00 UTC, Source: linkedin, Total: 365
++++
Total in read model: 885, Total in event store: 885
```
