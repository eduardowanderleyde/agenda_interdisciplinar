import sys
import json
from datetime import datetime, timedelta

# Recebe os parâmetros do Rails via argumento
params = json.loads(sys.argv[1])

# Simula a geração de 10 agendas diferentes
agendas = []
for i in range(10):
    agenda = {
        'opcao': i+1,
        'descricao': f'Agenda gerada #{i+1}',
        'slots': []
    }
    # Exemplo: cria 5 slots fictícios por agenda
    for j in range(5):
        slot = {
            'sala': f"Sala {j+1}",
            'profissional': f"Profissional {j+1}",
            'paciente': f"Paciente {j+1}",
            'inicio': (datetime.now() + timedelta(minutes=30*j)).strftime('%H:%M'),
            'fim': (datetime.now() + timedelta(minutes=30*(j+1))).strftime('%H:%M')
        }
        agenda['slots'].append(slot)
    agendas.append(agenda)

print(json.dumps(agendas)) 