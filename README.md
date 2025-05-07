# Sistema SaaS para Agendamento Dinâmico de Clínica Interdisciplinar

Sistema de agendamento desenvolvido em Ruby on Rails para gerenciamento de atendimentos em clínica de pacientes autistas.

## Requisitos

- Ruby 3.2.2
- PostgreSQL
- Redis
- Node.js
- Yarn

## Configuração

1. Clone o repositório
2. Instale as dependências:

   ```bash
   bundle install
   yarn install
   ```

3. Configure o banco de dados:

   ```bash
   bin/rails db:create db:migrate
   ```

4. Inicie o Redis (necessário para Sidekiq e Action Cable):

   ```bash
   redis-server
   ```

5. Em outro terminal, inicie o servidor de desenvolvimento:

   ```bash
   bin/dev
   ```

O servidor estará disponível em `http://localhost:3000`

## Funcionalidades

- Cadastro de pacientes e profissionais
- Agendamento dinâmico com verificação de conflitos
- Visualização semanal da agenda
- Preenchimento de evoluções clínicas
- Interface responsiva e interativa com Hotwire/Turbo
- Gráficos de evolução dos pacientes
- Upload e processamento de imagens

## Tecnologias Utilizadas

- Ruby on Rails 7.1
- PostgreSQL
- Redis
- Sidekiq
- Devise
- Pundit
- Simple Calendar
- Tailwind CSS
- Stimulus.js
- Turbo
- Chartkick
- Shrine
