-- ============================================
-- MELHORIAS DE DATABASE E INFRAESTRUTURA
-- ============================================

CREATE TABLE IF NOT EXISTS usuarios (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(255) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    senha VARCHAR(255) NOT NULL,
    foto_perfil VARCHAR(255)
);

CREATE TABLE IF NOT EXISTS links (
    id INT AUTO_INCREMENT PRIMARY KEY,
    usuario_id INT NOT NULL,
    titulo VARCHAR(100),
    url VARCHAR(255),
    ordem INT,
    FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE
);

-- ============================================
-- 1. ÍNDICES OTIMIZADOS
-- ============================================

-- Problema: Faltam índices em colunas frequentemente consultadas
-- Solução: Adicionar índices estratégicos

-- Índice único em username (já existe)
CREATE UNIQUE INDEX idx_usuarios_username ON usuarios(username);

-- Índice único em email (já existe)
CREATE UNIQUE INDEX idx_usuarios_email ON usuarios(email);

-- NOVO: Índice composto para busca de links por usuário e ordem
CREATE INDEX idx_links_usuario_ordem ON links(usuario_id, ordem);


-- ============================================
-- 2. AUDITORIA E LOGGING
-- ============================================

-- Tabela de auditoria de alterações
CREATE TABLE auditoria (
    id INT AUTO_INCREMENT PRIMARY KEY,
    usuario_id INT,
    acao VARCHAR(50) NOT NULL,
    tabela VARCHAR(50) NOT NULL,
    registro_id INT,
    dados_antes JSON,
    dados_depois JSON,
    ip_address VARCHAR(45),
    user_agent TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_auditoria_usuario (usuario_id),
    INDEX idx_auditoria_acao (acao),
    INDEX idx_auditoria_created (created_at),
    FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE SET NULL
) ENGINE=InnoDB;

-- Tabela de tentativas de login
CREATE TABLE login_attempts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    email VARCHAR(255),
    ip_address VARCHAR(45) NOT NULL,
    sucesso BOOLEAN DEFAULT FALSE,
    motivo_falha VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_login_attempts_email (email),
    INDEX idx_login_attempts_ip (ip_address),
    INDEX idx_login_attempts_created (created_at)
) ENGINE=InnoDB;

-- Limpeza automática de registros antigos (>90 dias)
CREATE EVENT limpar_auditoria_antiga
ON SCHEDULE EVERY 1 DAY
DO
    DELETE FROM auditoria WHERE created_at < DATE_SUB(NOW(), INTERVAL 90 DAY);

CREATE EVENT limpar_login_attempts_antigos
ON SCHEDULE EVERY 1 DAY
DO
    DELETE FROM login_attempts WHERE created_at < DATE_SUB(NOW(), INTERVAL 30 DAY);


-- ============================================
-- 3. SOFT DELETE (em vez de hard delete)
-- ============================================

-- Adicionar coluna deleted_at nas tabelas
ALTER TABLE usuarios 
ADD COLUMN deleted_at TIMESTAMP NULL,
ADD COLUMN deleted_by INT NULL,
ADD INDEX idx_usuarios_deleted (deleted_at);

ALTER TABLE links 
ADD COLUMN deleted_at TIMESTAMP NULL,
ADD INDEX idx_links_deleted (deleted_at);

-- Trigger para soft delete de links quando usuário é deletado
DELIMITER //
CREATE TRIGGER soft_delete_user_links
BEFORE UPDATE ON usuarios
FOR EACH ROW
BEGIN
    IF NEW.deleted_at IS NOT NULL AND OLD.deleted_at IS NULL THEN
        UPDATE links 
        SET deleted_at = NEW.deleted_at 
        WHERE usuario_id = NEW.id AND deleted_at IS NULL;
    END IF;
END//
DELIMITER ;


-- ============================================
-- 4. TIMESTAMPS AUTOMÁTICOS
-- ============================================

ALTER TABLE usuarios 
ADD COLUMN created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
ADD COLUMN updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP;

ALTER TABLE links 
ADD COLUMN created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
ADD COLUMN updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP;


-- ============================================
-- 5. CONSTRAINTS E VALIDAÇÕES
-- ============================================

-- Adicionar constraints de tamanho
ALTER TABLE usuarios 
MODIFY COLUMN username VARCHAR(20) NOT NULL,
MODIFY COLUMN email VARCHAR(255) NOT NULL,
ADD CONSTRAINT chk_username_length CHECK (CHAR_LENGTH(username) >= 3);

ALTER TABLE links 
MODIFY COLUMN titulo VARCHAR(100) NOT NULL,
MODIFY COLUMN url VARCHAR(500) NOT NULL, -- 150 é muito curto
ADD CONSTRAINT chk_titulo_not_empty CHECK (TRIM(titulo) != ''),
ADD CONSTRAINT chk_url_not_empty CHECK (TRIM(url) != '');


-- ============================================
-- 6. ESTATÍSTICAS E ANALYTICS
-- ============================================

CREATE TABLE link_clicks (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    link_id INT NOT NULL,
    usuario_id INT NOT NULL,
    clicked_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ip_address VARCHAR(45),
    user_agent TEXT,
    referrer VARCHAR(500),
    INDEX idx_clicks_link (link_id),
    INDEX idx_clicks_usuario (usuario_id),
    INDEX idx_clicks_date (clicked_at),
    FOREIGN KEY (link_id) REFERENCES links(id) ON DELETE CASCADE,
    FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- View para estatísticas agregadas
CREATE OR REPLACE VIEW link_statistics AS
SELECT 
    l.id AS link_id,
    l.titulo,
    l.usuario_id,
    COUNT(lc.id) AS total_clicks,
    COUNT(DISTINCT lc.ip_address) AS unique_visitors,
    MAX(lc.clicked_at) AS last_click,
    DATE(lc.clicked_at) AS click_date
FROM links l
LEFT JOIN link_clicks lc ON l.id = lc.link_id
WHERE l.deleted_at IS NULL
GROUP BY l.id, l.titulo, l.usuario_id, DATE(lc.clicked_at);


-- ============================================
-- 7. BACKUP E RECOVERY
-- ============================================

-- Procedure para backup manual
DELIMITER //
CREATE PROCEDURE backup_user_data(IN p_usuario_id INT)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Erro ao fazer backup';
    END;

    START TRANSACTION;

    -- Backup do usuário
    CREATE TEMPORARY TABLE IF NOT EXISTS temp_backup_user AS
    SELECT * FROM usuarios WHERE id = p_usuario_id;

    -- Backup dos links
    CREATE TEMPORARY TABLE IF NOT EXISTS temp_backup_links AS
    SELECT * FROM links WHERE usuario_id = p_usuario_id;

    COMMIT;

    SELECT 'Backup realizado com sucesso' AS status;
END//
DELIMITER ;


-- ============================================
-- 8. OTIMIZAÇÃO DE QUERIES COMUNS
-- ============================================

-- View materializada para perfis públicos mais acessados
CREATE TABLE cache_perfis_publicos (
    usuario_id INT PRIMARY KEY,
    username VARCHAR(20),
    foto_perfil VARCHAR(255),
    links_json JSON,
    total_links INT,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- Procedure para atualizar cache
DELIMITER //
CREATE PROCEDURE atualizar_cache_perfil(IN p_usuario_id INT)
BEGIN
    DELETE FROM cache_perfis_publicos WHERE usuario_id = p_usuario_id;

    INSERT INTO cache_perfis_publicos (usuario_id, username, foto_perfil, links_json, total_links)
    SELECT 
        u.id,
        u.username,
        u.foto_perfil,
        JSON_ARRAYAGG(
            JSON_OBJECT(
                'id', l.id,
                'titulo', l.titulo,
                'url', l.url,
                'ordem', l.ordem
            )
        ) AS links_json,
        COUNT(l.id) AS total_links
    FROM usuarios u
    LEFT JOIN links l ON u.id = l.usuario_id AND l.deleted_at IS NULL
    WHERE u.id = p_usuario_id AND u.deleted_at IS NULL
    GROUP BY u.id, u.username, u.foto_perfil;
END//
DELIMITER ;

-- Trigger para atualizar cache automaticamente
DELIMITER //
CREATE TRIGGER atualizar_cache_apos_link
AFTER INSERT ON links
FOR EACH ROW
BEGIN
    CALL atualizar_cache_perfil(NEW.usuario_id);
END//

CREATE TRIGGER atualizar_cache_apos_update_link
AFTER UPDATE ON links
FOR EACH ROW
BEGIN
    CALL atualizar_cache_perfil(NEW.usuario_id);
END//

CREATE TRIGGER atualizar_cache_apos_delete_link
AFTER DELETE ON links
FOR EACH ROW
BEGIN
    CALL atualizar_cache_perfil(OLD.usuario_id);
END//
DELIMITER ;


-- ============================================
-- 9. PARTICIONAMENTO (para escala futura)
-- ============================================

-- Particionar tabela de auditoria por data
ALTER TABLE auditoria 
PARTITION BY RANGE (YEAR(created_at)) (
    PARTITION p_2024 VALUES LESS THAN (2025),
    PARTITION p_2025 VALUES LESS THAN (2026),
    PARTITION p_2026 VALUES LESS THAN (2027),
    PARTITION p_future VALUES LESS THAN MAXVALUE
);


-- ============================================
-- 10. MONITORAMENTO DE PERFORMANCE
-- ============================================

-- View para queries lentas
CREATE OR REPLACE VIEW slow_queries AS
SELECT 
    DIGEST_TEXT AS query,
    COUNT_STAR AS exec_count,
    AVG_TIMER_WAIT/1000000000000 AS avg_time_sec,
    MAX_TIMER_WAIT/1000000000000 AS max_time_sec,
    SUM_ROWS_EXAMINED AS rows_examined
FROM performance_schema.events_statements_summary_by_digest
WHERE AVG_TIMER_WAIT > 1000000000 -- > 1ms
ORDER BY AVG_TIMER_WAIT DESC
LIMIT 20;

-- View para tamanho das tabelas
CREATE OR REPLACE VIEW table_sizes AS
SELECT 
    TABLE_NAME,
    ROUND(((DATA_LENGTH + INDEX_LENGTH) / 1024 / 1024), 2) AS size_mb,
    TABLE_ROWS
FROM information_schema.TABLES
WHERE TABLE_SCHEMA = 'MyLinks'
ORDER BY (DATA_LENGTH + INDEX_LENGTH) DESC;


-- ============================================
-- COMANDOS DE MANUTENÇÃO PERIÓDICA
-- ============================================

-- Otimizar tabelas (rodar mensalmente)
OPTIMIZE TABLE usuarios;
OPTIMIZE TABLE links;
OPTIMIZE TABLE auditoria;
OPTIMIZE TABLE login_attempts;

-- Analisar tabelas (atualizar estatísticas)
ANALYZE TABLE usuarios;
ANALYZE TABLE links;

-- Verificar integridade
CHECK TABLE usuarios;
CHECK TABLE links;
