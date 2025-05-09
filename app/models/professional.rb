class Professional < ApplicationRecord
  belongs_to :user, optional: true
  has_many :appointments
  has_many :evolutions, through: :appointments
  has_many :professional_specialties
  has_many :specialties, through: :professional_specialties

  validates :name, presence: true
  validates :available_days, presence: true
  validate :available_hours_format

  after_initialize :set_defaults

  # Garante que available_hours seja sempre um hash com os dias da semana
  def available_hours
    super.presence || {}
  end

  def hours_for(day)
    available_hours[day.to_s] || []
  end

  def add_hour_for(day, interval)
    h = available_hours
    h[day.to_s] ||= []
    h[day.to_s] << interval
    self.available_hours = h
  end

  def available_hours_format
    return if available_hours.blank? || !available_hours.is_a?(Hash)

    regex = /\A\d{2}:\d{2} - \d{2}:\d{2}\z/
    available_hours.each do |dia, intervalos|
      Array(intervalos).each do |intervalo|
        unless intervalo.is_a?(String) && intervalo.match?(regex)
          errors.add(:available_hours,
                     "Intervalo inválido para #{dia.humanize}: #{intervalo}. Use o formato 08:00 - 12:00")
        end
      end
    end
  end

  def available_hours=(value)
    # Se vier string JSON, faz parse
    if value.is_a?(String)
      begin
        value = begin
          JSON.parse(value)
        rescue StandardError
          {}
        end
      rescue StandardError
        value = {}
      end
    end
    # Se vier array, coloca em all_days
    value = { 'all_days' => value } if value.is_a?(Array)
    # Se vier nil ou outro tipo, vira hash vazio
    value = {} unless value.is_a?(Hash)
    super(value)
  end

  private

  def set_defaults
    self.available_hours ||= {}
  end
end
