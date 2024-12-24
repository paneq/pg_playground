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
    execute('DROP FUNCTION IF EXISTS process_event;')
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

class CreateUsers < ActiveRecord::Migration[8.0]
  def up
    drop_table :users, if_exists: true
    create_table "users", force: :cascade do |t|
      t.string "status", null: false
    end
  end
end

class CreateFunction < ActiveRecord::Migration[8.0]
  def up
    execute(<<-SQL)
      CREATE OR REPLACE FUNCTION process_event(e event_store_events)
      RETURNS void AS $$
      DECLARE
         user_id integer;
      BEGIN
         user_id := (e.data->>'user_id')::integer;
         IF e.event_type = 'UserRegistered' THEN
             INSERT INTO users (id, status) VALUES (user_id, 'registered');
         ELSIF e.event_type = 'UserUnregistered' THEN
             UPDATE users SET status = 'unregistered' WHERE id = user_id;
         ELSE
             RAISE NOTICE 'Unexpected event type: %', e.event_type;
         END IF;
      END;
      $$ LANGUAGE plpgsql;
   SQL
  end
end

class ProcessUserEvents < ActiveRecord::Migration[8.0]
  def up
    begin
      # TODO: Fix me
      execute("select incremental.drop_pipeline('reduce-user-events');")
    rescue
      puts "rescued"
    end
    sql = <<-SQL
      select incremental.create_sequence_pipeline('reduce-user-events', 'event_store_events',
        $$
          SELECT process_event(e.*)
          FROM event_store_events e
          WHERE id BETWEEN $1 AND $2
          AND event_type IN ('UserRegistered', 'UserUnregistered')
          ORDER BY id
        $$
      );
    SQL
    execute(sql)
  end
end

CreateRESTable.new.up
CreateUsers.new.up
CreateFunction.new.up
ProcessUserEvents.new.up

event_store = RailsEventStore::JSONClient.new

class User < ActiveRecord::Base
  self.table_name = 'users'
end

class UserRegistered < RailsEventStore::Event
end
class UserUnregistered < RailsEventStore::Event
end

stop_writing = false
Signal.trap("HUP") do
  puts "Stopping writers"
  stop_writing = true
end

Thread.new do
  (1..).each do |user_id|
    break if stop_writing
    ActiveRecord::Base.transaction do
      puts "registering: #{user_id}"
      event_store.publish(UserRegistered.new(data: {
        user_id: user_id,
        name: "User #{user_id}",
      }))

      if user_id % 3 == 1
        puts "unregistering: #{user_id}"
        event_store.publish(UserUnregistered.new(data: {
          user_id: user_id,
        }))
      end
    end
    sleep(0.5)
  end
end


loop do
  sleep(10)
  ActiveRecord::Base.transaction do
    User.order('id DESC').limit(10).each do |user|
      puts "User: #{user.id}, Status: #{user.status}"
    end
    puts "---- to stop producers run: kill -HUP #{Process.pid}"
  end
end
