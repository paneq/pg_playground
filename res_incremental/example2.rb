require 'active_record'
require 'logger'

# Database connection configuration
ActiveRecord::Base.establish_connection(
  adapter: 'postgresql',
  host: 'localhost',
  database: 'postgres',
  username: 'postgres',
  password: 'postgres',
  port: 5432
)

ActiveRecord::Base.logger = Logger.new(STDOUT)

# Schema management: Define and create the users table
class CreateUsersTable < ActiveRecord::Migration[7.0]
  def up
    create_table :users do |t|
      t.string :name, null: false
      t.string :email, null: false
      t.timestamps
    end

    add_index :users, :email, unique: true
  end

  def down
    drop_table :users
  end
end

# Run the migration if the table doesn't exist
begin
  unless ActiveRecord::Base.connection.table_exists?(:users)
    CreateUsersTable.new.up
  end
rescue => e
  puts "Migration error: #{e.message}"
end

# Define the model
class User < ActiveRecord::Base
  validates :name, presence: true
  validates :email, presence: true, uniqueness: true
end

# Example usage
begin
  # Create a new user
  user = User.create!(
    name: 'John Doe',
    email: 'john@example.com'
  )
  puts "Created user: #{user.inspect}"

  # Find a user
  found_user = User.find_by(email: 'john@example.com')
  puts "Found user: #{found_user.inspect}"

rescue ActiveRecord::Error => e
  puts "Database error: #{e.message}"
end