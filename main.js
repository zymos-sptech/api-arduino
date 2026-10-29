// importa os bibliotecas necessários
const serialport = require("serialport");
const express = require("express");
const mysql = require("mysql2");

// constantes para configurações
const SERIAL_BAUD_RATE = 9600;
const SERVIDOR_PORTA = 3300;

// habilita ou desabilita a inserção de dados no banco de dados
const HABILITAR_OPERACAO_INSERIR = false;

// função para comunicação serial
const serial = async (valorestemperaturaAnalog) => {
  // conexão com o banco de dados MySQL
  const poolBancoDados = mysql
    .createPool({
      host: "localhost",
      user: "user_insert_zymos",
      password: "Zymos123!",
      database: "zymos",
      port: 3307,
    })
    .promise();

  // Ids dos lotes
  const idLote01 = 100;

  // id do sensore
  const sensor01 = 1;

  // temperatura do lote
  let tempLote01 = 0;

  // lista as portas seriais disponíveis e procura pelo Arduino
  const portas = await serialport.SerialPort.list();
  const portaArduino = portas.find(
    (porta) =>
      (porta.vendorId == 2341 && porta.productId == 43) ||
      (porta.manufacturer &&
        porta.manufacturer.toLowerCase().includes("arduino")),
  );

  if (!portaArduino) {
    const portasDetectadas = portas.map((p) => p.path).join(", ");
    throw new Error(
      `O Arduino não foi encontrado em nenhuma porta serial. Portas detectadas: ${portasDetectadas || "nenhuma"}`,
    );
  }

  // configura a porta serial com o baud rate especificado
  const arduino = new serialport.SerialPort({
    path: portaArduino.path,
    baudRate: SERIAL_BAUD_RATE,
  });

  // evento quando a porta serial é aberta
  arduino.on("open", () => {
    console.log(
      `A leitura do Arduino foi iniciada na porta ${portaArduino.path} utilizando Baud Rate de ${SERIAL_BAUD_RATE}`,
    );
  });

  // processa os dados recebidos do Arduino
  arduino
    .pipe(new serialport.ReadlineParser({ delimiter: "\r\n" }))
    .on("data", async (data) => {
      const dadosSensor = data.split(";");

      const tempConvertida = parseFloat(dadosSensor[1]);

      tempLote01 = tempConvertida;

      const getFaixaIdealLote01 = await getFaixaIdeal(idLote01);
      const tempMinLote01 = getFaixaIdealLote01[0]?.temperatura_min;
      const tempMaxLote01 = getFaixaIdealLote01[0]?.temperatura_max;

      // armazena os valores dos sensores nos arrays correspondentes
      valorestemperaturaAnalog.push({
        temperatura: tempLote01.toFixed(2),
        faixaIdealMin: tempMinLote01,
        faixaIdealMax: tempMaxLote01,
      });

      console.log(
        `\nLOTE01 | Temp: ${tempLote01.toFixed(2)}°C | Faixa Ideal: [${tempMinLote01}°C - ${tempMaxLote01}°C]`,
      );

      // insere os dados no banco de dados (se habilitado)
      if (HABILITAR_OPERACAO_INSERIR) {
        await enviarDadosBd(sensor01, idLote01, tempLote01.toFixed(2));
        console.log(`Dados inseridos no banco com sucesso.`);
      }
    });

  // evento para lidar com erros na comunicação serial
  arduino.on("error", (mensagem) => {
    console.error(`Erro no Arduino (Mensagem: ${mensagem})`);
  });
  async function enviarDadosBd(fk_sensor, temperatura) {
    // este insert irá inserir os dados na tabela "leitura_sensor"
    const [response] = await poolBancoDados.execute(
      "INSERT INTO leitura_sensor (temperatura, fk_sensor) VALUES (?, ?)",
      [temperatura, fk_sensor],
    );
    return response;
  }

  async function getFaixaIdeal(id_lote) {
    const [response] = await poolBancoDados.execute(
      "SELECT c.temperatura_min, c.temperatura_max FROM lote l JOIN cerveja c ON l.fk_cerveja = c.id_cerveja WHERE id_lote = ?",
      [id_lote],
    );
    return response;
  }
};

// função para criar e configurar o servidor web
const servidor = (valorestemperaturaAnalog) => {
  const app = express();

  // configurações de requisição e resposta
  app.use((request, response, next) => {
    response.header("Access-Control-Allow-Origin", "*");
    response.header(
      "Access-Control-Allow-Headers",
      "Origin, Content-Type, Accept",
    );
    next();
  });

  // inicia o servidor na porta especificada
  app.listen(SERVIDOR_PORTA, () => {
    console.log(`API executada com sucesso na porta ${SERVIDOR_PORTA}`);
  });

  // define os endpoints da API para cada tipo de sensor
  app.get("/sensores/temperatura", (_, response) => {
    return response.json(valorestemperaturaAnalog);
  });
};

// função principal assíncrona para iniciar a comunicação serial e o servidor web
(async () => {
  // arrays para armazenar os valores dos sensores
  const valorestemperaturaAnalog = [];

  // inicia a comunicação serial
  await serial(valorestemperaturaAnalog);

  // inicia o servidor web
  servidor(valorestemperaturaAnalog);
})();
