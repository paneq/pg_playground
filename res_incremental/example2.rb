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

ActiveRecord::Base.logger = Logger.new(STDOUT)

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

CreateRESTable.new.up

event_store = RailsEventStore::JSONClient.new

class UserCreated < RailsEventStore::Event
end

event_store.publish(UserCreated.new(data: { name: 'John Doe' }))
