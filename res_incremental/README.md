# About this example

This [example](https://github.com/paneq/pg_playground/blob/main/res_incremental/res_pg_incremental.rb) 
demonstrates how [pg_incremental](https://github.com/CrunchyData/pg_incremental) extension can
be used for processing domain events' data
coming from [Rails Event Store](https://railseventstore.org/)
to build materialized [read models](https://event-driven.io/en/projections_and_read_models_in_event_driven_architecture/).

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
