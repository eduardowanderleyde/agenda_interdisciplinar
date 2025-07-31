# Force DATABASE_URL usage in production
if Rails.env.production?
  database_url = ENV['RAILS_DATABASE_URL'] || ENV['DATABASE_URL']

  if database_url.present?
    Rails.application.config.after_initialize do
      ActiveRecord::Base.connection_pool.disconnect! if ActiveRecord::Base.connected?
      ActiveRecord::Base.establish_connection(database_url)
    end
  end
end
