# 🗄️ MyLinks - Database

Repositório contendo o script SQL de criação do banco de dados MySQL para o projeto **MyLinks**.

---

## 📂 Estrutura do Banco

```
MyLinks (Database)
├── usuarios
│   ├── id (PK)
│   ├── username (UNIQUE)
│   ├── email (UNIQUE)
│   ├── senha (NOT NULL, hash bcrypt)
│   └── foto_perfil
│
└── links
    ├── id (PK)
    ├── usuario_id (FK → usuarios.id)
    ├── titulo
    ├── url
    └── ordem
```

---

## 🔗 Relacionamentos

- **1:N** entre `usuarios` e `links`
- **ON DELETE CASCADE**: Ao deletar um usuário, todos os seus links são removidos automaticamente

---

## 📊 Diagrama Entidade-Relacionamento

```
┌─────────────────┐         ┌─────────────────┐
│   usuarios         │           │     links       │
├─────────────────┤         ├─────────────────┤
│ id (PK)         │─────┬───    │ id (PK)         │
│ username (UQ)   │     │        │ usuario_id (FK) │
│ email (UQ)      │     └──→    │ titulo          │
│ senha           │              │ url             │
│ foto_perfil     │              │ ordem           │
└─────────────────┘         └─────────────────┘
     1                                 N
```

---

## 🚀 Como Usar

### 1️⃣ **Criar o Banco Localmente**
```bash
mysql -u root -p < MyLinks.sql
```

### 2️⃣ **Criar o Banco em Produção (Railway/PlanetScale)**
1. Acesse o painel do Railway/PlanetScale
2. Crie um novo banco MySQL
3. Execute o conteúdo de `MyLinks.sql` no console SQL
4. Copie a URL de conexão

### 3️⃣ **Configurar Variável de Ambiente**
```env
# .env do backend
CONN_URL=mysql://user:password@host:port/MyLinks
```

---

## 📌 Campos Principais

### **Tabela: usuarios**
| Campo | Tipo | Restrições | Descrição |
|-------|------|------------|-----------|
| `id` | INT | PK, AUTO_INCREMENT | Identificador único |
| `username` | VARCHAR(255) | UNIQUE | Nome de usuário |
| `email` | VARCHAR(255) | UNIQUE | E-mail do usuário |
| `senha` | VARCHAR(255) | NOT NULL | Hash bcrypt da senha |
| `foto_perfil` | VARCHAR(255) | NULL | URL da foto (Cloudinary) |

### **Tabela: links**
| Campo | Tipo | Restrições | Descrição |
|-------|------|------------|-----------|
| `id` | INT | PK, AUTO_INCREMENT | Identificador único |
| `usuario_id` | INT | FK, ON DELETE CASCADE | ID do dono do link |
| `titulo` | VARCHAR(100) | - | Título do link (ex: "Meu GitHub") |
| `url` | VARCHAR(150) | - | URL completa |
| `ordem` | INT | - | Posição na lista (reordenação) |

---

## 🔒 Segurança

- ✅ **Senhas NUNCA são armazenadas em texto puro**
- ✅ Utiliza **bcrypt** para hash irreversível
- ✅ Constraints de **unicidade** em username e email
- ✅ **ON DELETE CASCADE** mantém integridade referencial

---

## 🛠️ Manutenção

### **Adicionar Índices (Opcional - Performance)**
```sql
-- Otimizar buscas por username
CREATE INDEX idx_username ON usuarios(username);

-- Otimizar listagem ordenada de links
CREATE INDEX idx_usuario_ordem ON links(usuario_id, ordem);
```

### **Adicionar Timestamps (Opcional - Auditoria)**
```sql
ALTER TABLE usuarios ADD COLUMN created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE links ADD COLUMN created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
```

---

## 📚 Repositórios Relacionados

- **Backend (API)**: [mylinks-api](https://github.com/seu-usuario/mylinks-api)
- **Frontend**: [mylinks-frontend](https://github.com/seu-usuario/mylinks-frontend)

---

## 📄 Licença

Este projeto foi desenvolvido como parte do **Curso Técnico em Desenvolvimento de Sistemas - SENAI Cabo**.

---

**Desenvolvido por**: [Luiz, Thalis, Diego, Renan e João] | 
**Docente**: Givanio José de Melo
