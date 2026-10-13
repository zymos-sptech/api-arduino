-- =========================================================
-- BANCO DE DADOS ZYMOS - MODELO PARA MVP (v3)
-- =========================================================
-- O que mudou da v2 pra v3:
--   - NOVA tabela unidade: uma empresa pode ter mais de uma fabrica
--     (endereco em campos separados - exemplo de campo composto)
--   - tanque agora pertence a uma unidade (fk_unidade), nao direto a empresa
--   - leitura_sensor continua só com fk_lote (nunca fk_tanque junto,
--     ver comentario na criacao da tabela)
--
-- Jornada do cliente coberta por este modelo:
--   1. Empresa preenche o formulario do site        -> tabela contato
--   2. Zymos fecha contrato e cadastra a empresa    -> tabela empresa
--   3. Zymos gera o codigo de ativacao              -> tabela codigo_ativacao
--   4. Cliente usa o codigo e cadastra os usuarios  -> tabela usuario
--   5. Cliente cadastra a(s) unidade(s) da empresa    -> tabela unidade
--   6. Cliente cadastra tanques, sensores e lotes   -> tanque, sensor, lote
--   7. Arduino envia leituras e o sistema gera alertas -> leitura_sensor, alerta
-- =========================================================

DROP DATABASE IF EXISTS zymos;

CREATE DATABASE zymos;

USE zymos;

-- =========================================================
-- 1. TABELAS DE OPCOES / DOMINIO (alimentam os dropdowns)
-- =========================================================

-- Em tanques_max o NULL = sem limite (Industrial)
CREATE TABLE plano (
    id_plano INT PRIMARY KEY AUTO_INCREMENT,
    nome_plano VARCHAR(20) NOT NULL,
    tanques_min INT NOT NULL,
    tanques_max INT NULL,
    valor_setup_tanque DECIMAL(8,2) NOT NULL,
    valor_mensal_tanque DECIMAL(8,2) NOT NULL
);

CREATE TABLE cargo (
    id_cargo INT PRIMARY KEY AUTO_INCREMENT,
    nome_cargo VARCHAR(50) NOT NULL
);

CREATE TABLE tipo_cerveja (
    id_tipo_cerveja INT PRIMARY KEY AUTO_INCREMENT,
    nome_tipo VARCHAR(20) NOT NULL
);

CREATE TABLE levedura (
    id_levedura INT PRIMARY KEY AUTO_INCREMENT,
    nome_levedura VARCHAR(100) NOT NULL
);

CREATE TABLE status_tanque (
    id_status_tanque INT PRIMARY KEY AUTO_INCREMENT,
    nome_status VARCHAR(30) NOT NULL
);

CREATE TABLE status_lote (
    id_status_lote INT PRIMARY KEY AUTO_INCREMENT,
    nome_status VARCHAR(20) NOT NULL
);

CREATE TABLE tipo_alerta (
    id_tipo_alerta INT PRIMARY KEY AUTO_INCREMENT,
    nome_tipo VARCHAR(50) NOT NULL
);

CREATE TABLE status_contato (
    id_status_contato INT PRIMARY KEY AUTO_INCREMENT,
    nome_status VARCHAR(30) NOT NULL
);

CREATE TABLE status_empresa (
    id_status_empresa INT PRIMARY KEY AUTO_INCREMENT,
    nome_status VARCHAR(20) NOT NULL
);

CREATE TABLE status_codigo (
    id_status_codigo INT PRIMARY KEY AUTO_INCREMENT,
    nome_status VARCHAR(20) NOT NULL
);

CREATE TABLE status_usuario (
    id_status_usuario INT PRIMARY KEY AUTO_INCREMENT,
    nome_status VARCHAR(20) NOT NULL
);

CREATE TABLE status_sensor (
    id_status_sensor INT PRIMARY KEY AUTO_INCREMENT,
    nome_status VARCHAR(20) NOT NULL
);

-- Faixa de tanques escolhida no formulario de contato (botoes do protótipo)
CREATE TABLE faixa_tanques (
    id_faixa_tanques INT PRIMARY KEY AUTO_INCREMENT,
    nome_faixa VARCHAR(20) NOT NULL
);


-- =========================================================
-- 2. TABELAS DE CADASTRO E CONTROLE
-- =========================================================

-- Contatos recebidos pelo formulario "Solicitar Demonstração & Proposta" do site
-- (ainda nao e cliente, e apenas um interessado / lead)
CREATE TABLE contato (
    id_contato INT PRIMARY KEY AUTO_INCREMENT,
    fk_status_contato INT NOT NULL DEFAULT 1,     
    fk_faixa_tanques INT NOT NULL,
    nome_completo VARCHAR(100) NOT NULL,
    email_corporativo VARCHAR(100) NOT NULL,
    nome_empresa VARCHAR(100) NOT NULL,             -- "Cervejaria / Empresa" no formulario
    mensagem VARCHAR(500) NULL,                     -- "Mensagem / Perfil da Operação", opcional
    aceite_contato BOOLEAN NOT NULL,                -- checkbox de consentimento, obrigatorio marcar
    data_contato DATETIME DEFAULT CURRENT_TIMESTAMP,
    data_atualizacao DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT ckfk_contato_status FOREIGN KEY (fk_status_contato) REFERENCES status_contato(id_status_contato),
    CONSTRAINT ckfk_contato_faixa FOREIGN KEY (fk_faixa_tanques) REFERENCES faixa_tanques(id_faixa_tanques),
    CONSTRAINT ck_contato_aceite CHECK (aceite_contato = 1)
);

-- Empresas clientes (cadastradas SOMENTE pela equipe Zymos apos o contrato)
CREATE TABLE empresa (
    id_empresa INT PRIMARY KEY AUTO_INCREMENT,
    fk_plano INT NOT NULL,
    fk_status_empresa INT NOT NULL DEFAULT 1,      -- 1 = Ativa
    fk_contato INT NULL,                           -- de qual contato do site ela veio
    nome_empresa VARCHAR(100) NOT NULL,
    cnpj CHAR(14) UNIQUE NOT NULL,
    data_inicio_contrato DATE NOT NULL,
    data_cadastro DATETIME DEFAULT CURRENT_TIMESTAMP,
    data_atualizacao DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT ckfk_empresa_plano FOREIGN KEY (fk_plano) REFERENCES plano(id_plano),
    CONSTRAINT ckfk_empresa_status FOREIGN KEY (fk_status_empresa) REFERENCES status_empresa(id_status_empresa),
    CONSTRAINT ckfk_empresa_contato FOREIGN KEY (fk_contato) REFERENCES contato(id_contato)
);

-- NOVA: Unidades (fabricas) da empresa. Uma empresa pode ter mais de uma.
-- Endereco em campos separados = exemplo de campo composto (rua+numero+
-- complemento+bairro+cidade+uf+cep formam UM atributo "endereco").
CREATE TABLE unidade (
    id_unidade INT PRIMARY KEY AUTO_INCREMENT,
    fk_empresa INT NOT NULL,
    nome_unidade VARCHAR(100) NOT NULL,            -- ex: "Fábrica Matriz"
    logradouro VARCHAR(150) NOT NULL,
    numero VARCHAR(10) NOT NULL,
    complemento VARCHAR(100) NULL,
    bairro VARCHAR(80) NOT NULL,
    cidade VARCHAR(80) NOT NULL,
    uf CHAR(2) NOT NULL,
    cep CHAR(8) NOT NULL,
    data_cadastro DATETIME DEFAULT CURRENT_TIMESTAMP,
    data_atualizacao DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT ckfk_unidade_empresa FOREIGN KEY (fk_empresa) REFERENCES empresa(id_empresa)
);

-- Codigo de ativacao que a Zymos entrega ao cliente
CREATE TABLE codigo_ativacao (
    id_codigo_ativacao INT PRIMARY KEY AUTO_INCREMENT,
    fk_empresa INT NOT NULL,
    fk_status_codigo INT NOT NULL DEFAULT 1,       -- 1 = Ativo
    codigo VARCHAR(20) UNIQUE NOT NULL,
    data_geracao DATETIME DEFAULT CURRENT_TIMESTAMP,
    data_expiracao DATETIME NULL,
    CONSTRAINT ckfk_codigo_empresa FOREIGN KEY (fk_empresa) REFERENCES empresa(id_empresa),
    CONSTRAINT ckfk_codigo_status FOREIGN KEY (fk_status_codigo) REFERENCES status_codigo(id_status_codigo)
);

-- Usuarios da plataforma
CREATE TABLE usuario (
    id_usuario INT PRIMARY KEY AUTO_INCREMENT,
    fk_empresa INT NOT NULL,
    fk_cargo INT NOT NULL,
    fk_status_usuario INT NOT NULL DEFAULT 1,      -- 1 = Ativo
    nome VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    senha VARCHAR(255) NOT NULL,                   -- guardar o HASH da senha, nunca a senha pura
    data_criacao DATETIME DEFAULT CURRENT_TIMESTAMP,
    data_atualizacao DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT ckfk_usuario_empresa FOREIGN KEY (fk_empresa) REFERENCES empresa(id_empresa),
    CONSTRAINT ckfk_usuario_cargo FOREIGN KEY (fk_cargo) REFERENCES cargo(id_cargo),
    CONSTRAINT ckfk_usuario_status FOREIGN KEY (fk_status_usuario) REFERENCES status_usuario(id_status_usuario)
);

-- Catalogo de estilos de cerveja (faixas de temperatura usadas nos alertas)
CREATE TABLE cerveja (
    id_cerveja INT PRIMARY KEY AUTO_INCREMENT,
    fk_tipo_cerveja INT NOT NULL,
    fk_levedura INT NOT NULL,
    nome_estilo VARCHAR(50) NOT NULL,
    temperatura_min DECIMAL(4,1) NOT NULL,
    temperatura_max DECIMAL(4,1) NOT NULL,
    temperatura_ideal DECIMAL(4,1) NOT NULL,
    tempo_fermentacao_dias INT NOT NULL,
    data_cadastro DATETIME DEFAULT CURRENT_TIMESTAMP,
    data_atualizacao DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT ckfk_cerveja_tipo FOREIGN KEY (fk_tipo_cerveja) REFERENCES tipo_cerveja(id_tipo_cerveja),
    CONSTRAINT ckfk_cerveja_levedura FOREIGN KEY (fk_levedura) REFERENCES levedura(id_levedura),
    CONSTRAINT ck_cerveja_faixa CHECK (
        temperatura_min < temperatura_max
        AND temperatura_ideal BETWEEN temperatura_min AND temperatura_max
    )
);

-- Tanque agora pertence a uma UNIDADE (nao direto a empresa).
-- Chega na empresa indiretamente: tanque -> unidade -> empresa.
CREATE TABLE tanque (
    id_tanque INT PRIMARY KEY AUTO_INCREMENT,
    fk_unidade INT NOT NULL,
    fk_status_tanque INT NOT NULL DEFAULT 1,       -- 1 = Disponivel
    identificador_tanque VARCHAR(30) NOT NULL,
    capacidade_litros INT NOT NULL,
    data_cadastro DATETIME DEFAULT CURRENT_TIMESTAMP,
    data_atualizacao DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT ckfk_tanque_unidade FOREIGN KEY (fk_unidade) REFERENCES unidade(id_unidade),
    CONSTRAINT ckfk_tanque_status FOREIGN KEY (fk_status_tanque) REFERENCES status_tanque(id_status_tanque),
    CONSTRAINT uq_tanque_unidade UNIQUE (fk_unidade, identificador_tanque)  -- nao repete TQ-01 na mesma unidade
);

CREATE TABLE sensor (
    id_sensor INT PRIMARY KEY AUTO_INCREMENT,
    fk_tanque INT NOT NULL,
    fk_status_sensor INT NOT NULL DEFAULT 1,       -- 1 = Ativo
    modelo VARCHAR(20) NOT NULL DEFAULT 'LM35',
    data_instalacao DATETIME DEFAULT CURRENT_TIMESTAMP,
    data_atualizacao DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT ckfk_sensor_tanque FOREIGN KEY (fk_tanque) REFERENCES tanque(id_tanque),
    CONSTRAINT ckfk_sensor_status FOREIGN KEY (fk_status_sensor) REFERENCES status_sensor(id_status_sensor)
);

-- Lote = a fermentacao em si: 1 tanque, 1 estilo, 1 responsavel, 1 janela de tempo.
CREATE TABLE lote (
    id_lote INT PRIMARY KEY AUTO_INCREMENT,
    codigo_lote VARCHAR(20) UNIQUE NOT NULL,
    fk_tanque INT NOT NULL,
    fk_cerveja INT NOT NULL,
    fk_usuario_criador INT NOT NULL,
    fk_status_lote INT NOT NULL DEFAULT 1,         -- 1 = Em andamento
    data_inicio DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    data_fim DATETIME NULL,
    data_atualizacao DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT ckfk_lote_tanque FOREIGN KEY (fk_tanque) REFERENCES tanque(id_tanque),
    CONSTRAINT ckfk_lote_cerveja FOREIGN KEY (fk_cerveja) REFERENCES cerveja(id_cerveja),
    CONSTRAINT ckfk_lote_usuario FOREIGN KEY (fk_usuario_criador) REFERENCES usuario(id_usuario),
    CONSTRAINT ckfk_lote_status FOREIGN KEY (fk_status_lote) REFERENCES status_lote(id_status_lote)
) AUTO_INCREMENT = 100;


-- =========================================================
-- 3. TELEMETRIA E ALERTAS (historicos / logs)
-- =========================================================

-- Leitura so tem fk_lote (NAO fk_tanque junto): o tanque ja e alcancado
-- indiretamente via lote -> tanque. Botar os dois seria dado duplicado
-- e cria risco de inconsistencia se o fk_tanque do lote mudar.
CREATE TABLE leitura_sensor (
    id_leitura BIGINT PRIMARY KEY AUTO_INCREMENT,
    fk_sensor INT NOT NULL,
    fk_lote INT NOT NULL,
    temperatura DECIMAL(4,1) NOT NULL,
    data_hora DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT ckfk_leitura_sensor FOREIGN KEY (fk_sensor) REFERENCES sensor(id_sensor),
    CONSTRAINT ckfk_leitura_lote FOREIGN KEY (fk_lote) REFERENCES lote(id_lote),
    INDEX idx_leitura_lote_data (fk_lote, data_hora),
    INDEX idx_leitura_sensor_data (fk_sensor, data_hora)
);

CREATE TABLE alerta (
    id_alerta INT PRIMARY KEY AUTO_INCREMENT,
    fk_leitura BIGINT NOT NULL,
    fk_tipo_alerta INT NOT NULL,
    descricao VARCHAR(255),
    data_alerta DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    data_resolucao DATETIME NULL,
    CONSTRAINT ckfk_alerta_leitura FOREIGN KEY (fk_leitura) REFERENCES leitura_sensor(id_leitura),
    CONSTRAINT ckfk_alerta_tipo FOREIGN KEY (fk_tipo_alerta) REFERENCES tipo_alerta(id_tipo_alerta)
);


-- =========================================================
-- 4. POVOAMENTO INICIAL
-- =========================================================

INSERT INTO plano (nome_plano, tanques_min, tanques_max, valor_setup_tanque, valor_mensal_tanque) VALUES
('Craft', 1, 9, 1200.00, 290.00),
('Regional', 10, 49, 900.00, 240.00),
('Industrial', 50, NULL, 600.00, 190.00);

INSERT INTO cargo (nome_cargo) VALUES ('Administrador'), ('Mestre Cervejeiro'), ('Operador'), ('Qualidade');
INSERT INTO tipo_cerveja (nome_tipo) VALUES ('Ale'), ('Lager');
INSERT INTO levedura (nome_levedura) VALUES ('Saccharomyces cerevisiae'), ('Saccharomyces pastorianus'), ('Saccharomyces carlsbergensis');
INSERT INTO status_tanque (nome_status) VALUES ('Disponível'), ('Em uso'), ('Em limpeza'), ('Manutenção'), ('Indisponível');
INSERT INTO status_lote (nome_status) VALUES ('Em andamento'), ('Finalizado'), ('Cancelado');
INSERT INTO tipo_alerta (nome_tipo) VALUES ('Temperatura acima do ideal'), ('Temperatura abaixo da ideal'), ('Tendência de desvio');
INSERT INTO status_contato (nome_status) VALUES ('Novo'), ('Em negociação'), ('Contrato fechado'), ('Perdido');
INSERT INTO status_empresa (nome_status) VALUES ('Ativa'), ('Suspensa'), ('Cancelada');
INSERT INTO status_codigo (nome_status) VALUES ('Ativo'), ('Expirado'), ('Revogado');
INSERT INTO status_usuario (nome_status) VALUES ('Ativo'), ('Inativo'), ('Bloqueado');
INSERT INTO status_sensor (nome_status) VALUES ('Ativo'), ('Inativo'), ('Manutenção');
INSERT INTO faixa_tanques (nome_faixa) VALUES ('1 a 4'), ('5 a 14'), ('15 ou mais');

-- ETAPA 1: empresa entra em contato pelo site (faixa 2 = "5 a 14")
INSERT INTO contato (fk_faixa_tanques, nome_completo, email_corporativo, nome_empresa, mensagem, aceite_contato) VALUES
(2, 'Carlos Silva', 'carlos.silva@ambev.com.br', 'Cervejaria Ambev - Unidade SP',
 'Conte um pouco sobre sua produção: gostaríamos de um diagnóstico térmico para os tanques fermentadores.', 1);

-- ETAPA 2: negociação e contrato fechado
UPDATE contato SET fk_status_contato = 3 WHERE id_contato = 1;

-- ETAPA 3: Zymos cadastra a empresa (fk_plano = 3 Industrial, fk_contato = 1)
INSERT INTO empresa (fk_plano, fk_contato, nome_empresa, cnpj, data_inicio_contrato) VALUES
(3, 1, 'Cervejaria Ambev - Unidade SP', '12344321000199', CURDATE());

-- ETAPA 4: Zymos cadastra a unidade (fábrica) dessa empresa
INSERT INTO unidade (fk_empresa, nome_unidade, logradouro, numero, bairro, cidade, uf, cep) VALUES
(1, 'Fábrica Matriz', 'Rodovia Anhanguera', '5000', 'Distrito Industrial', 'Ribeirão Preto', 'SP', '14096000');

-- ETAPA 5: Zymos gera o código de ativação (válido por 30 dias)
INSERT INTO codigo_ativacao (fk_empresa, codigo, data_expiracao) VALUES
(1, 'ZYM-AMB1-2026', DATE_ADD(NOW(), INTERVAL 30 DAY));

-- ETAPA 6: cliente valida o código e cadastra os usuários
INSERT INTO usuario (fk_empresa, fk_cargo, nome, email, senha) VALUES
(1, 1, 'Carlos Silva', 'carlos.silva@ambev.com.br', 'hash_senha_123'),
(1, 2, 'Juliana Mestre', 'juliana.qualidade@ambev.com.br', 'hash_senha_456');

-- Estilos de cerveja
INSERT INTO cerveja (fk_tipo_cerveja, fk_levedura, nome_estilo, temperatura_min, temperatura_max, temperatura_ideal, tempo_fermentacao_dias) VALUES
(1, 1, 'India Pale Ale (IPA)', 15.0, 24.0, 20.0, 14),
(2, 2, 'Pilsen', 8.0, 14.0, 10.0, 21);

-- Tanques (fk_unidade = 1, status 2 = Em uso)
INSERT INTO tanque (fk_unidade, fk_status_tanque, identificador_tanque, capacidade_litros) VALUES
(1, 2, 'Tanque TQ-01', 10000),
(1, 2, 'Tanque TQ-02', 10000),
(1, 1, 'Tanque TQ-03', 10000);

select * from leitura_sensor;
-- Sensores (1 por tanque)
INSERT INTO sensor (fk_tanque) VALUES (4), (5), (6);

-- Lotes: uma brassagem grande de IPA dividida em 2 tanques (mesmo codigo_producao),
-- e um lote avulso de Pilsen no TQ-03
INSERT INTO lote (codigo_lote, fk_tanque, fk_cerveja, fk_usuario_criador, fk_status_lote, data_inicio) VALUES
('LOTE-2026-101-A', 4, 1, 2, 1, '2026-09-20 08:00:00'),
('LOTE-2026-101-B', 5, 1, 2, 1, '2026-09-20 08:00:00'),
('LOTE-2026-095', 6, 2, 2, 1, '2026-09-25 09:00:00');

-- Leituras de exemplo (poucas linhas, só pra ilustrar os SELECTs abaixo;
-- na produção real chegariam a cada 2 segundos via Arduino/API)
INSERT INTO leitura_sensor (fk_sensor, fk_lote, temperatura, data_hora) VALUES
(1, 100, 19.8, '2026-09-20 09:00:00'),
(1, 100, 20.1, '2026-09-20 10:00:00'),
(1, 100, 25.2, '2026-09-20 11:00:00'),   -- desvio
(2, 101, 19.5, '2026-09-20 09:00:00'),
(2, 101, 19.9, '2026-09-20 10:00:00'),
(2, 101, 20.3, '2026-09-20 11:00:00'),
(3, 102, 10.2, '2026-09-25 10:00:00'),
(3, 102, 10.4, '2026-09-25 11:00:00');

-- Alerta gerado pela leitura fora da faixa (id_leitura 3 = 25.2°C no lote 100)
INSERT INTO alerta (fk_leitura, fk_tipo_alerta, descricao) VALUES
(3, 1, 'Leitura de 25.2°C ultrapassou a máxima de 24.0°C definida para o estilo IPA.');


-- =========================================================
-- 5. CONSULTAS DE TESTE (uma por etapa/funcionalidade discutida)
-- =========================================================

-- 5.1 Funil comercial
SELECT c.id_contato, c.nome_completo, c.nome_empresa, f.nome_faixa AS 'Tanques',
       s.nome_status AS 'Situação', c.data_contato
FROM contato c
JOIN status_contato s ON c.fk_status_contato = s.id_status_contato
JOIN faixa_tanques f ON c.fk_faixa_tanques = f.id_faixa_tanques
ORDER BY c.data_contato DESC;

-- 5.2 Validação do código de ativação na tela /cadastro
SELECT ca.fk_empresa, e.nome_empresa
FROM codigo_ativacao ca
JOIN status_codigo sc ON ca.fk_status_codigo = sc.id_status_codigo
JOIN empresa e ON ca.fk_empresa = e.id_empresa
WHERE ca.codigo = 'ZYM-AMB1-2026'
  AND sc.nome_status = 'Ativo'
  AND (ca.data_expiracao IS NULL OR ca.data_expiracao > NOW());

-- 5.3 Login: usuário com empresa, cargo e plano
SELECT u.id_usuario, u.nome AS 'Usuário', u.email AS 'E-mail de Login',
       c.nome_cargo AS 'Cargo', e.nome_empresa AS 'Empresa', p.nome_plano AS 'Plano'
FROM usuario u
JOIN empresa e ON u.fk_empresa = e.id_empresa
JOIN plano p ON e.fk_plano = p.id_plano
JOIN cargo c ON u.fk_cargo = c.id_cargo
WHERE u.email = 'carlos.silva@ambev.com.br';

-- 5.4 Filtro em cascata do dashboard: Unidade -> Tanque -> Lote -> Leituras
SELECT ls.temperatura, ls.data_hora
FROM leitura_sensor ls
JOIN lote l ON ls.fk_lote = l.id_lote
JOIN tanque t ON l.fk_tanque = t.id_tanque
JOIN unidade un ON t.fk_unidade = un.id_unidade
WHERE un.id_unidade = 1
  AND t.id_tanque = 1
  AND l.id_lote = 100
ORDER BY ls.data_hora;

-- 5.5 Tempo real: últimos 15 minutos de leitura (dado bruto, a cada 2s)
SELECT temperatura, data_hora
FROM leitura_sensor
WHERE fk_lote = 100
  AND data_hora >= NOW() - INTERVAL 15 MINUTE
ORDER BY data_hora;

-- 5.6 Período maior: agregado em baldes de 5 minutos (evita plotar milhões de pontos)
SELECT
    FROM_UNIXTIME(FLOOR(UNIX_TIMESTAMP(data_hora) / 300) * 300) AS intervalo_5min,
    AVG(temperatura) AS temp_media,
    MIN(temperatura) AS temp_min,
    MAX(temperatura) AS temp_max
FROM leitura_sensor
WHERE fk_lote = 100
GROUP BY intervalo_5min
ORDER BY intervalo_5min;

-- 5.7 Comparativo entre lotes agrupados pela mesma brassagem (codigo_producao),
-- alinhado por tempo relativo (hora 0, 1, 2... desde o início de cada lote)
SELECT
    FLOOR(TIMESTAMPDIFF(MINUTE, l.data_inicio, ls.data_hora) / 60) AS hora_relativa,
    AVG(ls.temperatura) AS temp_media_grupo,
    MIN(ls.temperatura) AS temp_min_grupo,
    MAX(ls.temperatura) AS temp_max_grupo
FROM leitura_sensor ls
JOIN lote l ON ls.fk_lote = l.id_lote
WHERE l.codigo_producao = 'PROD-2026-101'
GROUP BY hora_relativa
ORDER BY hora_relativa;

-- 5.8 Alertas em aberto da empresa
SELECT a.id_alerta, ta.nome_tipo AS 'Tipo', a.descricao, a.data_alerta, t.identificador_tanque
FROM alerta a
JOIN tipo_alerta ta ON a.fk_tipo_alerta = ta.id_tipo_alerta
JOIN leitura_sensor ls ON a.fk_leitura = ls.id_leitura
JOIN lote l ON ls.fk_lote = l.id_lote
JOIN tanque t ON l.fk_tanque = t.id_tanque
JOIN unidade un ON t.fk_unidade = un.id_unidade
WHERE un.fk_empresa = 1
  AND a.data_resolucao IS NULL
ORDER BY a.data_alerta DESC;
