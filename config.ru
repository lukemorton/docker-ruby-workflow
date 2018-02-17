require 'logger'
require 'sequel'

# Sequel.connect(
#   adapter: :postgres,
#   host: ENV['DATABASE_HOST'],
#   user: ENV['DATABASE_USER'],
#   password: ENV['DATABASE_PASSWORD'],
#   max_connections: 10,
#   logger: Logger.new('db.log')
# )

run Proc.new { |env| [200, {}, ['71']] }
