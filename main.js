// importa os bibliotecas necessários
const serialport = require("serialport");
const express = require("express");
const mysql = require("mysql2");

// constantes para configurações
const SERIAL_BAUD_RATE = 9600;
const SERVIDOR_PORTA = 3300;

// habilita ou desabilita a inserção de dados no banco de dados
const HABILITAR_OPERACAO_INSERIR = true;
const HABILITAR_DADOS_SIMULADOS = true;

// função para comunicação serial
const serial = async (valorestemperaturaAnalog) => {
  // conexão com o banco de dados MySQL
  const poolBancoDados = mysql
    .createPool({
      host: "localhost",
      user: "user_zymos",
      password: "zymos123!",
      database: "zymos",
      port: 3306,
    })
    .promise();

  // Ids dos lotes
  const idLote01 = 106;
  const idLote02 = 107;
  const idLote03 = 108;

  // ids dos sensores
  const sensor01 = 4;
  const sensor02 = 5;
  const sensor03 = 6;

  // temperaturas dos lotes
  let tempLote01 = 0;
  let tempLote02 = 0;
  let tempLote03 = 0;

  const dadosSimulados = async (data) => {
    tempLote01 = parseFloat(data) + 3;
    tempLote02 = parseFloat(data) - 5;
    tempLote03 = parseFloat(data) + 6;

    console.log(`\n\nLOTE | TEMPERATURA`);
    console.log(`LOTE01 | ${tempLote01.toFixed(2)}`);
    console.log(`LOTE02 | ${tempLote02.toFixed(2)}`);
    console.log(`LOTE03 | ${tempLote03.toFixed(2)}`);

    if (HABILITAR_OPERACAO_INSERIR) {
      // Envia os dados para o banco de dados
      console.log(`temp antes de chamar a func ${tempLote01}`);
      await enviarDadosBd(sensor01, idLote01, tempLote01.toFixed(2));
      await enviarDadosBd(sensor02, idLote02, tempLote02.toFixed(2));
      await enviarDadosBd(sensor03, idLote03, tempLote03.toFixed(2));
    }
  };

  if (HABILITAR_DADOS_SIMULADOS) {
    console.log(
      "*** MODO SIMULADO: os dados são falsos, o Arduino NÃO está sendo lido ***"
    );

    setInterval(() => {
      const analogico = (18 + Math.random() * 4).toFixed(2); // 18.00 a 21.99
      dadosSimulados(`${analogico}`);
    }, 1000);

    return;
  } else {
    // lista as portas seriais disponíveis e procura pelo Arduino
    const portas = await serialport.SerialPort.list();
    const portaArduino = portas.find(
      (porta) => porta.vendorId == 2341 && porta.productId == 43
    );
    if (!portaArduino) {
      throw new Error("O arduino não foi encontrado em nenhuma porta serial");
    }

    // configura a porta serial com o baud rate especificado
    const arduino = new serialport.SerialPort({
      path: portaArduino.path,
      baudRate: SERIAL_BAUD_RATE,
    });

    // evento quando a porta serial é aberta
    arduino.on("open", () => {
      console.log(
        `A leitura do arduino foi iniciada na porta ${portaArduino.path} utilizando Baud Rate de ${SERIAL_BAUD_RATE}`
      );
    });

    // processa os dados recebidos do Arduino
    arduino
      .pipe(new serialport.ReadlineParser({ delimiter: "\r\n" }))
      .on("data", async (data) => {
        console.log(data);
        const temperaturaAnalog = parseFloat(data[0]);

        // armazena os valores dos sensores nos arrays correspondentes
        valorestemperaturaAnalog.push(temperaturaAnalog);
        // valoresSensorDigital.push(sensorDigital);

        // insere os dados no banco de dados (se habilitado)
        if (HABILITAR_OPERACAO_INSERIR) {
          // await enviarDadosBd()
        }
      });

    // evento para lidar com erros na comunicação serial
    arduino.on("error", (mensagem) => {
      console.error(`Erro no arduino (Mensagem: ${mensagem}`);
    });
  }

  async function enviarDadosBd(fk_sensor, fk_lote, temperatura) {
    console.log("Valores recebidos: ", temperatura, fk_sensor, fk_lote);
    // este insert irá inserir os dados na tabela "medida"
    const [response] = await poolBancoDados.execute(
      "INSERT INTO leitura_sensor (temperatura, fk_sensor, fk_lote) VALUES (?, ?, ?)",
      [temperatura, fk_sensor, fk_lote]
    );

    console.log("valores inseridos no banco: ", temperatura, fk_sensor, fk_lote);

    return response;
  }
};

// função para criar e configurar o servidor web
const servidor = (
  valorestemperaturaAnalog
  //valoresSensorDigital
) => {
  const app = express();

  // configurações de requisição e resposta
  app.use((request, response, next) => {
    response.header("Access-Control-Allow-Origin", "*");
    response.header(
      "Access-Control-Allow-Headers",
      "Origin, Content-Type, Accept"
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
  await serial(
    valorestemperaturaAnalog
  );

  // inicia o servidor web
  servidor(
    valorestemperaturaAnalog
  );
})();