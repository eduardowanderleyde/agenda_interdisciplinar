# 🚀 Guia de Deploy - Agenda Interdisciplinar

## 📋 Status Atual dos Serviços no Render

### ❌ Problemas Identificados

1. **`agenda-interdisciplinar-db`**: Suspenso pelo Render
2. **`agenda-interdisciplinar`**: Deploy falhou

### ✅ Serviços Funcionando

1. **`agenda-interdisciplinar-worker`**: Deployed ✓
2. **`agenda-interdisciplinar-redis`**: Deployed ✓

## 🔧 Soluções Passo a Passo

### **Passo 1: Reativar o Banco de Dados**

1. Acesse o dashboard do Render
2. Clique em `agenda-interdisciplinar-db`
3. Na página do serviço, procure por:
   - Botão "Resume" ou "Reactivate"
   - Ou vá em "Settings" → "Suspend/Resume"

**Se não conseguir reativar:**

- Verifique se não excedeu o limite gratuito
- Considere fazer upgrade para plano pago
- Ou crie um novo banco de dados

### **Passo 2: Configurar Variáveis de Ambiente**

No serviço `agenda-interdisciplinar`, vá em **Settings** → **Environment Variables** e adicione:

```
RAILS_MASTER_KEY=9de0532f41376aecb5b38edfc55d2616
RAILS_ENV=production
RAILS_SERVE_STATIC_FILES=true
```

### **Passo 3: Verificar Configurações do Banco**

Certifique-se que as seguintes variáveis estão configuradas automaticamente:

- `DATABASE_URL` (deve vir do banco de dados)
- `REDIS_URL` (deve vir do Redis)

### **Passo 4: Forçar Novo Deploy**

1. No serviço `agenda-interdisciplinar`
2. Clique em **"Manual Deploy"** → **"Deploy latest commit"**
3. Monitore os logs para identificar erros

## 🔍 Verificação de Logs

### **Para verificar logs do deploy:**

1. Clique no serviço `agenda-interdisciplinar`
2. Vá na aba **"Logs"**
3. Procure por erros específicos

### **Logs comuns a verificar:**

- `ActiveRecord::DatabaseConnectionError`
- `ActiveSupport::MessageEncryptor::InvalidMessage`
- Problemas de assets compilation

## 🛠️ Problemas Técnicos Já Corrigidos

### ✅ Corrigido no Código

1. **Tailwind CSS**: Configurado corretamente
2. **Assets**: Compilação funcionando
3. **Credenciais**: Produção configurada
4. **Dockerfile**: NODE_OPTIONS adicionado

### ⚠️ Ainda Precisa de Ação

1. **Banco de dados**: Reativar no Render
2. **Variáveis de ambiente**: Configurar manualmente
3. **Deploy**: Forçar novo deploy após correções

## 📞 Próximos Passos

1. **Reative o banco de dados** no dashboard do Render
2. **Configure as variáveis de ambiente** listadas acima
3. **Force um novo deploy** do serviço principal
4. **Monitore os logs** para identificar problemas restantes

## 🆘 Se Ainda Houver Problemas

### **Verificar:**

- Logs detalhados do deploy
- Configuração do banco de dados
- Variáveis de ambiente
- Limites do plano gratuito do Render

### **Alternativas:**

- Fazer upgrade para plano pago
- Migrar para outro provedor (Heroku, Railway, etc.)
- Usar banco de dados externo (Supabase, PlanetScale, etc.)
