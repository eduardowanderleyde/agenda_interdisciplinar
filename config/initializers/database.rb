# Force DATABASE_URL usage in production
if Rails.env.production? && ENV['DATABASE_URL'].present?
  Rails.application.config.after_initialize do
    ActiveRecord::Base.connection_pool.disconnect! if ActiveRecord::Base.connected?
    ActiveRecord::Base.establish_connection(ENV['DATABASE_URL'])
  end
end
