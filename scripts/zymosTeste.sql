-- =========================================================
-- BANCO DE DADOS ZYMOS - MODELO PARA MVP
-- =========================================================
DROP DATABASE zymos;

CREATE DATABASE zymos;
USE zymos;

-- =========================================================
-- 1. TABELAS DE OPÇÕES / DOMÍNIO (Substituem os CHECKs)
-- =========================================================

-- Tabela de opções de planos
CREATE TABLE plano (
    id_plano INT PRIMARY KEY AUTO_INCREMENT,
    nome_plano VARCHAR(20) NOT NULL
);

-- Tabela de opções de cargos dos usuários
CREATE TABLE cargo (
    id_cargo INT PRIMARY KEY AUTO_INCREMENT,
    nome_cargo VARCHAR(50) NOT NULL
);

-- Tabela de tipos de cerveja (Ale, Lager, etc.)
CREATE TABLE tipo_cerveja (
    id_tipo_cerveja INT PRIMARY KEY AUTO_INCREMENT,
    nome_tipo VARCHAR(20) NOT NULL
);

-- Tabela de leveduras de cerveja
CREATE TABLE levedura (
    id_levedura INT PRIMARY KEY AUTO_INCREMENT,
    nome_levedura VARCHAR(100) NOT NULL
);

-- Tabela de opções de status para os tanques
CREATE TABLE status_tanque (
    id_status_tanque INT PRIMARY KEY AUTO_INCREMENT,
    nome_status VARCHAR(30) NOT NULL
);

-- Tabela de opções de status para os lotes
CREATE TABLE status_lote (
    id_status_lote INT PRIMARY KEY AUTO_INCREMENT,
    nome_status VARCHAR(20) NOT NULL
);

-- Tabela de tipos de alertas
CREATE TABLE tipo_alerta (
    id_tipo_alerta INT PRIMARY KEY AUTO_INCREMENT,
    nome_tipo VARCHAR(50) NOT NULL
);


-- =========================================================
-- 2. TABELAS DE CADASTRO E CONTROLE DA FÁBRICA
-- =========================================================

-- Tabela de Empresas
CREATE TABLE empresa (
    id_empresa INT PRIMARY KEY AUTO_INCREMENT,
    fk_plano INT NOT NULL,
    nome_empresa VARCHAR(100) NOT NULL,
    cnpj CHAR(14) UNIQUE NOT NULL,
    data_cadastro DATETIME DEFAULT CURRENT_TIMESTAMP,
    data_atualizacao DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_empresa_plano FOREIGN KEY (fk_plano) REFERENCES plano(id_plano)
);

-- Tabela de Usuários
CREATE TABLE usuario (
    id_usuario INT PRIMARY KEY AUTO_INCREMENT,
    fk_empresa INT NOT NULL,
    fk_cargo INT NOT NULL,
    nome VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    senha VARCHAR(255) NOT NULL,
    status_usuario VARCHAR(10) NOT NULL DEFAULT 'Ativo',
    data_criacao DATETIME DEFAULT CURRENT_TIMESTAMP,
    data_atualizacao DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_usuario_empresa FOREIGN KEY (fk_empresa) REFERENCES empresa(id_empresa),
    CONSTRAINT fk_usuario_cargo FOREIGN KEY (fk_cargo) REFERENCES cargo(id_cargo)
);

-- Tabela de Cervejas
CREATE TABLE cerveja (
    id_cerveja INT PRIMARY KEY AUTO_INCREMENT,
    fk_tipo_cerveja INT NOT NULL,
    fk_levedura INT NOT NULL,
    nome_estilo VARCHAR(50) NOT NULL,
    temperatura_min DECIMAL(3,1) NOT NULL,
    temperatura_max DECIMAL(3,1) NOT NULL,
    temperatura_ideal DECIMAL(3,1) NOT NULL,
    tempo_fermentacao_dias INT NOT NULL,
    data_cadastro DATETIME DEFAULT CURRENT_TIMESTAMP,
    data_atualizacao DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_cerveja_tipo FOREIGN KEY (fk_tipo_cerveja) REFERENCES tipo_cerveja(id_tipo_cerveja),
    CONSTRAINT fk_cerveja_levedura FOREIGN KEY (fk_levedura) REFERENCES levedura(id_levedura)
);

-- Tabela de Tanques
CREATE TABLE tanque (
    id_tanque INT PRIMARY KEY AUTO_INCREMENT,
    fk_empresa INT NOT NULL,
    fk_status_tanque INT NOT NULL,
    identificador_tanque VARCHAR(30) NOT NULL,
    capacidade_litros INT NOT NULL,
    data_cadastro DATETIME DEFAULT CURRENT_TIMESTAMP,
    data_atualizacao DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_tanque_empresa FOREIGN KEY (fk_empresa) REFERENCES empresa(id_empresa),
    CONSTRAINT fk_tanque_status FOREIGN KEY (fk_status_tanque) REFERENCES status_tanque(id_status_tanque)
);

-- Tabela de Sensores
CREATE TABLE sensor (
    id_sensor INT PRIMARY KEY AUTO_INCREMENT,
    fk_tanque INT NOT NULL,
    modelo VARCHAR(20) NOT NULL DEFAULT 'LM35',
    status_sensor VARCHAR(10) NOT NULL DEFAULT 'Ativo',
    data_instalacao DATETIME DEFAULT CURRENT_TIMESTAMP,
    data_atualizacao DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_sensor_tanque FOREIGN KEY (fk_tanque) REFERENCES tanque(id_tanque)
);

-- Tabela de Lotes
CREATE TABLE lote (
    id_lote INT PRIMARY KEY AUTO_INCREMENT,
    codigo_lote VARCHAR(20) UNIQUE NOT NULL,
    fk_tanque INT NOT NULL,
    fk_cerveja INT NOT NULL,
    fk_usuario_criador INT NOT NULL,
    fk_status_lote INT NOT NULL,
    data_inicio DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    data_fim DATETIME NULL,
    data_atualizacao DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_lote_tanque FOREIGN KEY (fk_tanque) REFERENCES tanque(id_tanque),
    CONSTRAINT fk_lote_cerveja FOREIGN KEY (fk_cerveja) REFERENCES cerveja(id_cerveja),
    CONSTRAINT fk_lote_usuario FOREIGN KEY (fk_usuario_criador) REFERENCES usuario(id_usuario),
    CONSTRAINT fk_lote_status FOREIGN KEY (fk_status_lote) REFERENCES status_lote(id_status_lote)
) AUTO_INCREMENT = 100;


-- =========================================================
-- 3. TABELAS DE TELEMETRIA E ALERTAS (Históricos / Logs)
-- =========================================================

-- Tabela de Leitura contínua dos Sensores
CREATE TABLE leitura_sensor (
    id_leitura INT PRIMARY KEY AUTO_INCREMENT,
    fk_sensor INT NOT NULL,
    fk_lote INT NOT NULL,
    temperatura DECIMAL(3,1) NOT NULL,
    data_hora DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_leitura_sensor FOREIGN KEY (fk_sensor) REFERENCES sensor(id_sensor),
    CONSTRAINT fk_leitura_lote FOREIGN KEY (fk_lote) REFERENCES lote(id_lote)
);

-- Tabela de Alertas de Temperatura
CREATE TABLE alerta (
    id_alerta INT PRIMARY KEY AUTO_INCREMENT,
    fk_leitura INT NOT NULL,
    fk_tipo_alerta INT NOT NULL,
    descricao VARCHAR(255),
    CONSTRAINT fk_alerta_leitura FOREIGN KEY (fk_leitura) REFERENCES leitura_sensor(id_leitura),
    CONSTRAINT fk_alerta_tipo FOREIGN KEY (fk_tipo_alerta) REFERENCES tipo_alerta(id_tipo_alerta)
);


-- =========================================================
-- 4. POVOAMENTO INICIAL (INSERÇÃO DOS DADOS)
-- =========================================================

-- Povoando as opções das tabelas auxiliares
INSERT INTO plano (nome_plano) VALUES ('Craft'), ('Regional'), ('Industrial');
INSERT INTO cargo (nome_cargo) VALUES ('Administrador'), ('Mestre Cervejeiro'), ('Operador'), ('Qualidade');
INSERT INTO tipo_cerveja (nome_tipo) VALUES ('Ale'), ('Lager');
INSERT INTO levedura (nome_levedura) VALUES ('Saccharomyces cerevisiae'), ('Saccharomyces pastorianus'), ('Saccharomyces carlsbergensis');
INSERT INTO status_tanque (nome_status) VALUES ('Disponível'), ('Em uso'), ('Em limpeza'), ('Manutenção'), ('Indisponível');
INSERT INTO status_lote (nome_status) VALUES ('Em andamento'), ('Finalizado'), ('Cancelado');
INSERT INTO tipo_alerta (nome_tipo) VALUES ('Temperatura acima do ideal'), ('Temperatura abaixo da ideal'), ('Tendência de desvio');

-- 1. Cadastro da Empresa (fk_plano = 3 é Industrial)
INSERT INTO empresa (fk_plano, nome_empresa, cnpj) VALUES 
(3, 'Cervejaria Ambev - Unidade SP', '12344321000199');

-- 2. Cadastro dos Usuários (1 = Admin, 2 = Mestre Cervejeiro)
INSERT INTO usuario (fk_empresa, fk_cargo, nome, email, senha) VALUES 
(1, 1, 'Carlos Silva', 'carlos.silva@ambev.com.br', 'hash_senha_123'),
(1, 2, 'Juliana Mestre', 'juliana.qualidade@ambev.com.br', 'hash_senha_456');

-- 3. Cadastro dos Estilos de Cerveja (1 = Ale, 2 = Lager / 1 = S. cerevisiae, 2 = S. pastorianus)
INSERT INTO cerveja (fk_tipo_cerveja, fk_levedura, nome_estilo, temperatura_min, temperatura_max, temperatura_ideal, tempo_fermentacao_dias) VALUES 
(1, 1, 'India Pale Ale (IPA)', 15.0, 24.0, 20.0, 14),
(2, 2, 'Pilsen', 8.0, 14.0, 10.0, 21);

-- 4. Setup dos Tanques (2 = Em uso, 1 = Disponível)
INSERT INTO tanque (fk_empresa, fk_status_tanque, identificador_tanque, capacidade_litros) VALUES 
(1, 2, 'Tanque TQ-01', 10000),
(1, 1, 'Tanque TQ-02', 10000);

-- 5. Cadastro do Sensor
INSERT INTO sensor (fk_tanque, modelo) VALUES 
(1, 'LM35'),
(2, 'LM35');

-- 6. Abertura do Lote (1 = Em andamento)
INSERT INTO lote (codigo_lote, fk_tanque, fk_cerveja, fk_usuario_criador, fk_status_lote) VALUES 
('LOTE-2026-101', 1, 1, 2, 1);

-- 7. Telemetria e Alerta (1 = Temperatura acima do ideal)
INSERT INTO leitura_sensor (fk_sensor, fk_lote, temperatura) VALUES 
(1, 100, 25.2);

INSERT INTO alerta (fk_leitura, fk_tipo_alerta, descricao) VALUES 
(1, 1, 'Leitura de 25.2°C ultrapassou a máxima de 24.0°C definida para o estilo IPA.');


-- =========================================================
-- 5. CONSULTA DE TESTE DE FUNCIONAMENTO
-- =========================================================

SELECT 
    u.id_usuario,
    u.nome AS 'Usuário',
    u.email AS 'E-mail de Login',
    c.nome_cargo AS 'Cargo',
    e.nome_empresa AS 'Empresa',
    p.nome_plano AS 'Plano Zymos',
    u.data_atualizacao AS 'Última Alteração do Usuário'
FROM usuario u
JOIN empresa e ON u.fk_empresa = e.id_empresa
JOIN plano p ON e.fk_plano = p.id_plano
JOIN cargo c ON u.fk_cargo = c.id_cargo
WHERE u.email = 'carlos.silva@ambev.com.br';