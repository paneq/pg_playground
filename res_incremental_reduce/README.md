# About this example

This [example](https://github.com/paneq/pg_playground/blob/main/res_incremental_reduce/res_pg_incremental_reduce.rb) 
demonstrates how [pg_incremental](https://github.com/CrunchyData/pg_incremental) extension can
be used for processing domain events' data
coming from [Rails Event Store](https://railseventstore.org/)
to implement a projection/[read model](https://event-driven.io/en/projections_and_read_models_in_event_driven_architecture/).

The script publishes `UserRegistered` and `UserUnregistered` events and then pg_incremental processes 
them every minute to build a `users` read model which shows current status of each user.

# Setup

```
bundle install
cd .. && docker compose up --build
```

# Running the example

```
bundle exec ruby res_pg_incremental_reduce.rb
```

# Example output

```
registering: 187
unregistering: 187
registering: 188
registering: 189
registering: 190
unregistering: 190
registering: 191
registering: 192
registering: 193
unregistering: 193
registering: 194
registering: 195
User: 178, Status: unregistered
User: 177, Status: registered
User: 176, Status: registered
User: 175, Status: unregistered
User: 174, Status: registered
User: 173, Status: registered
User: 172, Status: unregistered
User: 171, Status: registered
User: 170, Status: registered
User: 169, Status: unregistered
```
