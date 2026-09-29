CREATE DATABASE zymosTeste;

USE zymosTeste;

CREATE TABLE dadosTemp (
id INT PRIMARY KEY AUTO_INCREMENT,
temperatura DECIMAL(5,2),
dt_medida DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE USER 'sensor'@'%' IDENTIFIED BY 'SPTECH@123senha';

GRANT INSERT ON zymosTeste.dadosTemp TO 'sensor'@'%';
GRANT SELECT ON zymosTeste.dadosTemp TO 'sensor'@'%';

FLUSH PRIVILEGES;

SHOW GRANTS FOR 'sensor'@'%';

SELECT *FROM dadosTemp;