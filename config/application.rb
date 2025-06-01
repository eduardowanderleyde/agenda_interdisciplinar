require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module AgendaInterdisciplinar
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Definir locale padrão
    config.i18n.default_locale = :'pt-BR'

    # Definir fuso horário da aplicação para Recife
    config.time_zone = 'America/Recife'
    # Manter o banco armazenando em UTC
    config.active_record.default_timezone = :utc

    # Configuração do Sidekiq como backend de jobs
    config.active_job.queue_adapter = :sidekiq
  end
end
