# PG Playground

Docker configuration for safely playing with various PG extensions such as:
* [pg_cron](https://github.com/citusdata/pg_cron)
* [pg_incremental](https://github.com/crunchydata/pg_incremental)

# Usage

```
docker compose up --build
docker exec -it pg_playground-postgres-1 psql -U postgres
\c postgres
```

And then you can execute i.e. the [example1.sql](https://github.com/paneq/pg_playground/blob/main/example1.sql)
statements inside postgresql console.

# Credits

* https://www.crunchydata.com/blog/pg_incremental-incremental-data-processing-in-postgres