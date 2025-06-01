class Professional < ApplicationRecord
  belongs_to :user, optional: true
  has_many :appointments, dependent: :destroy
  has_many :evolutions, through: :appointments
  has_many :professional_specialties, dependent: :destroy
  has_many :specialties, through: :professional_specialties
  # validates :name, presence: { message: "O nome não pode ficar em branco" }
  validate :available_hours_format
  validate :must_have_at_least_one_available_day
  validate :name_presence_custom

  after_initialize :set_defaults

  DIAS_PT_EN = {
    'segunda-feira' => 'monday',
    'terça-feira' => 'tuesday',
    'quarta-feira' => 'wednesday',
    'quinta-feira' => 'thursday',
    'sexta-feira' => 'friday',
    'sábado' => 'saturday',
    'domingo' => 'sunday'
  }

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

    regex = /\A\d{2}:\d{2} - \d{2}:\d{2}\z/ # O formato esperado é "HH:MM - HH:MM"
    available_hours.each do |dia, intervalos|
      Array(intervalos).each do |intervalo|
        unless intervalo.is_a?(String) && intervalo.match?(regex)
          errors.add(:available_hours,
                     "Intervalo inválido para #{dia.humanize}: #{intervalo}. Use o formato 08:00 - 12:00")
        end
      end
    end
  end

  def available_days=(value)
    # Converte para inglês se vier em português
    value = value.map { |d| DIAS_PT_EN[d] || d } if value.is_a?(Array)
    super(value)
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
    # Converte as chaves para inglês se vierem em português
    value = value.transform_keys { |k| DIAS_PT_EN[k] || k } if value.is_a?(Hash)
    super(value)
  end

  private

  def set_defaults
    self.available_hours ||= {}
  end

  def must_have_at_least_one_available_day
    if available_days.blank? || available_days.empty?
      errors.add(:base, "É obrigatório selecionar pelo menos um dia disponível para o profissional.")
    end
  end

  def name_presence_custom
    if name.blank?
      errors.add(:base, "O nome não pode ficar em branco")
    end
  end
end
