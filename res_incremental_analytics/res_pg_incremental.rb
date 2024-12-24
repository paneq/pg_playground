require 'active_record'
require 'logger'
require 'rails_event_store_active_record'
require 'rails_event_store/all'

ActiveRecord::Base.establish_connection(
  adapter: 'postgresql',
  host: 'localhost',
  database: 'postgres',
  username: 'postgres',
  password: 'postgres',
  port: 5432
)

# ActiveRecord::Base.logger = Logger.new(STDOUT)

class CreateRESTable < ActiveRecord::Migration[7.0]
  def up
    drop_table :event_store_events, if_exists: true
    drop_table :event_store_events_in_streams, if_exists: true

    create_table "event_store_events", id: :serial, force: :cascade do |t|
      t.uuid "event_id", null: false
      t.string "event_type", null: false
      t.jsonb "metadata"
      t.jsonb "data", null: false
      t.datetime "created_at", precision: nil, null: false
      t.datetime "valid_at", precision: nil
      t.index ["created_at"], name: "index_event_store_events_on_created_at"
      t.index ["event_id"], name: "index_event_store_events_on_event_id", unique: true
      t.index ["event_type"], name: "index_event_store_events_on_event_type"
      t.index ["valid_at"], name: "index_event_store_events_on_valid_at"
    end

    create_table "event_store_events_in_streams", id: :serial, force: :cascade do |t|
      t.string "stream", null: false
      t.integer "position"
      t.uuid "event_id", null: false
      t.datetime "created_at", precision: nil, null: false
      t.index ["created_at"], name: "index_event_store_events_in_streams_on_created_at"
      t.index ["event_id"], name: "index_event_store_events_in_streams_on_event_id"
      t.index ["stream", "event_id"], name: "index_event_store_events_in_streams_on_stream_and_event_id", unique: true
      t.index ["stream", "position"], name: "index_event_store_events_in_streams_on_stream_and_position", unique: true
    end
  end
end

class CreateUserRegistrations < ActiveRecord::Migration[8.0]
  def up
    drop_table :registrations, if_exists: true
    execute(<<-SQL)
      CREATE TABLE registrations (
        minute TIMESTAMP(0) NOT NULL,
        source VARCHAR NOT NULL,
        total INTEGER NOT NULL DEFAULT 0,
        PRIMARY KEY (minute, source)
      );
    SQL
  end
end

class UserSourcesByMinuteReadModel < ActiveRecord::Migration[8.0]
  def up
    begin
      # TODO: Fix me
      execute("select incremental.drop_pipeline('registrations-to-read-model');")
    rescue
      puts "rescued"
    end
    sql = <<-SQL
      select incremental.create_sequence_pipeline('registrations-to-read-model', 'event_store_events',
        $$
          insert into registrations (minute, source, total)
          select
            date_trunc('minute', created_at),
            (data->>'source')::text,
            count(distinct (data->>'user_id')::integer)
          from event_store_events
          where
            id between $1 and $2
          and
            event_type = 'UserRegistered'
          group by 1, 2
          on conflict (minute, source) do
            update set total = registrations.total + excluded.total;
        $$
      );
    SQL
    execute(sql)
  end
end

CreateRESTable.new.up
CreateUserRegistrations.new.up
UserSourcesByMinuteReadModel.new.up

event_store = RailsEventStore::JSONClient.new

class RegistrationByMinute < ActiveRecord::Base
  self.table_name = 'registrations'
end
class DbEvent < ActiveRecord::Base
  self.table_name = 'event_store_events'
end

class UserRegistered < RailsEventStore::Event
end


sources = ['linkedin', 'facebook', 'bsky']
sleeps = [0.1, 1, 20]
stop_writing = false
Signal.trap("HUP") do
  puts "Stopping writers"
  stop_writing = true
end

writers = 3.times do |writer_id|
  Thread.new do
    (1..).each do |i|
      break if stop_writing
      ActiveRecord::Base.transaction do
        event_store.publish(UserRegistered.new(data: {
          user_id: user_id = i*10 + writer_id,
          name: "User #{user_id}",
          source: sources[writer_id]
        }))
        sleep(sleeps[writer_id])
        puts "creating: #{user_id}"
      end
    end
  end
end

loop do
  sleep(10)
  ActiveRecord::Base.transaction do
    RegistrationByMinute.order('minute DESC, source ASC').all.each do |registration|
      puts "Minute: #{registration.minute}, Source: #{registration.source}, Total: #{registration.total}"
    end
    puts "++++"
    regs_total = RegistrationByMinute.all.map(&:total).sum
    res_totals = DbEvent.count
    puts "Total in read model: #{regs_total}, Total in event store: #{res_totals}"
    puts "---- to stop producers run: kill -HUP #{Process.pid}"
  end
end
