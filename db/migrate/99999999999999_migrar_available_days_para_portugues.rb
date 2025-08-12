class MigrarAvailableDaysParaPortugues < ActiveRecord::Migration[7.1]
  # Temporarily disabled to fix deployment issues
  # DIAS = {
  #   'monday' => 'segunda-feira',
  #   'tuesday' => 'terça-feira',
  #   'wednesday' => 'quarta-feira',
  #   'thursday' => 'quinta-feira',
  #   'friday' => 'sexta-feira',
  #   'saturday' => 'sábado',
  #   'sunday' => 'domingo'
  # }

  def up
    # Temporarily disabled to fix deployment issues
    # Professional.find_each do |prof|
    #   # Corrigir available_days
    #   dias = (prof.available_days || []).map { |d| DIAS[d] || d }
    #   prof.update_column(:available_days, dias)

    #   # Corrigir available_hours
    #   ah = prof.available_hours || {}
    #   novo_ah = {}
    #   ah.each do |k, v|
    #     novo_ah[DIAS[k] || k] = v
    #   end
    #   prof.update_column(:available_hours, novo_ah)
    # end
    puts "Migration temporarily disabled for deployment"
  end

  def down
    # Não faz o rollback
  end
end 