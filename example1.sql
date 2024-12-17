/* source: https://www.crunchydata.com/blog/pg_incremental-incremental-data-processing-in-postgres */

/* define the raw data and summary table */
create table events (event_id bigserial, event_time timestamptz, user_id bigint, response_time double precision);
create table view_counts (day timestamptz, user_id bigint, count bigint, primary key (day, user_id));

/* enable fast range scans on the sequence column */
create index on events using brin (event_id);

/* for demo: generate some random data */
insert into events (event_time, user_id, response_time)
select now(), random() * 100, random() from generate_series(1,1000000) s;

/* define a sequence pipeline that periodically upserts view counts */
select incremental.create_sequence_pipeline('view-count-pipeline', 'events',
                                            $$
                                                insert into view_counts
    select date_trunc('day', event_time), user_id, count(*)
                                                from events where event_id between $1 and $2
    group by 1, 2
                                                on conflict (day, user_id) do update set count = view_counts.count + EXCLUDED.count;
$$
);

/* get the most active users of today */
select user_id, sum(count) from view_counts where day = now()::date group by 1 order by 2 desc limit 3;