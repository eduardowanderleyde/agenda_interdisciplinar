class AddRoomToAppointments < ActiveRecord::Migration[7.1]
  def change
    add_reference :appointments, :room, null: true, foreign_key: true

    # Atualiza registros existentes com uma sala padrão
    reversible do |dir|
      dir.up do
        default_room = Room.first_or_create!(name: 'Sala 1', description: 'Sala padrão')
        Appointment.where(room_id: nil).update_all(room_id: default_room.id)

        # Agora que todos os registros têm uma sala, podemos tornar a coluna não nula
        change_column_null :appointments, :room_id, false
      end
    end
  end
end
