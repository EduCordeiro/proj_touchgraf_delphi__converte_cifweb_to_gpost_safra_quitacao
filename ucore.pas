unit ucore;

interface

uses
  Windows, Messages, Variants, Graphics, Controls, FileCtrl,
  Dialogs, StdCtrls,  Classes, SysUtils, Forms,
  DB, ZConnection, ZAbstractRODataset, ZAbstractDataset, ZDataset, ZSqlProcessor,
  ADODb, DBTables,
  udatatypes_apps,
  // Classes
  ClassParametrosDeEntrada,
  ClassArquivoIni, ClassStrings, ClassConexoes, ClassConf, ClassMySqlBases,
  ClassTextFile, ClassDirectory, ClassLog, ClassFuncoesWin, ClassLayoutArquivo,
  ClassBlocaInteligente, ClassFuncoesBancarias, ClassPlanoDeTriagem, ClassExpressaoRegular,
  ClassStatusProcessamento, ClassDateTime, ClassSMTPDelphi;

type

  TCore = class(TObject)
  private

    __queryMySQL_processamento__    : TZQuery;
    __queryMySQL_processamento2__   : TZQuery;
    __queryMySQL_processamento3__   : TZQuery;
    __queryMySQL_Insert_            : TZQuery;
    __queryMySQL_plano_de_triagem__ : TZQuery;

    // FUNÇÃO DE PROCESSAMENTO
      Procedure PROCESSAMENTO();
      Procedure PROCESSAMENTO_SP();

      procedure StoredProcedure_Dropar(Nome: string; logBD:boolean=false; idprograma:integer=0);

      function StoredProcedure_Criar(Nome : string; scriptSQL: TStringList): boolean;

      procedure StoredProcedure_Executar(Nome: string; ComParametro:boolean=false; logBD:boolean=false; idprograma:integer=0);

      function Compactar_Arquivo_7z(Arquivo, destino : String; mover_arquivo: Boolean=false; ZIP: Boolean=false): integer;
      function Extrair_Arquivo_7z(Arquivo, destino : String): integer;

      PROCEDURE COMPACTAR_ARQUIVO(ARQUIVO_ORIGEM, PATH_DESTINO: String; MOVER_ARQUIVO: Boolean=FALSE; ZIP: Boolean=false);
      PROCEDURE EXTRAIR_ARQUIVO(ARQUIVO_ORIGEM, PATH_DESTINO: String);

      procedure Atualiza_arquivo_conf_C(ArquivoConf, sINP, sOUT, sTMP, sLOG, sRGP: String);
      procedure execulta_app_c(app, arquivo_conf: string);

  public

    __ListaPlanoDeTriagem__       : TRecordPlanoTriagemCorreios;

    objParametrosDeEntrada   : TParametrosDeEntrada;
    objConexao               : TMysqlDatabase;
    objPlanoDeTriagem        : TPlanoDeTriagem;
    objString                : TFormataString;
    objLogar                 : TArquivoDelog;
    objDateTime              : TFormataDateTime;
    objArquivoIni            : TArquivoIni;
    objArquivoDeConexoes     : TArquivoDeConexoes;
    objArquivoDeConfiguracao : TArquivoConf;
    objDiretorio             : TDiretorio;
    objFuncoesWin            : TFuncoesWin;
    objLayoutArquivoCliente  : TLayoutCliente;
    objBlocagemInteligente   : TBlocaInteligente;
    objFuncoesBancarias      : TFuncoesBancarias;
    objExpressaoRegular      : TExpressaoRegular;
    objStatusProcessamento   : TStausProcessamento;
    objEmail                 : TSMTPDelphi;

    PROCEDURE COMPACTAR();
    PROCEDURE EXTRAIR();

    function GERA_LOTE_PEDIDO(): String;
    Procedure VALIDA_LOTE_PEDIDO();
    Procedure AtualizaDadosTabelaLOG();

    function PesquisarLote(LOTE_PEDIDO : STRING; status : Integer): Boolean;

    procedure ExcluirBase(NomeTabela: String);
    procedure ExcluirTabela(NomeTabela: String);
    function EnviarEmail(Assunto: string=''; Corpo: string=''): Boolean;
    procedure MainLoop();
    constructor create();

    procedure ReverterArquivos();

    procedure getListaDeArquivosJaProcessados();

    function ArquivoExieteTabelaTrack(Arquivo: string): Boolean;
    procedure CriaMovimento();

  end;

implementation

uses uMain, Math;

constructor TCore.create();
var
  sMSG                       : string;
  sArquivosScriptSQL         : string;
  stlScripSQL                : TStringList;
begin

  try

    stlScripSQL                                              := TStringList.Create();

    objStatusProcessamento                                   := TStausProcessamento.create();
    objParametrosDeEntrada                                   := TParametrosDeEntrada.Create();

    objParametrosDeEntrada.STL_LISTA_ARQUIVOS_JA_PROCESSADOS := TStringList.Create();
    objParametrosDeEntrada.STL_LISTA_ARQUIVOS_REVERTER       := TStringList.Create();

    objLogar                                                 := TArquivoDelog.Create();
    if FileExists(objLogar.getArquivoDeLog()) then
      objFuncoesWin.DelFile(objLogar.getArquivoDeLog());

    objFuncoesWin                        := TFuncoesWin.create(objLogar);
    objString                            := TFormataString.Create(objLogar);
    objDateTime                          := TFormataDateTime.Create(objLogar);
    objLayoutArquivoCliente              := TLayoutCliente.Create();
    objFuncoesBancarias                  := TFuncoesBancarias.Create();
    objExpressaoRegular                  := TExpressaoRegular.Create();

    objArquivoIni                        := TArquivoIni.create(objLogar,
                                                               objString,
                                                               ExtractFilePath(Application.ExeName),
                                                               ExtractFileName(Application.ExeName));

    objArquivoDeConexoes                 := TArquivoDeConexoes.create(objLogar,
                                                                      objString,
                                                                      objArquivoIni.getPathConexoes());

    objArquivoDeConfiguracao             := TArquivoConf.create(objArquivoIni.getPathConfiguracoes(),
                                                                ExtractFileName(Application.ExeName));

    objParametrosDeEntrada.ID_PROCESSAMENTO := objArquivoDeConfiguracao.getIDProcessamento;

    objConexao                           := TMysqlDatabase.Create();

    if objArquivoIni.getPathConfiguracoes() <> '' then
    begin

      objParametrosDeEntrada.PATHENTRADA                                := objArquivoDeConfiguracao.getConfiguracao('path_default_arquivos_entrada');
      objParametrosDeEntrada.PATHSAIDA                                  := objArquivoDeConfiguracao.getConfiguracao('path_default_arquivos_saida');
      objParametrosDeEntrada.TABELA_PROCESSAMENTO                       := objArquivoDeConfiguracao.getConfiguracao('tabela_processamento');
      objParametrosDeEntrada.TABELA_LOTES_PEDIDOS                       := objArquivoDeConfiguracao.getConfiguracao('TABELA_LOTES_PEDIDOS');
      objParametrosDeEntrada.TABELA_PLANO_DE_TRIAGEM                    := objArquivoDeConfiguracao.getConfiguracao('tabela_plano_de_triagem');
      objParametrosDeEntrada.CARREGAR_PLANO_DE_TRIAGEM_MEMORIA          := objArquivoDeConfiguracao.getConfiguracao('CARREGAR_PLANO_DE_TRIAGEM_MEMORIA');
      objParametrosDeEntrada.TABELA_BLOCAGEM_INTELIGENTE                := objArquivoDeConfiguracao.getConfiguracao('TABELA_BLOCAGEM_INTELIGENTE');
      objParametrosDeEntrada.TABELA_BLOCAGEM_INTELIGENTE_RELATORIO      := objArquivoDeConfiguracao.getConfiguracao('TABELA_BLOCAGEM_INTELIGENTE_RELATORIO');
      objParametrosDeEntrada.TABELA_ENTRADA_SP                          := objArquivoDeConfiguracao.getConfiguracao('TABELA_ENTRADA_SP');
      objParametrosDeEntrada.TABELA_AUX_SP                              := objArquivoDeConfiguracao.getConfiguracao('TABELA_AUX_SP');
      objParametrosDeEntrada.TABELA_CICLO_POSTAGEM_FAC                  := objArquivoDeConfiguracao.getConfiguracao('TABELA_CICLO_POSTAGEM_FAC');
      objParametrosDeEntrada.LIMITE_DE_SELECT_POR_INTERACOES_NA_MEMORIA := objArquivoDeConfiguracao.getConfiguracao('numero_de_select_por_interacoes_na_memoria');
      objParametrosDeEntrada.NUMERO_DE_IMAGENS_PARA_BLOCAGENS           := objArquivoDeConfiguracao.getConfiguracao('NUMERO_DE_IMAGENS_PARA_BLOCAGENS');
      objParametrosDeEntrada.BLOCAR_ARQUIVO                             := objArquivoDeConfiguracao.getConfiguracao('BLOCAR_ARQUIVO');
      objParametrosDeEntrada.BLOCAGEM                                   := objArquivoDeConfiguracao.getConfiguracao('BLOCAGEM');
      objParametrosDeEntrada.MANTER_ARQUIVO_ORIGINAL                    := objArquivoDeConfiguracao.getConfiguracao('MANTER_ARQUIVO_ORIGINAL');
      objParametrosDeEntrada.FORMATACAO_LOTE_PEDIDO                     := objArquivoDeConfiguracao.getConfiguracao('FORMATACAO_LOTE_PEDIDO');
      objParametrosDeEntrada.lista_de_caracteres_invalidos              := objArquivoDeConfiguracao.getConfiguracao('lista_de_caracteres_invalidos');
      objParametrosDeEntrada.SP_001                                     := objArquivoDeConfiguracao.getConfiguracao('SP_001');
      objParametrosDeEntrada.SP_002                                     := objArquivoDeConfiguracao.getConfiguracao('SP_002');
      objParametrosDeEntrada.SP_003                                     := objArquivoDeConfiguracao.getConfiguracao('SP_003');
      objParametrosDeEntrada.SP_001_NAME                                := objArquivoDeConfiguracao.getConfiguracao('SP_001_NAME');
      objParametrosDeEntrada.SP_002_NAME                                := objArquivoDeConfiguracao.getConfiguracao('SP_002_NAME');
      objParametrosDeEntrada.SP_003_NAME                                := objArquivoDeConfiguracao.getConfiguracao('SP_003_NAME');
      objParametrosDeEntrada.eHost                                      := objArquivoDeConfiguracao.getConfiguracao('eHost');
      objParametrosDeEntrada.eUser                                      := objArquivoDeConfiguracao.getConfiguracao('eUser');
      objParametrosDeEntrada.eFrom                                      := objArquivoDeConfiguracao.getConfiguracao('eFrom');
      objParametrosDeEntrada.eTo                                        := objArquivoDeConfiguracao.getConfiguracao('eTo');

      objParametrosDeEntrada.EXTENCAO_ARQUIVOS                          := objArquivoDeConfiguracao.getConfiguracao('EXTENCAO_ARQUIVOS');
      
      objParametrosDeEntrada.COPIAR_LOG_PARA_SAIDA                      := StrTobool(objArquivoDeConfiguracao.getConfiguracao('COPIAR_LOG_PARA_SAIDA'));

      objParametrosDeEntrada.CRIAR_CSV_TRACK                            := StrTobool(objArquivoDeConfiguracao.getConfiguracao('CRIAR_CSV_TRACK'));
      objParametrosDeEntrada.PATH_TRACK                                 := objArquivoDeConfiguracao.getConfiguracao('PATH_TRACK');

      objParametrosDeEntrada.TABELA_TRACK                               := objArquivoDeConfiguracao.getConfiguracao('TABELA_TRACK');
      objParametrosDeEntrada.TABELA_TRACK_LINE                          := objArquivoDeConfiguracao.getConfiguracao('TABELA_TRACK_LINE');
      objParametrosDeEntrada.TABELA_TRACK_LINE_HISTORY                  := objArquivoDeConfiguracao.getConfiguracao('TABELA_TRACK_LINE_HISTORY');

      objParametrosDeEntrada.APP_C_GERA_IDX_EXE                         := objArquivoDeConfiguracao.getConfiguracao('APP_C_GERA_IDX_EXE');
      objParametrosDeEntrada.APP_C_GERA_IDX_CFG                         := objArquivoDeConfiguracao.getConfiguracao('APP_C_GERA_IDX_CFG');

      objParametrosDeEntrada.app_7z_32bits                              := objArquivoDeConfiguracao.getConfiguracao('app_7z_32bits');
      objParametrosDeEntrada.app_7z_64bits                              := objArquivoDeConfiguracao.getConfiguracao('app_7z_64bits');
      objParametrosDeEntrada.ARQUITETURA_WINDOWS                        := objArquivoDeConfiguracao.getConfiguracao('ARQUITETURA_WINDOWS');

      objParametrosDeEntrada.LOGAR                                      := objArquivoDeConfiguracao.getConfiguracao('LOGAR');

      objParametrosDeEntrada.NUMERO_CONTRATO                            := objArquivoDeConfiguracao.getConfiguracao('NUMERO_CONTRATO');
      objParametrosDeEntrada.CODIGO_UNIDADE_POSTAGEM                    := objArquivoDeConfiguracao.getConfiguracao('CODIGO_UNIDADE_POSTAGEM');
      objParametrosDeEntrada.CEP_UNIDADE_POSTAGEM                       := objArquivoDeConfiguracao.getConfiguracao('CEP_UNIDADE_POSTAGEM');
      objParametrosDeEntrada.CODIGO_AVALIACAO_TECNICA                   := objArquivoDeConfiguracao.getConfiguracao('CODIGO_AVALIACAO_TECNICA');
      objParametrosDeEntrada.DNE_ATUALIZADO                             := objArquivoDeConfiguracao.getConfiguracao('DNE_ATUALIZADO');
      objParametrosDeEntrada.NUMERO_CARTAO                              := objArquivoDeConfiguracao.getConfiguracao('NUMERO_CARTAO');
      objParametrosDeEntrada.CODIGO_MUTIPLO                             := objArquivoDeConfiguracao.getConfiguracao('CODIGO_MUTIPLO');
      objParametrosDeEntrada.CODIGO_CONTEUDO                            := objArquivoDeConfiguracao.getConfiguracao('CODIGO_CONTEUDO');
      objParametrosDeEntrada.CODIGO_SERVICO_ADICIONAL                   := objArquivoDeConfiguracao.getConfiguracao('CODIGO_SERVICO_ADICIONAL');
      objParametrosDeEntrada.VALOR_DECLARADO                            := objArquivoDeConfiguracao.getConfiguracao('VALOR_DECLARADO');
      objParametrosDeEntrada.PESO                                       := objArquivoDeConfiguracao.getConfiguracao('PESO');
      objParametrosDeEntrada.FAC_SIMPLES_LOCAL                          := objArquivoDeConfiguracao.getConfiguracao('FAC_SIMPLES_LOCAL');
      objParametrosDeEntrada.FAC_SIMPLES_ESTADUAL                       := objArquivoDeConfiguracao.getConfiguracao('FAC_SIMPLES_ESTADUAL');
      objParametrosDeEntrada.FAC_SIMPLES_NACIONAL                       := objArquivoDeConfiguracao.getConfiguracao('FAC_SIMPLES_NACIONAL');
      objParametrosDeEntrada.dias_para_postagem_apos_processamento      := objArquivoDeConfiguracao.getConfiguracao('dias_para_postagem_apos_processamento');

      objParametrosDeEntrada.COMPACTAR_MIDIA                            := objArquivoDeConfiguracao.getConfiguracao('COMPACTAR_MIDIA');
      objParametrosDeEntrada.USAR_PATH_PERSONALIZADO_CIF                := objArquivoDeConfiguracao.getConfiguracao('USAR_PATH_PERSONALIZADO_CIF');
      objParametrosDeEntrada.PATH_DEFAULT_ARQUIVOS_SAIDA_CIF            := objArquivoDeConfiguracao.getConfiguracao('PATH_DEFAULT_ARQUIVOS_SAIDA_CIF');      


      //================
      //  LOGA USUÁRIO
      //========================================================================================================================================================
      objParametrosDeEntrada.APP_LOGAR                                  := objArquivoDeConfiguracao.getConfiguracao('APP_LOGAR');
      objParametrosDeEntrada.TABELA_LOTES_PEDIDOS_LOGIN                 := objArquivoDeConfiguracao.getConfiguracao('TABELA_LOTES_PEDIDOS_LOGIN');
      //========================================================================================================================================================

      objParametrosDeEntrada.ENVIAR_EMAIL                               := objArquivoDeConfiguracao.getConfiguracao('ENVIAR_EMAIL');



      objLogar.Logar('[DEBUG] TfrmMain.FormCreate() - Versão do programa: ' + objFuncoesWin.GetVersaoDaAplicacao());

      objParametrosDeEntrada.PathArquivo_TMP := objArquivoIni.getPathArquivosTemporarios();

      // Criando a Conexao
      objConexao.ConectarAoBanco(objArquivoDeConexoes.getHostName,
                                 'mysql',
                                 objArquivoDeConexoes.getUser,
                                 objArquivoDeConexoes.getPassword,
                                 objArquivoDeConexoes.getProtocolo
                                 );

      sArquivosScriptSQL := ExtractFileName(Application.ExeName);
      sArquivosScriptSQL := StringReplace(sArquivosScriptSQL, '.exe', '.sql', [rfReplaceAll, rfIgnoreCase]);

      stlScripSQL.LoadFromFile(objArquivoIni.getPathScripSQL() + sArquivosScriptSQL);
      objConexao.ExecutaScript(stlScripSQL);

      objBlocagemInteligente   := TBlocaInteligente.create(objParametrosDeEntrada,
                                                           objConexao,
                                                           objFuncoesWin,
                                                           objString,
                                                           objLogar);

      // Criando Objeto de Plano de Triagem
      if StrToBool(objParametrosDeEntrada.CARREGAR_PLANO_DE_TRIAGEM_MEMORIA) then
        objPlanoDeTriagem := TPlanoDeTriagem.create(objConexao,
                                                    objLogar,
                                                    objString,
                                                    objParametrosDeEntrada.TABELA_PLANO_DE_TRIAGEM, fac);



      objParametrosDeEntrada.stlRelatorioQTDE           := TStringList.Create();

      // LISTA DE ARUQIVOS JA PROCESSADOS
      getListaDeArquivosJaProcessados();


      objParametrosDeEntrada.STL_LOG_TXT                := TStringList.Create(); 

      IF StrToBool(objParametrosDeEntrada.LOGAR) THEN
      BEGIN

          //================
          //  LOGA USUÁRIO
          //==========================================================================================================================================================
          objParametrosDeEntrada.APP_LOGAR_PARAMETRO_TAB_INDEX      := '2';
          objParametrosDeEntrada.APP_LOGAR_PARAMETRO_NOME_APLICACAO := StringReplace(ExtractFileName(Application.ExeName), '.EXE', '', [rfReplaceAll, rfIgnoreCase]);
          objParametrosDeEntrada.APP_LOGAR_PARAMETRO_ARQUIVO_LOGAR  := ExtractFilePath(Application.ExeName) +
                                                                       StringReplace(ExtractFileName(objParametrosDeEntrada.APP_LOGAR), '.EXE', '.TXT', [rfReplaceAll, rfIgnoreCase]);

          objParametrosDeEntrada.APP_LOGAR_PARAMETRO_ARQUIVO_LOGAR  := StringReplace(objParametrosDeEntrada.APP_LOGAR_PARAMETRO_ARQUIVO_LOGAR, '\', '/', [rfReplaceAll, rfIgnoreCase]);

          

          objParametrosDeEntrada.STL_ARQUIVO_USUARIO_LOGADO := TStringList.Create();
          objFuncoesWin.ExecutarPrograma(objParametrosDeEntrada.APP_LOGAR
                                 + ' ' + objParametrosDeEntrada.APP_LOGAR_PARAMETRO_TAB_INDEX
                                 + ' ' + objParametrosDeEntrada.APP_LOGAR_PARAMETRO_NOME_APLICACAO
                                 + ' ' + objParametrosDeEntrada.APP_LOGAR_PARAMETRO_ARQUIVO_LOGAR);

          objParametrosDeEntrada.STL_ARQUIVO_USUARIO_LOGADO.LoadFromFile(objParametrosDeEntrada.APP_LOGAR_PARAMETRO_ARQUIVO_LOGAR);

          //=====================
          //   CAMPOS DE LOGIN
          //=====================
          objParametrosDeEntrada.USUARIO_LOGADO_APP           := objString.getTermo(1, ';', objParametrosDeEntrada.STL_ARQUIVO_USUARIO_LOGADO.Strings[0]);
          objParametrosDeEntrada.APP_LOGAR_CHAVE_APP          := objString.getTermo(2, ';', objParametrosDeEntrada.STL_ARQUIVO_USUARIO_LOGADO.Strings[0]);
          objParametrosDeEntrada.APP_LOGAR_LOTE               := objString.getTermo(3, ';', objParametrosDeEntrada.STL_ARQUIVO_USUARIO_LOGADO.Strings[0]);
          objParametrosDeEntrada.APP_LOGAR_USUARIO_LOGADO_WIN := objString.getTermo(4, ';', objParametrosDeEntrada.STL_ARQUIVO_USUARIO_LOGADO.Strings[0]);
          objParametrosDeEntrada.APP_LOGAR_IP                 := objString.getTermo(5, ';', objParametrosDeEntrada.STL_ARQUIVO_USUARIO_LOGADO.Strings[0]);
          objParametrosDeEntrada.APP_LOGAR_ID                 := objString.getTermo(6, ';', objParametrosDeEntrada.STL_ARQUIVO_USUARIO_LOGADO.Strings[0]);

          IF (Trim(objParametrosDeEntrada.USUARIO_LOGADO_APP) ='')
          or (Trim(objParametrosDeEntrada.APP_LOGAR_CHAVE_APP) ='')
          or (Trim(objParametrosDeEntrada.APP_LOGAR_LOTE) ='')
          or (Trim(objParametrosDeEntrada.APP_LOGAR_USUARIO_LOGADO_WIN) ='')
          or (Trim(objParametrosDeEntrada.APP_LOGAR_IP) ='')
          or (Trim(objParametrosDeEntrada.APP_LOGAR_ID) ='')
          THEN
            objParametrosDeEntrada.USUARIO_LOGADO_APP := '-1';
      END;

      //=========================
      //    DADOS DE REDE APP
      //=========================
      objParametrosDeEntrada.HOSTNAME                     := objFuncoesWin.getNetHostName;
      objParametrosDeEntrada.IP                           := objFuncoesWin.GetIP;
      objParametrosDeEntrada.USUARIO_SO                   := objFuncoesWin.GetUsuarioLogado;

      //========================
      //  GERA LOTE PEDIDO
      //========================
      if NOT StrToBool(objParametrosDeEntrada.LOGAR) then
      BEGIN

        objParametrosDeEntrada.PEDIDO_LOTE                  := GERA_LOTE_PEDIDO();

        objParametrosDeEntrada.USUARIO_LOGADO_APP           := objParametrosDeEntrada.USUARIO_SO;
        objParametrosDeEntrada.APP_LOGAR_CHAVE_APP          := objParametrosDeEntrada.ID_PROCESSAMENTO;
        objParametrosDeEntrada.APP_LOGAR_LOTE               := objParametrosDeEntrada.PEDIDO_LOTE;
        objParametrosDeEntrada.APP_LOGAR_USUARIO_LOGADO_WIN := objParametrosDeEntrada.USUARIO_SO;
        objParametrosDeEntrada.APP_LOGAR_IP                 := objParametrosDeEntrada.IP;
        objParametrosDeEntrada.APP_LOGAR_ID                 := objParametrosDeEntrada.ID_PROCESSAMENTO;

      END
      ELSE
      IF objParametrosDeEntrada.USUARIO_LOGADO_APP <> '-1' THEN
        objParametrosDeEntrada.PEDIDO_LOTE                := GERA_LOTE_PEDIDO();
      //==========================================================================================================================================================

    end;

  except
    on E:Exception do
    begin

      sMSG := '[ERRO] Não foi possível inicializar as configurações aq do programa. '+#13#10#13#10
            + ' EXCEÇÃO: '+E.Message+#13#10#13#10
            + ' O programa será encerrado agora.';

      showmessage(sMSG);

      objLogar.Logar(sMSG);

      Application.Terminate;
    end;
  end;

end;

function TCore.GERA_LOTE_PEDIDO(): String;
var
  sComando : string;
  sData    : string;
begin

  //==================
  //  CRIA NOVO LOTE
  //==================
  sData := FormatDateTime('YYYY-MM-DD hh:mm:ss', Now());

  sComando := ' insert into ' + objParametrosDeEntrada.TABELA_LOTES_PEDIDOS + '(VALIDO, DATA_CRIACAO, CHAVE, USUARIO_WIN, USUARIO_APP, IP, ID, LOTE_LOGIN, HOSTNAME)'
            + ' Value('
                      + '"'   + 'N'
                      + '","' + sData
                      + '","' + objParametrosDeEntrada.APP_LOGAR_CHAVE_APP
                      + '","' + objParametrosDeEntrada.APP_LOGAR_USUARIO_LOGADO_WIN
                      + '","' + objParametrosDeEntrada.USUARIO_LOGADO_APP
                      + '","' + objParametrosDeEntrada.APP_LOGAR_IP
                      + '","' + objParametrosDeEntrada.ID_PROCESSAMENTO
                      + '","' + objParametrosDeEntrada.APP_LOGAR_LOTE
                      + '","' + objParametrosDeEntrada.HOSTNAME
                      + '")';
  objConexao.Executar_SQL(__queryMySQL_processamento__, sComando, 1);

  //========================
  //  RETORNA LOTE CRIADO
  //========================
  sComando := ' SELECT LOTE_PEDIDO FROM  ' + objParametrosDeEntrada.TABELA_LOTES_PEDIDOS
            + ' WHERE '
                      + '     VALIDO        = "' + 'N'                                                 + '"'
                      + ' AND DATA_CRIACAO  = "' + sData                                               + '"'
                      + ' AND CHAVE         = "' + objParametrosDeEntrada.APP_LOGAR_CHAVE_APP          + '"'
                      + ' AND USUARIO_WIN   = "' + objParametrosDeEntrada.APP_LOGAR_USUARIO_LOGADO_WIN + '"'
                      + ' AND USUARIO_APP   = "' + objParametrosDeEntrada.USUARIO_LOGADO_APP           + '"'
                      + ' AND HOSTNAME      = "' + objParametrosDeEntrada.HOSTNAME                     + '"'
                      + ' AND LOTE_LOGIN    = "' + objParametrosDeEntrada.APP_LOGAR_LOTE               + '"'
                      + ' AND IP            = "' + objParametrosDeEntrada.APP_LOGAR_IP                 + '"'
                      + ' AND ID            = "' + objParametrosDeEntrada.ID_PROCESSAMENTO             + '"';
  objConexao.Executar_SQL(__queryMySQL_processamento__, sComando, 2);

  Result := FormatFloat(objParametrosDeEntrada.FORMATACAO_LOTE_PEDIDO, __queryMySQL_processamento__.FieldByName('LOTE_PEDIDO').AsInteger);

end;

PROCEDURE TCore.VALIDA_LOTE_PEDIDO();
VAR
  sComando                : string;
BEGIN

  //========================
  //  RETORNA LOTE CRIADO
  //========================
  sComando := ' UPDATE  ' + objParametrosDeEntrada.TABELA_LOTES_PEDIDOS
            + ' set VALIDO         = "' + objParametrosDeEntrada.STATUS_PROCESSAMENTO  + '"'
            + '    ,RELATORIO_QTD  = "' + objParametrosDeEntrada.stlRelatorioQTDE.Text + '"'
            + '    ,LOTE_LOGIN     = "' + objParametrosDeEntrada.APP_LOGAR_LOTE    + '"'
            + ' WHERE '
            + '     LOTE_PEDIDO   = "' + objParametrosDeEntrada.PEDIDO_LOTE                   + '"'
            + ' AND VALIDO        = "' + 'N'                                                  + '"'
            + ' AND CHAVE         = "' + objParametrosDeEntrada.APP_LOGAR_CHAVE_APP           + '"'
            + ' AND USUARIO_WIN   = "' + objParametrosDeEntrada.APP_LOGAR_USUARIO_LOGADO_WIN  + '"'
            + ' AND HOSTNAME      = "' + objParametrosDeEntrada.HOSTNAME                      + '"'
            + ' AND IP            = "' + objParametrosDeEntrada.APP_LOGAR_IP                  + '"'
            + ' AND ID            = "' + objParametrosDeEntrada.ID_PROCESSAMENTO              + '"';
  objConexao.Executar_SQL(__queryMySQL_processamento__, sComando, 1);

end;

Procedure TCore.AtualizaDadosTabelaLOG();
var
  sComando                  : String;
Begin
  //=========================================================================
  //  GRAVA LOG NA TABELA DE LOGIN - SOMENTE SE O PARÂMETRO LOGAR FOR TRUE
  //=========================================================================
  if StrToBool(objParametrosDeEntrada.LOGAR) then
  begin
    objParametrosDeEntrada.STL_LOG_TXT.Text := StringReplace(objParametrosDeEntrada.STL_LOG_TXT.Text, '\', '\\', [rfReplaceAll, rfIgnoreCase]);

    sComando := ' update ' + objParametrosDeEntrada.TABELA_LOTES_PEDIDOS_LOGIN
              + ' SET '
              + '      LOG_APP          = "' + objParametrosDeEntrada.STL_LOG_TXT.Text                           + '"'
              + '     ,VALIDO           = "' + objParametrosDeEntrada.STATUS_PROCESSAMENTO                       + '"'
              + '     ,QTD_PROCESSADA   = "' + IntToStr(objParametrosDeEntrada.TOTAL_PROCESSADOS_LOG)            + '"'
              + '     ,QTD_INVALIDOS    = "' + IntToStr(objParametrosDeEntrada.TOTAL_PROCESSADOS_INVALIDOS_LOG)  + '"'
              + '     ,LOTE_APP         = "' + objParametrosDeEntrada.PEDIDO_LOTE                                + '"'
              + '     ,RELATORIO_QTD    = "' + objParametrosDeEntrada.stlRelatorioQTDE.Text                      + '"'
              + ' WHERE CHAVE       = "' + objParametrosDeEntrada.APP_LOGAR_CHAVE_APP          + '"'
              + '   AND LOTE_PEDIDO = "' + objParametrosDeEntrada.APP_LOGAR_LOTE               + '"'
              + '   AND USUARIO_WIN = "' + objParametrosDeEntrada.APP_LOGAR_USUARIO_LOGADO_WIN + '"'
              + '   AND USUARIO_APP = "' + objParametrosDeEntrada.USUARIO_LOGADO_APP           + '"'
              + '   AND HOSTNAME    = "' + objParametrosDeEntrada.HOSTNAME                     + '"'
              + '   AND IP          = "' + objParametrosDeEntrada.APP_LOGAR_IP                 + '"'
              + '   AND ID          = "' + objParametrosDeEntrada.APP_LOGAR_ID                 + '"';
    objConexao.Executar_SQL(__queryMySQL_processamento__, sComando, 1);
  end;

end;

procedure TCore.MainLoop();
var
  sMSG : string;
begin

  objLogar.Logar('[DEBUG] TCore.MainLoop() - begin...');
  try
    try

        objDiretorio := TDiretorio.create(objParametrosDeEntrada.PathEntrada);
        objParametrosDeEntrada.PathEntrada := objDiretorio.getDiretorio();

        objDiretorio.setDiretorio(objParametrosDeEntrada.PathSaida);
        objParametrosDeEntrada.PathSaida   := objDiretorio.getDiretorio();

//      PROCESSAMENTO();
//      PROCESSAMENTO_SP();

    finally

      if Assigned(objDiretorio) then
      begin
        objDiretorio.destroy;
        Pointer(objDiretorio) := nil;
      end;

    end;

  except

    // 0------------------------------------------0
    // |  Excessões desntro do objCore caem aqui  |
    // 0------------------------------------------0
    on E:Exception do
    begin

      sMSG :='Erro ao execultar a Função MainLoop(). ' + #13#10#13#10
                 +'EXCEÇÃO: '+E.Message+#13#10#13#10
                 +'O programa será encerrado agora.';

      IF StrToBool(objParametrosDeEntrada.ENVIAR_EMAIL) THEN
        EnviarEmail('ERRO DE PROCESSAMENTO !!!', sMSG + #13 + #13 + 'SEGUE LOG EM ANEXO.' + #13 + #13
        + 'DETALHES DE LOGIN' + #13
        + '=================' + #13
        + 'HOSTNAME.......................: ' + objParametrosDeEntrada.HOSTNAME + #13
        + 'USUARIO LOGADO.................: ' + objParametrosDeEntrada.USUARIO_LOGADO_APP + #13
        + 'USUARIO SO.....................: ' + objParametrosDeEntrada.USUARIO_SO + #13
        + 'LOTE LOGIN.....................: ' + objParametrosDeEntrada.APP_LOGAR_LOTE + #13
        + 'IP.............................: ' + objParametrosDeEntrada.IP);

      showmessage(sMSG);
      objLogar.Logar(sMSG);

    end;
  end;

  objLogar.Logar('[DEBUG] TCore.MainLoop() - ...end');

end;

Procedure TCore.PROCESSAMENTO();
Var


Arq_Arquivo_Entada   : TextFile;
Arq_Arquivo_Saida    : TextFile;

sArquivoEntrada      : string;
sArquivoSaida        : string;
sLinha               : string;
sValues              : string;
sComando             : string;
sCampos              : string;
sOperadora           : string;
sContrato            : string;
sCep                 : string;

iContArquivos        : Integer;
iTotalDeArquivos     : Integer;

// Variáveis de controle do select
iTotalDeRegistrosDaTabela : Integer;
iLimit : Integer;
iTotalDeInteracoesDeSelects : Integer;
iResto : Integer;
iRegInicial : Integer;
iQtdeRegistros : Integer;
iContInteracoesDeSelects : Integer;


begin

  //*********************************************************************************************
  //                         Alimentando nome dos campos da tabela de Cliente
  //*********************************************************************************************
  sComando := 'describe ' + objParametrosDeEntrada.tabela_processamento;
  objStatusProcessamento := objConexao.Executar_SQL(__queryMySQL_processamento__, sComando, 2);

  while not __queryMySQL_processamento__.Eof do
  Begin
    sCampos := sCampos + __queryMySQL_processamento__.FieldByName('Field').AsString;
    __queryMySQL_processamento__.Next;
    if not __queryMySQL_processamento__.Eof then
      sCampos := sCampos + ',';
  end;

  iTotalDeArquivos := objParametrosDeEntrada.ListaDeArquivosDeEntrada.Count;

  for iContArquivos := 0 to iTotalDeArquivos - 1 do
  begin

    sComando := 'delete from ' + objParametrosDeEntrada.tabela_processamento;
    objStatusProcessamento := objConexao.Executar_SQL(__queryMySQL_processamento__, sComando, 1);

    sArquivoEntrada := objParametrosDeEntrada.ListaDeArquivosDeEntrada.Strings[iContArquivos];

    AssignFile(Arq_Arquivo_Entada, objString.AjustaPath(objParametrosDeEntrada.PathEntrada) + sArquivoEntrada);
    reset(Arq_Arquivo_Entada);

    while not eof(Arq_Arquivo_Entada) do
    Begin

      readln(Arq_Arquivo_Entada, sLinha);

      sLinha := objString.StringReplaceList(sLinha, objParametrosDeEntrada.lista_de_caracteres_invalidos);

      sOperadora := Copy(sLinha, 16, 3);
      sContrato  := Copy(sLinha, 23, 9);
      sCep       := Copy(sLinha, 393, 8);

      sValues := '"' + sOperadora + '",'
               + '"' + sContrato + '",'
               + '"' + sCep + '",'
               + '"' + sLinha + '"';

      sComando := 'Insert into ' + objParametrosDeEntrada.tabela_processamento + ' (' + sCampos + ') values(' + sValues + ')';
      objStatusProcessamento := objConexao.Executar_SQL(__queryMySQL_processamento__, sComando, 1);

    end;

    CloseFile(Arq_Arquivo_Entada);

    sComando := 'SELECT count(contrato) as qtde FROM ' + objParametrosDeEntrada.tabela_processamento;
    objStatusProcessamento := objConexao.Executar_SQL(__queryMySQL_processamento__, sComando, 2);

    iTotalDeRegistrosDaTabela := __queryMySQL_processamento__.FieldByName('qtde').AsInteger;

    iLimit := StrToInt(objParametrosDeEntrada.LIMITE_DE_SELECT_POR_INTERACOES_NA_MEMORIA);
    iResto := iTotalDeRegistrosDaTabela mod iLimit;

    if iResto <> 0 then
      iTotalDeInteracoesDeSelects := iTotalDeRegistrosDaTabela div iLimit + 1
    else
      iTotalDeInteracoesDeSelects := iTotalDeRegistrosDaTabela div iLimit;

    iQtdeRegistros := 0;

    sArquivoSaida   := StringReplace(sArquivoEntrada, '.txt', '_SAIDA.TXT', [rfReplaceAll, rfIgnoreCase]);

    AssignFile(Arq_Arquivo_Saida, objString.AjustaPath(objParametrosDeEntrada.PATHSAIDA) + sArquivoSaida);
    Rewrite(Arq_Arquivo_Saida);

    for iContInteracoesDeSelects := 0 to iTotalDeInteracoesDeSelects -1 do
    begin
      iRegInicial    := iQtdeRegistros;
      iQtdeRegistros := iQtdeRegistros + iLimit;

      sComando := 'SELECT * FROM ' + objParametrosDeEntrada.tabela_processamento + ' limit ' + IntToStr(iRegInicial) + ',' + IntToStr(iLimit);
      objStatusProcessamento := objConexao.Executar_SQL(__queryMySQL_processamento__, sComando, 2);

      while not __queryMySQL_processamento__.Eof do
      begin

        sLinha := __queryMySQL_processamento__.FieldByName('LINHA').AsString;

        sCep   := Copy(sLinha, 393, 8);

        writeln(Arq_Arquivo_Saida, sLinha);

        __queryMySQL_processamento__.Next;

      end;

    end;

    CloseFile(Arq_Arquivo_Saida);

    IF StrToBool(objParametrosDeEntrada.BLOCAR_ARQUIVO) THEN
      objBlocagemInteligente.Blocar(objParametrosDeEntrada.PathSaida + sArquivoSaida);

  end;

end;

procedure TCore.ExcluirBase(NomeTabela: String);
var
  sComando : String;
  sBase    : string;
begin

  sBase := objString.getTermo(1, '.', NomeTabela);

  sComando := 'drop database ' + sBase;
  objStatusProcessamento := objConexao.Executar_SQL(__queryMySQL_processamento__, sComando, 1);
end;

procedure TCore.ExcluirTabela(NomeTabela: String);
var
  sComando : String;
  sTabela  : String;
begin

  sTabela := objString.getTermo(2, '.', NomeTabela);

  sComando := 'drop table ' + sTabela;
  objStatusProcessamento := objConexao.Executar_SQL(__queryMySQL_processamento__, sComando, 1);
end;

Procedure TCore.PROCESSAMENTO_SP();
Var

objArquivoSaida : TArquivoTexto;

sArquivoSaida   : string;

Arq_Arquivo_Entada : TextFile;

sArquivoEntrada : string;

sComando : string;
sCampos : string;

iContArquivos : Integer;
iTotalDeArquivos : Integer;

sLinha : string;

sValues : string;

// Variáveis de controle do select
iTotalDeRegistrosDaTabela : Integer;
iLimit : Integer;
iTotalDeInteracoesDeSelects : Integer;
iResto : Integer;
iRegInicial : Integer;
iQtdeRegistros : Integer;
iContInteracoesDeSelects : Integer;

sOperadora : string;
sContrato : string;
sCep : string;
sArquivoInsessaoBanco: string;

begin

  objParametrosDeEntrada.STL_SP001  := TStringList.create();
  objParametrosDeEntrada.STL_SP002  := TStringList.create();
  objParametrosDeEntrada.STL_SP003  := TStringList.create();

  objParametrosDeEntrada.STL_SP001.LoadFromFile(objParametrosDeEntrada.SP_001);
  objParametrosDeEntrada.STL_SP002.LoadFromFile(objParametrosDeEntrada.SP_002);
  objParametrosDeEntrada.STL_SP003.LoadFromFile(objParametrosDeEntrada.SP_003);

  // CHAMO APENAS A PRIMEIRA STORED POIS ELA CHAMA A RESTANTE;

  StoredProcedure_Dropar(objParametrosDeEntrada.SP_001_NAME);
  StoredProcedure_Dropar(objParametrosDeEntrada.SP_002_NAME);
  StoredProcedure_Dropar(objParametrosDeEntrada.SP_003_NAME);

  StoredProcedure_Criar('SP001', objParametrosDeEntrada.STL_SP001);
  StoredProcedure_Criar('SP002', objParametrosDeEntrada.STL_SP002);
  StoredProcedure_Criar('SP003', objParametrosDeEntrada.STL_SP003);

  //*********************************************************************************************
  //                         Alimentando nome dos campos da tabela de Cliente
  //*********************************************************************************************
  sComando := 'describe ' + objParametrosDeEntrada.tabela_processamento;
  objStatusProcessamento := objConexao.Executar_SQL(__queryMySQL_processamento__, sComando, 2);

  while not __queryMySQL_processamento__.Eof do
  Begin
    sCampos := sCampos + __queryMySQL_processamento__.FieldByName('Field').AsString;
    __queryMySQL_processamento__.Next;
    if not __queryMySQL_processamento__.Eof then
      sCampos := sCampos + ',';
  end;

  iTotalDeArquivos := objParametrosDeEntrada.ListaDeArquivosDeEntrada.Count;

  for iContArquivos := 0 to iTotalDeArquivos - 1 do
  begin

    sArquivoEntrada       := objParametrosDeEntrada.ListaDeArquivosDeEntrada.Strings[iContArquivos];
    sArquivoInsessaoBanco := objParametrosDeEntrada.PathEntrada + sArquivoEntrada;
    sArquivoInsessaoBanco := StringReplace(sArquivoInsessaoBanco, '\', '\\', [rfReplaceAll, rfIgnoreCase]);

    sComando := ' LOAD DATA LOCAL INFILE "'+ sArquivoInsessaoBanco +'" '
             + ' INTO TABLE ' + objParametrosDeEntrada.TABELA_ENTRADA_SP
             + ' FIELDS ESCAPED BY "\t" '    //desta forma se tiver aspas duplas, aspas simples ou contra-barra no arquivo ele vai gravá-las, sem dar erro e gravando inclusive estes caracteres no campo da tabela destino
             + ' LINES TERMINATED BY "\n" '
             + ' (textolinha, arquivo, tipo_reg) '
             + ' SET arquivo  = "' + sArquivoEntrada + '",'
             + '     tipo_reg = MID(textolinha, 1, 2)';
    objStatusProcessamento := objConexao.Executar_SQL(__queryMySQL_processamento__, sComando, 1);

    objLogar.Logar('ARQUIVO: ' + sArquivoEntrada + ' INSERIDO NA TABELA:' + objParametrosDeEntrada.TABELA_ENTRADA_SP);

  end;

  StoredProcedure_Executar(objParametrosDeEntrada.SP_001_NAME);

end;


procedure TCore.StoredProcedure_Dropar(Nome: string; logBD:boolean=false; idprograma:integer=0);
var
  sSQL: string;
  sMensagem: string;
begin
  try
    sSQL := 'DROP PROCEDURE if exists ' + Nome;
    objConexao.Executar_SQL(__queryMySQL_processamento__, sSQL, 1);
  except
    on E:Exception do
    begin
      sMensagem := '  StoredProcedure_Dropar(' + Nome + ') - Excecao:' + E.Message + ' . SQL: ' + sSQL;
      objLogar.Logar(sMensagem);
    end;
  end;

end;

function TCore.StoredProcedure_Criar(Nome : string; scriptSQL: TStringList): boolean;
var
  bExecutou    : boolean;
  sMensagem    : string;
begin


  bExecutou := objConexao.Executar_SQL(__queryMySQL_processamento__, scriptSQL.Text, 1).status;

  if not bExecutou then
  begin
    sMensagem := '  StoredProcedure_Criar(' + Nome + ') - Não foi possível carregar a stored procedure para execução.';
    objLogar.Logar(sMensagem);
  end;

  result := bExecutou;
end;

procedure TCore.StoredProcedure_Executar(Nome: string; ComParametro:boolean=false; logBD:boolean=false; idprograma:integer=0);
var

  sSQL        : string;
  sMensagem   : string;
begin

  try
    (*
    if not Assigned(con) then
    begin
      con := TZConnection.Create(Application);
      con.HostName  := objConexao.getHostName;
      con.Database  := sNomeBase;
      con.User      := objConexao.getUser;
      con.Protocol  := objConexao.getProtocolo;
      con.Password  := objConexao.getPassword;
      con.Properties.Add('CLIENT_MULTI_STATEMENTS=1');
      con.Connected := True;
    end;

    if not Assigned(QP) then
      QP := TZQuery.Create(Application);

    QP.Connection := con;
    QP.SQL.Clear;
    *)

    sSQL := 'CALL '+ Nome;
    if not ComParametro then
      sSQL := sSQL + '()';

    objConexao.Executar_SQL(__queryMySQL_processamento__, sSQL, 1);

  except
    on E:Exception do
    begin
      sMensagem := '[ERRO] StoredProcedure_Executar('+Nome+') - Excecao:'+E.Message+' . SQL: '+sSQL;
      objLogar.Logar(sMensagem);
      ShowMessage(sMensagem);
    end;
  end;

//  objConexao.Executar_SQL(__queryMySQL_processamento__, sSQL, 1)

end;

function TCore.EnviarEmail(Assunto: string=''; Corpo: string=''): Boolean;
var
  sHost    : string;
  suser    : string;
  sFrom    : string;
  sTo      : string;
  sAssunto : string;
  sCorpo   : string;
  sAnexo   : string;
  sAplicacao: string;

begin

  sAplicacao := ExtractFileName(Application.ExeName);
  sAplicacao := StringReplace(sAplicacao, '.exe', '', [rfReplaceAll, rfIgnoreCase]);

  sHost    := objParametrosDeEntrada.eHost;
  suser    := objParametrosDeEntrada.eUser;
  sFrom    := objParametrosDeEntrada.eFrom;
  sTo      := objParametrosDeEntrada.eTo;
  sAssunto := 'Processamento - ' + sAplicacao + ' - ' + objFuncoesWin.GetVersaoDaAplicacao() + ' [PROCESSAMENTO: ' + objParametrosDeEntrada.PEDIDO_LOTE + ']';
  sAssunto := sAssunto + ' ' + Assunto;
  sCorpo   := Corpo;

  sAnexo := objLogar.getArquivoDeLog();

  //sAnexo := StringReplace(anexo, '"', '', [rfReplaceAll, rfIgnoreCase]);
  //sAnexo := StringReplace(anexo, '''', '', [rfReplaceAll, rfIgnoreCase]);

  try

    objEmail := TSMTPDelphi.create(sHost, suser);

    if objEmail.ConectarAoServidorSMTP() then
    begin
      if objEmail.AnexarArquivo(sAnexo) then
      begin

          if not (objEmail.EnviarEmail(sFrom, sTo, sAssunto, sCorpo)) then
            ShowMessage('ERRO AO ENVIAR O E-MAIL')
          else
          if not objEmail.DesconectarDoServidorSMTP() then
            ShowMessage('ERRO AO DESCONECTAR DO SERVIDOR');
      end
      else
        ShowMessage('ERRO AO ANEXAR O ARQUIVO');
    end
    else
      ShowMessage('ERRO AO CONECTAR AO SERVIDOR');

  except
    ShowMessage('NÃO FOI POSSIVEL ENVIAR O E-MAIL.');
  end;
end;



function Tcore.PesquisarLote(LOTE_PEDIDO : STRING; status : Integer): Boolean;
var
  sComando : string;
  iPedido  : Integer;
  sStauts  : string;
begin

  case status of
    0: sStauts := 'S';
    1: sStauts := 'N';
  end;

  objParametrosDeEntrada.PEDIDO_LOTE_TMP := LOTE_PEDIDO;

  sComando := ' SELECT RELATORIO_QTD FROM  ' + objParametrosDeEntrada.TABELA_LOTES_PEDIDOS
            + ' WHERE LOTE_PEDIDO = ' + LOTE_PEDIDO + ' AND VALIDO = "' + sStauts + '"';
  objStatusProcessamento := objConexao.Executar_SQL(__queryMySQL_processamento__, sComando, 2);

  objParametrosDeEntrada.stlRelatorioQTDE.Text := __queryMySQL_processamento__.FieldByName('RELATORIO_QTD').AsString;

  if __queryMySQL_processamento__.RecordCount > 0 then
    Result := True
  else
    Result := False;

end;

PROCEDURE TCORE.COMPACTAR();
Var
  sArquivo         : String;
  sPathEntrada     : String;
  sPathSaida       : String;

  iContArquivos    : Integer;
  iTotalDeArquivos : Integer;
BEGIN

  sPathEntrada := objString.AjustaPath(objParametrosDeEntrada.PATHENTRADA);
  sPathSaida   := objString.AjustaPath(objParametrosDeEntrada.PATHSAIDA);
  ForceDirectories(sPathSaida);

  iTotalDeArquivos := objParametrosDeEntrada.ListaDeArquivosDeEntrada.Count;

  for iContArquivos := 0 to iTotalDeArquivos - 1 do
  begin

    sArquivo := objParametrosDeEntrada.LISTADEARQUIVOSDEENTRADA.Strings[iContArquivos];
    COMPACTAR_ARQUIVO(sPathEntrada + sArquivo, sPathSaida, True);

  end;

end;

PROCEDURE TCORE.EXTRAIR();
Var
  sArquivo         : String;
  sPathEntrada     : String;
  sPathSaida       : String;

  iContArquivos    : Integer;
  iTotalDeArquivos : Integer;
BEGIN

  sPathEntrada := objString.AjustaPath(objParametrosDeEntrada.PATHENTRADA);
  sPathSaida   := objString.AjustaPath(objParametrosDeEntrada.PATHSAIDA);
  ForceDirectories(sPathSaida);

  iTotalDeArquivos := objParametrosDeEntrada.ListaDeArquivosDeEntrada.Count;

  for iContArquivos := 0 to iTotalDeArquivos - 1 do
  begin

    sArquivo := objParametrosDeEntrada.LISTADEARQUIVOSDEENTRADA.Strings[iContArquivos];
    EXTRAIR_ARQUIVO(sPathEntrada + sArquivo, sPathSaida);

  end;

end;


PROCEDURE TCORE.COMPACTAR_ARQUIVO(ARQUIVO_ORIGEM, PATH_DESTINO: String; MOVER_ARQUIVO: Boolean = FALSE; ZIP: Boolean=false);
begin

  Compactar_Arquivo_7z(ARQUIVO_ORIGEM, PATH_DESTINO, MOVER_ARQUIVO, ZIP);

end;

PROCEDURE TCORE.EXTRAIR_ARQUIVO(ARQUIVO_ORIGEM, PATH_DESTINO: String);
begin

  Extrair_Arquivo_7z(ARQUIVO_ORIGEM, PATH_DESTINO);

end;

function TCORE.Compactar_Arquivo_7z(Arquivo, destino : String; mover_arquivo: Boolean=false; ZIP: Boolean=false): integer;
Var
  sComando                  : String;
  sArquivoDestino           : String;
  sParametros               : String;
  __AplicativoCompactacao__ : String;

  iRetorno                  : Integer;
Begin

  destino     := objString.AjustaPath(destino);
  sParametros := ' a ';

  if ZIP then
  begin

    IF Pos('.csv', Arquivo) > 0 THEN
      sArquivoDestino := StringReplace(ExtractFileName(Arquivo), '.csv', '', [rfReplaceAll, rfIgnoreCase]) + '.zip'
    else
    IF Pos('.txt', Arquivo) > 0 THEN
      sArquivoDestino := StringReplace(ExtractFileName(Arquivo), '.txt', '', [rfReplaceAll, rfIgnoreCase]) + '.zip'
    else
    IF Pos('.CSV', Arquivo) > 0 THEN
      sArquivoDestino := StringReplace(ExtractFileName(Arquivo), '.CSV', '', [rfReplaceAll, rfIgnoreCase]) + '.ZIP'
    else
    IF Pos('.TXT', Arquivo) > 0 THEN
      sArquivoDestino := StringReplace(ExtractFileName(Arquivo), '.TXT', '', [rfReplaceAll, rfIgnoreCase]) + '.ZIP'
    else
      sArquivoDestino := ExtractFileName(Arquivo) + '.ZIP';

    sParametros     := sParametros + ' -tzip ';

  end
  else
  BEGIN

    IF Pos('.TXT', Arquivo) > 0 THEN
      sArquivoDestino := StringReplace(ExtractFileName(Arquivo), '.TXT', '', [rfReplaceAll, rfIgnoreCase]) + '.7Z'
    ELSE
      sArquivoDestino := ExtractFileName(Arquivo) + '.7Z';

  end;

    IF StrToInt(objParametrosDeEntrada.ARQUITETURA_WINDOWS) = 32 THEN
      __AplicativoCompactacao__ := objParametrosDeEntrada.app_7z_32bits;

    IF StrToInt(objParametrosDeEntrada.ARQUITETURA_WINDOWS) = 64 THEN
      __AplicativoCompactacao__ := objParametrosDeEntrada.app_7z_64bits;

    sComando := __AplicativoCompactacao__ + sParametros + ' "' + destino + sArquivoDestino + '" "' + Arquivo + '"';

    if mover_arquivo then
      sComando := sComando + ' -sdel';

    iRetorno := objFuncoesWin.WinExecAndWait32(sComando);

    Result   := iRetorno;

End;

function TCORE.Extrair_Arquivo_7z(Arquivo, destino : String): integer;
Var
  sComando                  : String;
  sParametros               : String;
  __AplicativoCompactacao__ : String;

  iRetorno                  : Integer;
Begin

    destino := objString.AjustaPath(destino);

    sParametros := ' e ';

    IF StrToInt(objParametrosDeEntrada.ARQUITETURA_WINDOWS) = 32 THEN
      __AplicativoCompactacao__ := objParametrosDeEntrada.app_7z_32bits;

    IF StrToInt(objParametrosDeEntrada.ARQUITETURA_WINDOWS) = 64 THEN
      __AplicativoCompactacao__ := objParametrosDeEntrada.app_7z_64bits;

    sComando := __AplicativoCompactacao__ + sParametros + ' ' + Arquivo +  ' -y -o"' + destino + '"';

    iRetorno := objFuncoesWin.WinExecAndWait32(sComando);

    Result   := iRetorno;

End;

procedure TCore.CriaMovimento();
var
  Arq_Arquivo_Entada                : textfile;
  Arq_Arquivo_Saida                 : textfile;
  Arq_Arquivo_Saida_CIF             : textfile;
  sArquivoEntrada                   : string;
  sArquivoSaidaCIF                  : string;
  sPathEntrada                      : string;
  sPathMovimentoArquivos            : string;
  sPathMovimentoBackupZip           : string;
  sPathMovimentoCIF                 : string;
  sPathMovimentoRelatorio           : string;
  sPathComplemento                  : string;
  sPathMovimentoTRACK               : string;
  sPathMovimentoTMP                 : string;
  sArquivoZIP                       : string;
  sArquivoPDF                       : string;
  sArquivoTXT                       : string;
  sArquivoJRN                       : string;
  sArquivoAFP                       : string;
  sArquivoREL                       : string;
  sComando                          : string;
  sLinha                            : string;
  sCEP                              : string;
  sCIF_WEB                          : string;
  sCIF_GPOST                        : string;
  sDR_Postgem                       : string;
  sCodigoADM                        : string;
  sLoteFAC                          : string;
  sSequenciaOBJ                     : string;
  sCodigoDestino                    : string;
  sFillerFixo                       : string;
  sDataPostagem                     : string;
  sCicloPostagem                    : string;
  sCodigoServico                    : string;
  sPeso                             : string;

  sNumeroCartao                     : string;

  sArquivoPdfOrigem                 : string;
  sTipoArquivoPdfOrigem             : string;
  sTipoArquivoOrigem                : string;

  sCODIGO_AVALIACAO_TECNICA         : string;

  sCepStatus                        : string;
  sLabelMotivoRetencao              : string;

  sChaveRetencao                    : string;
  sFolhas                           : string;

  iContArquivos                     : Integer;
  iContReg                          : Integer;
  iContArquivoZip                   : Integer;
  //iTotalFolhas                      : Integer;
  //iTotalPaginas                     : Integer;
  iTotalPeso                        : Integer;
  iTotalObjestos                    : Integer;

  iObjetosOk                        : Integer;
  iObjetosRetidos                   : Integer;

  iPesoObjetosOk                    : Integer;
  iPesoObjetosRetidos               : Integer;


  iTotalObjetosOk                   : Integer;
  iTotalObjetosRetidos              : Integer;

  iPesoTotalObjetosOk               : Integer;
  iPesoTotalObjetosRetidos          : Integer;


  stlFiltroArquivo                  : TStringList;
  stlRelatorio                      : TStringList;
  stlListaRetencao                  : TStringList;
  stlRelatorioObjRetidosAnalitico   : TStringList;
  stlTrack                          : TStringList;

  wDia                              : word;
  wMes                              : word;
  wAno                              : word;

  sAno                              : String;
  sAnoPostagem                      : String;
  sMes                              : String;
  sMesPostagem                      : String;
  sNomeClienteEndereco              : String;

  sNovaDataPostagemCif                 : String;

begin

  objParametrosDeEntrada.TIMESTAMP := now();

  DecodeDate(objParametrosDeEntrada.TIMESTAMP, wAno, wMes, wDia);
  sAno := FormatFloat('0000', wAno);
  sMes := FormatFloat('00', wMes);

  sNovaDataPostagemCif := FormatDateTime('DDMMYY', objParametrosDeEntrada.DATA_POSTAGEM);

  //=======================================================================================================================================================================================
  //  LIMPANDO A TABELA DE PROCESSAMENTO
  //=======================================================================================================================================================================================
  sComando := 'DELETE FROM ' + objParametrosDeEntrada.TABELA_PROCESSAMENTO;
  objConexao.Executar_SQL(__queryMySQL_processamento__, sComando, 1);
  //=======================================================================================================================================================================================

  if objParametrosDeEntrada.TESTE then
    sPathComplemento := '_TESTE';

  stlFiltroArquivo                 := TStringList.create();
  stlRelatorio                     := TStringList.create();
  stlListaRetencao                 := TStringList.create();
  stlRelatorioObjRetidosAnalitico  := TStringList.create();
  stlTrack                         := TStringList.create();

  //=======================================================================================================================================================================================
  //  DEFINE ESTRUTURA MOVIMENTO
  //=======================================================================================================================================================================================
  sPathEntrada                     := objString.AjustaPath(objParametrosDeEntrada.PATHENTRADA);
  sPathMovimentoArquivos           := objString.AjustaPath(objParametrosDeEntrada.PATHSAIDA);
  sPathmovimentoBackupZip          := objString.AjustaPath(objParametrosDeEntrada.PATHSAIDA) + FormatDateTime('YYYYMMDD', objParametrosDeEntrada.MOVIMENTO) + sPathComplemento + PathDelim + FormatFloat(objParametrosDeEntrada.FORMATACAO_LOTE_PEDIDO, StrToInt(objParametrosDeEntrada.PEDIDO_LOTE)) + PathDelim + 'BACKUP_ZIP' + PathDelim;
  //sPathmovimentoCIF                := objString.AjustaPath(objParametrosDeEntrada.PATHSAIDA) + PathDelim + 'CIF'        + PathDelim;
  sPathMovimentoRelatorio          := objString.AjustaPath(objParametrosDeEntrada.PATHSAIDA) + PathDelim + 'RELATORIO'  + PathDelim;
  sPathMovimentoTRACK              := objString.AjustaPath(objParametrosDeEntrada.PATHSAIDA) + FormatDateTime('YYYYMMDD', objParametrosDeEntrada.MOVIMENTO) + sPathComplemento + PathDelim + FormatFloat(objParametrosDeEntrada.FORMATACAO_LOTE_PEDIDO, StrToInt(objParametrosDeEntrada.PEDIDO_LOTE)) + PathDelim + 'TRACK'      + PathDelim;
  sPathMovimentoTMP                := objString.AjustaPath(objParametrosDeEntrada.PATHSAIDA) + FormatDateTime('YYYYMMDD', objParametrosDeEntrada.MOVIMENTO) + sPathComplemento + PathDelim + FormatFloat(objParametrosDeEntrada.FORMATACAO_LOTE_PEDIDO, StrToInt(objParametrosDeEntrada.PEDIDO_LOTE)) + PathDelim + 'TMP'      + PathDelim;
  //=======================================================================================================================================================================================

  //===================================================================================================================================================================
  // CRIA PASTAS
  //===================================================================================================================================================================
  ForceDirectories(sPathMovimentoArquivos);
//  ForceDirectories(sPathmovimentoBackupZip);
//  ForceDirectories(sPathmovimentoCIF);
  ForceDirectories(sPathMovimentoRelatorio);
  //ForceDirectories(sPathMovimentoTRACK);
  //ForceDirectories(sPathMovimentoTMP);
  //===================================================================================================================================================================

  //===================================================================================================================================================================
  // Carrega arquivo rentencao
  //===================================================================================================================================================================
  if objParametrosDeEntrada.TEM_ARQUIVO_RETENCAO then
  begin

    AssignFile(Arq_Arquivo_Entada, objString.AjustaPath(objParametrosDeEntrada.PathEntrada) + 'RETENCAO.CSV');
    reset(Arq_Arquivo_Entada);

    stlListaRetencao.Clear;
    while not eof(Arq_Arquivo_Entada) do
    Begin
      readln(Arq_Arquivo_Entada, sLinha);

      sChaveRetencao := objString.getTermo(01, ';', sLinha);
      stlListaRetencao.Add(sChaveRetencao);

    end;

    CloseFile(Arq_Arquivo_Entada);

  end;
  //===================================================================================================================================================================

  //===================================================================================================================================================================
  // Processa arquivo
  //===================================================================================================================================================================
  for iContArquivos := 0 to objParametrosDeEntrada.LISTADEARQUIVOSDEENTRADA.Count - 1 do
  begin


    sArquivoEntrada := objParametrosDeEntrada.ListaDeArquivosDeEntrada.Strings[iContArquivos];

    AssignFile(Arq_Arquivo_Saida, sPathMovimentoArquivos + sArquivoEntrada + '.GPOST.' + StringReplace(objParametrosDeEntrada.EXTENCAO_ARQUIVOS, '*.', '', [rfReplaceAll, rfIgnoreCase]));
    Rewrite(Arq_Arquivo_Saida);

    AssignFile(Arq_Arquivo_Entada, objString.AjustaPath(objParametrosDeEntrada.PathEntrada) + sArquivoEntrada);
    reset(Arq_Arquivo_Entada);

    iContReg := 0;
    while not eof(Arq_Arquivo_Entada) do
    Begin

      readln(Arq_Arquivo_Entada, sLinha);
      inc(iContReg);

      sNomeClienteEndereco              := objString.getTermo(04, '^', sLinha);
      sArquivoPdfOrigem                 := '';
      sTipoArquivoPdfOrigem             := ''; //AnsiUpperCase(Copy(sArquivoPdfOrigem, length(sArquivoPdfOrigem) - 5, 6));

      sCODIGO_AVALIACAO_TECNICA         := objParametrosDeEntrada.CODIGO_AVALIACAO_TECNICA;
      sTipoArquivoOrigem                := 'QT'; // QUITAÇÃO

      sPeso                             := objParametrosDeEntrada.PESO;


      sFolhas                           := '1';

      sCEP                              := objString.getTermo(08, '^', sLinha);
      sCEP                              := StringReplace(sCEP, '-', '', [rfReplaceAll, rfIgnoreCase]);
      sCEP                              := StringReplace(sCEP, ' ', '', [rfReplaceAll, rfIgnoreCase]);

      //=======================================================
      // VALIDAÇÃO SIMPLES DA INTEGRIDADE DO CEP
      //=======================================================
      sCepStatus := '01';

      if StrToIntDef(sCEP, 0) = 0 then
        sCepStatus:= '04';

      // Primeiro teste
      if length(trim(sCEP)) <> 8 then
        sCepStatus:= '02';

      // Segunto teste
      if sCEP = '00000000' then
        sCepStatus:= '03';

      //=======================================================

      sCIF_WEB                          := objString.getTermo(13, '^', sLinha);

      sDR_Postgem                       := copy(sCIF_WEB, 01, 02);
      sCodigoADM                        := copy(sCIF_WEB, 03, 08);
      sLoteFAC                          := copy(sCIF_WEB, 11, 05);
      sSequenciaOBJ                     := copy(sCIF_WEB, 16, 11);
      sCodigoDestino                    := copy(sCIF_WEB, 27, 01);
      sFillerFixo                       := copy(sCIF_WEB, 28, 01);
      sDataPostagem                     := copy(sCIF_WEB, 29, 06);

      if objParametrosDeEntrada.DEFINIR_DATA_POSTAGEM then
        sDataPostagem := sNovaDataPostagemCif;

      sMesPostagem                      := copy(sDataPostagem, 3, 2);
      sAnoPostagem                      := copy(sAno, 1, 2) + copy(sDataPostagem, 5, 2);

      sCIF_GPOST                        := objParametrosDeEntrada.NUMERO_CARTAO
                                         + sLoteFAC
                                         + sSequenciaOBJ
                                         + sCodigoDestino
                                         + objParametrosDeEntrada.CODIGO_MUTIPLO
                                         + sDataPostagem;

      sLinha := StringReplace(sLinha, sCIF_WEB, sCIF_GPOST, [rfReplaceAll, rfIgnoreCase]);

      case StrToInt(sCodigoDestino) of
        1: sCodigoServico := objParametrosDeEntrada.FAC_SIMPLES_LOCAL;
        2: sCodigoServico := objParametrosDeEntrada.FAC_SIMPLES_ESTADUAL;
        3: sCodigoServico := objParametrosDeEntrada.FAC_SIMPLES_NACIONAL;
      else
         sCodigoServico := objParametrosDeEntrada.FAC_SIMPLES_LOCAL;
      end;

      //====================================================================================
      //  PEGANDO O CICLO DE POSTAGEM FAC GPOST
      //====================================================================================
      sComando := 'SELECT CICLO FROM ' + objParametrosDeEntrada.TABELA_CICLO_POSTAGEM_FAC
            + ' WHERE MES = "' + sMesPostagem + '"';
            objConexao.Executar_SQL(__queryMySQL_processamento__, sComando, 2);

      sCicloPostagem := __queryMySQL_processamento__.FieldByName('CICLO').AsString;
      //====================================================================================

        //=================================================================================================================================================================
        //  INSERE NA TABELA PROCESSAMENTO
        //=================================================================================================================================================================
        sComando := 'insert into ' + objParametrosDeEntrada.TABELA_PROCESSAMENTO
                  + ' (SEQUENCIA'
                  + ' ,NOME_CLIENTE_ENDERECO'
                  + ' ,NUMERO_CONTRATO'
                  + ' ,NUMERO_CARTAO'
                  + ' ,NUMERO_LOTE'
                  + ' ,MCU_UNIDADE_POSTAGEM'
                  + ' ,CEP_UNIDADE_POSTAGEM'
                  + ' ,CODIGO_AVALIACAO_TECNICA'
                  + ' ,CICLO_POSTAGEM'
                  + ' ,ANO_POSTAGEM'
                  + ' ,DNE_ATUALIZADO'
                  + ' ,SEQUENCIA_OBJETO'
                  + ' ,PESO'
                  + ' ,CODIGO_SERVICO'
                  + ' ,CODIGO_MULTIPLO'
                  + ' ,CODIGO_CONTEUDO'
                  + ' ,CODIGO_SERVICO_ADICIONAL'
                  + ' ,VALOR_DECLARADO'
                  + ' ,CEP_DESTINO'
                  + ' ,CEP_STATUS'
                  + ' ,DATA_POSTAGEM'
                  + ' ,MOVIMENTO'
                  + ' ,ARQUIVO'
                  + ' ,PRODUTO'
                  + ')'

                  + ' VALUES ('
                  + '"'   + IntToStr(iContReg)
                  + '","' + sNomeClienteEndereco
                  + '","' + objParametrosDeEntrada.NUMERO_CONTRATO
                  + '","' + objParametrosDeEntrada.NUMERO_CARTAO
                  + '","' + sLoteFAC
                  + '","' + objParametrosDeEntrada.CODIGO_UNIDADE_POSTAGEM
                  + '","' + objParametrosDeEntrada.CEP_UNIDADE_POSTAGEM
                  + '","' + sCODIGO_AVALIACAO_TECNICA
                  + '","' + sCicloPostagem
                  + '","' + sAnoPostagem
                  + '","' + objParametrosDeEntrada.DNE_ATUALIZADO
                  + '","' + sSequenciaOBJ
                  + '","' + sPeso
                  + '","' + sCodigoServico
                  + '","' + objParametrosDeEntrada.CODIGO_MUTIPLO
                  + '","' + objParametrosDeEntrada.CODIGO_CONTEUDO
                  + '","' + objParametrosDeEntrada.CODIGO_SERVICO_ADICIONAL
                  + '","' + objParametrosDeEntrada.VALOR_DECLARADO
                  + '","' + sCEP
                  + '","' + sCepStatus
                  + '","' + sDataPostagem
                  + '","' + FormatDateTime('YYYYMMDD', objParametrosDeEntrada.MOVIMENTO)
                  + '","' + sArquivoEntrada
                  + '","' + sTipoArquivoOrigem
                  + '"'
                  + ')';
        objConexao.Executar_SQL(__queryMySQL_processamento__, sComando, 1);

          //=================================================================================================================================================================
          //  INSERE NA TABELA TRACK LINE
          //=================================================================================================================================================================
          if not objParametrosDeEntrada.TESTE then
          begin
            sComando := 'INSERT INTO  ' + objParametrosDeEntrada.TABELA_TRACK_LINE
                      + ' (ARQUIVO_TXT'
                       + ',SEQUENCIA_REGISTRO'
                       + ',TIMESTAMP'
                       + ',LOTE_PROCESSAMENTO'
                       + ',MOVIMENTO'
                       + ',ACABAMENTO'
                       + ',PAGINAS'
                       + ',FOLHAS'
                       + ',OF_FORMULARIO'
                       + ',DATA_POSTAGEM'
                       + ',LOTE'
                       + ',CIF'
                       + ',PESO'
                       + ',DIRECAO'
                       + ',CATEGORIA'
                       + ',PORTE'
                       + ',STATUS_REGISTRO'
                       + ',PAPEL'
                       + ',TIPO_DOCUMENTO'
                       + ',LINHA'
                       + ') '
                       + ' VALUES("'
                       +         sArquivoEntrada
                       + '","' + IntToStr(iContReg)
                       + '","' + FormatDateTime('YYYY-MM-DD hh:mm:ss', objParametrosDeEntrada.TIMESTAMP)
                       + '","' + FormatFloat(objParametrosDeEntrada.FORMATACAO_LOTE_PEDIDO, StrToInt(objParametrosDeEntrada.PEDIDO_LOTE))
                       + '","' + FormatDateTime('YYYYMMDD', objParametrosDeEntrada.MOVIMENTO)
                       + '","' + ''
                       + '","' + ''
                       + '","' + sFolhas
                       + '","' + ''
                       + '","' + sDataPostagem
                       + '","' + sLoteFAC
                       + '","' + sCIF_GPOST
                       + '","' + IntToStr(iTotalPeso)
                       + '","' + sCodigoDestino
                       + '","' + sCodigoServico
                       + '","' + ''
                       + '","' + sCepStatus
                       + '","' + ''
                       + '","' + sTipoArquivoOrigem
                       + '","' + sLinha
                       + '")'
                       ;
            objConexao.Executar_SQL(__queryMySQL_processamento__, sComando, 1);

          end;


      writeln(Arq_Arquivo_Saida, sLinha);

    end;

    CloseFile(Arq_Arquivo_Entada);
    CloseFile(Arq_Arquivo_Saida);
  END;
  //===================================================================================================================================================================

  stlRelatorioObjRetidosAnalitico.Clear;
  stlRelatorioObjRetidosAnalitico.Add('LOTE  SEQUENCIA   ARQUIVO ORIGEM                                    NOME                           CEP');
  stlRelatorioObjRetidosAnalitico.Add('----- ----------- ------------------------------------------------- ------------------------------ --------');

  //====================================================================================
  //  CRIANDO ARQUIVO CIF
  //====================================================================================
    sComando := 'SELECT  * FROM ' + objParametrosDeEntrada.TABELA_PROCESSAMENTO
              + ' WHERE CEP_STATUS = "01" '
              + ' group by NUMERO_CARTAO, NUMERO_LOTE';
    objConexao.Executar_SQL(__queryMySQL_processamento__, sComando, 2);

   while not __queryMySQL_processamento__.Eof do
   Begin

     //====================================================================================
     //  DEFININDO O CAMINHO DO CIF
     //====================================================================================
     if StrToBoolDef(objParametrosDeEntrada.USAR_PATH_PERSONALIZADO_CIF, false) then
       sPathmovimentoCIF                := objString.AjustaPath(objParametrosDeEntrada.PATH_DEFAULT_ARQUIVOS_SAIDA_CIF + '_' + __queryMySQL_processamento__.FieldByName('PRODUTO').AsString)
                                        + __queryMySQL_processamento__.FieldByName('ANO_POSTAGEM').AsString
                                        + copy(__queryMySQL_processamento__.FieldByName('DATA_POSTAGEM').AsString, 3,2)
                                        + copy(__queryMySQL_processamento__.FieldByName('DATA_POSTAGEM').AsString, 1,2)
                                        + PathDelim
     else
       sPathmovimentoCIF                := objString.AjustaPath(objParametrosDeEntrada.PATHSAIDA) + 'CIF'        + PathDelim;

     ForceDirectories(sPathmovimentoCIF);
     //====================================================================================

     sNumeroCartao := __queryMySQL_processamento__.FieldByName('NUMERO_CARTAO').AsString;
     sLoteFAC      := __queryMySQL_processamento__.FieldByName('NUMERO_LOTE').AsString;

     sArquivoSaidaCIF := 'FAC_' + sNumeroCartao + '_' + sLoteFAC + '_UNICA';

     IF objParametrosDeEntrada.TESTE THEN
       sArquivoSaidaCIF := sArquivoSaidaCIF + '_TESTE';

     sArquivoSaidaCIF := sArquivoSaidaCIF + '.txt';

     AssignFile(Arq_Arquivo_Saida_CIF, sPathMovimentoCIF + sArquivoSaidaCIF);
     Rewrite(Arq_Arquivo_Saida_CIF);

     //========================================================================================
     //  CABECALHO DO ARQUIVO
     //========================================================================================
     sLinha := __queryMySQL_processamento__.FieldByName('NUMERO_CONTRATO').AsString
       + '|' + __queryMySQL_processamento__.FieldByName('NUMERO_CARTAO').AsString
       + '|' + __queryMySQL_processamento__.FieldByName('NUMERO_LOTE').AsString
       + '|' + __queryMySQL_processamento__.FieldByName('MCU_UNIDADE_POSTAGEM').AsString
       + '|' + __queryMySQL_processamento__.FieldByName('CEP_UNIDADE_POSTAGEM').AsString
       + '|' + __queryMySQL_processamento__.FieldByName('CODIGO_AVALIACAO_TECNICA').AsString
       + '|' + __queryMySQL_processamento__.FieldByName('CICLO_POSTAGEM').AsString
       + '|' + __queryMySQL_processamento__.FieldByName('ANO_POSTAGEM').AsString
       + '|' + __queryMySQL_processamento__.FieldByName('DNE_ATUALIZADO').AsString;

     writeln(Arq_Arquivo_Saida_CIF, sLinha);
     //========================================================================================

     //========================================================================================
     //  DETALHES DO ARQUIVO
     //========================================================================================
     sComando := 'SELECT  * FROM ' + objParametrosDeEntrada.TABELA_PROCESSAMENTO
               + ' WHERE NUMERO_CARTAO = "' + sNumeroCartao + '"'
               + '   AND NUMERO_LOTE   = "' + sLoteFAC + '"'
               + '   AND CEP_STATUS    = "01" '
               + ' ORDER BY SEQUENCIA_OBJETO ';
     objConexao.Executar_SQL(__queryMySQL_processamento2__, sComando, 2);

     while not __queryMySQL_processamento2__.Eof do
     Begin

       sLinha := __queryMySQL_processamento2__.FieldByName('SEQUENCIA_OBJETO').AsString
         + '|' + __queryMySQL_processamento2__.FieldByName('PESO').AsString
         + '|' + __queryMySQL_processamento2__.FieldByName('CODIGO_SERVICO').AsString
         + '|' + __queryMySQL_processamento2__.FieldByName('CODIGO_MULTIPLO').AsString
         + '|' + __queryMySQL_processamento2__.FieldByName('CODIGO_CONTEUDO').AsString
         + '|' + __queryMySQL_processamento2__.FieldByName('CODIGO_SERVICO_ADICIONAL').AsString
         + '|' + __queryMySQL_processamento2__.FieldByName('VALOR_DECLARADO').AsString
         + '|' + ''
         + '|' + ''
         + '|' + ''
         + '|' + ''
         + '|' + ''
         + '|' + ''
         + '|' + __queryMySQL_processamento2__.FieldByName('CEP_DESTINO').AsString;

         {*
         + '|' + ''
         + '|' + ''
         + '|' + ''
         + '|' + ''
         + '|' + ''
         + '|' + ''
         + '|' + ''
         + '|' + ''
         + '|' + ''
         + '|' + ''
         + '|' + ''
         + '|' + ''
         + '|' + ''
         + '|' + ''
         + '|' + ''
         + '|' + ''
         + '|' + ''
         + '|' + ''
         + '|' + ''
         + '|' + ''
         + '|' + ''
         + '|' + ''
         + objString.RepeteChar('|', 64);
         *}

         writeln(Arq_Arquivo_Saida_CIF, sLinha);

         __queryMySQL_processamento2__.Next;

     END;
     //========================================================================================


     //==================================================================================================================================
     //  RODAPÉ DO ARQUIVO
     //==================================================================================================================================
     sComando := 'SELECT  COUNT(NUMERO_LOTE) AS "QTD", SUM(PESO) AS "PESO" FROM ' + objParametrosDeEntrada.TABELA_PROCESSAMENTO
               + ' WHERE NUMERO_CARTAO = "' + sNumeroCartao + '"'
               + '   AND NUMERO_LOTE   = "' + sLoteFAC + '"'
               + '   AND CEP_STATUS    = "01" '
               + ' group by NUMERO_CARTAO, NUMERO_LOTE ';
     objConexao.Executar_SQL(__queryMySQL_processamento2__, sComando, 2);

     sLinha := FormatFloat('0000000', __queryMySQL_processamento2__.FieldByName('QTD').AsInteger)
       + '|' + FormatFloat('000000000000', __queryMySQL_processamento2__.FieldByName('PESO').AsInteger);
     writeln(Arq_Arquivo_Saida_CIF, sLinha);
     //==================================================================================================================================

     closefile(Arq_Arquivo_Saida_CIF);

     if StrToBoolDef(objParametrosDeEntrada.COMPACTAR_MIDIA, false) then
       COMPACTAR_ARQUIVO(sPathMovimentoCIF + sArquivoSaidaCIF, ExtractFilePath(sPathMovimentoCIF + sArquivoSaidaCIF), True, True);

     //========================================================================================
     //  Relação de objetos CIF retidos
     //========================================================================================
     sComando := 'SELECT  NUMERO_LOTE, SEQUENCIA_OBJETO, ARQUIVO, NOME_CLIENTE_ENDERECO, CEP_DESTINO, CEP_STATUS FROM ' + objParametrosDeEntrada.TABELA_PROCESSAMENTO
               + ' WHERE NUMERO_CARTAO = "' + sNumeroCartao + '"'
               + '   AND NUMERO_LOTE   = "' + sLoteFAC + '"'
               + '   AND CEP_STATUS    <> "01" '
               + ' ORDER BY SEQUENCIA_OBJETO ';
     objConexao.Executar_SQL(__queryMySQL_processamento2__, sComando, 2);

     while not __queryMySQL_processamento2__.Eof do
     Begin

       sLabelMotivoRetencao := 'RETIDO POR CEP INCONSISTENTE';

       stlRelatorioObjRetidosAnalitico.Add(
                                            __queryMySQL_processamento2__.FieldByName('NUMERO_LOTE').AsString
                                    + ' ' + __queryMySQL_processamento2__.FieldByName('SEQUENCIA_OBJETO').AsString
                                    + ' ' + objString.AjustaStr(__queryMySQL_processamento2__.FieldByName('ARQUIVO').AsString, 49)
                                    + ' ' + objString.AjustaStr(__queryMySQL_processamento2__.FieldByName('NOME_CLIENTE_ENDERECO').AsString, 30)
                                    + ' ' + objString.AjustaStr(__queryMySQL_processamento2__.FieldByName('CEP_DESTINO').AsString, 8)
                                    + ' ' + sLabelMotivoRetencao
                                   );
       __queryMySQL_processamento2__.Next;
     end;

     //========================================================================================

     __queryMySQL_processamento__.Next;
   end;
  //====================================================================================

  //===================================================================================================
  // CRIANDO RELATÓRIO DE QUANTIDADES
  //==================================================================================================================================================================
  stlRelatorio.Clear;
  sComando := 'SELECT MOVIMENTO, ARQUIVO, NUMERO_LOTE, DATA_POSTAGEM FROM ' + objParametrosDeEntrada.TABELA_PROCESSAMENTO
            + ' GROUP BY ARQUIVO, NUMERO_LOTE ';
  objConexao.Executar_SQL(__queryMySQL_processamento__, sComando, 2);

  sLinha := stringOfChar('-', 136)
  + #13 + #10 + 'RELATÓRIO DE QUANTIDADES - PROCESSAMENTO ' + sPathComplemento
  + #13 + #10 + stringOfChar('-', 136)
  + #13 + #10 + 'MOVIMENTO  ARQUIVO                                                               DATA DE POSTAGEM LOTE DE POSTAGEM QUANTIDADE MIDIA PESO MIDIA   QUANTIDADE RET   PESO RETIDOS'
  + #13 + #10 + '---------- --------------------------------------------------------------------- ---------------- ---------------- ---------------- ------------ ---------------- ------------';
  stlRelatorio.Add(sLinha);


  iTotalObjetosOk     := 0;
  iPesoTotalObjetosOk := 0;

  iTotalObjetosRetidos     := 0;
  iPesoTotalObjetosRetidos := 0;

  iTotalObjestos  := 0;
  iTotalPeso      := 0;

  while not __queryMySQL_processamento__.Eof do
  begin

    sComando := 'SELECT MOVIMENTO, ARQUIVO, DATA_POSTAGEM, NUMERO_LOTE, CEP_STATUS, COUNT(NUMERO_LOTE) AS "QTD", SUM(PESO) AS "PESO" FROM ' + objParametrosDeEntrada.TABELA_PROCESSAMENTO
              + ' WHERE ARQUIVO     = "' + __queryMySQL_processamento__.FieldByName('ARQUIVO').AsString + '"'
              + '   AND NUMERO_LOTE = "' + __queryMySQL_processamento__.FieldByName('NUMERO_LOTE').AsString + '"'
              + ' GROUP BY MOVIMENTO, ARQUIVO, DATA_POSTAGEM, NUMERO_LOTE, CEP_STATUS ';
    objConexao.Executar_SQL(__queryMySQL_processamento2__, sComando, 2);

    //============================================================================================================================================
    // APURA POR STATUS DE CEP
    //============================================================================================================================================
    iObjetosOk          := 0;
    iObjetosRetidos     := 0;

    iPesoObjetosOk      := 0;
    iPesoObjetosRetidos := 0;

    while not __queryMySQL_processamento2__.Eof do
    begin

      sCepStatus := __queryMySQL_processamento2__.FieldByName('CEP_STATUS').AsString;

      if sCepStatus = '01' then
      begin
        iObjetosOk     := iObjetosOk     + __queryMySQL_processamento2__.FieldByName('QTD').AsInteger;
        iPesoObjetosOk := iPesoObjetosOk + __queryMySQL_processamento2__.FieldByName('PESO').AsInteger;
      end
      else
      begin
        iObjetosRetidos     := iObjetosRetidos     + __queryMySQL_processamento2__.FieldByName('QTD').AsInteger;
        iPesoObjetosRetidos := iPesoObjetosRetidos + __queryMySQL_processamento2__.FieldByName('PESO').AsInteger;
      end;

      __queryMySQL_processamento2__.Next;
    END;
    //============================================================================================================================================

    sLinha := objString.AjustaStr(__queryMySQL_processamento__.FieldByName('MOVIMENTO').AsString, 10)
      + ' ' + objString.AjustaStr(__queryMySQL_processamento__.FieldByName('ARQUIVO').AsString, 69)
      + ' ' + objString.AjustaStr(__queryMySQL_processamento__.FieldByName('DATA_POSTAGEM').AsString, 16, 1)
      + ' ' + objString.AjustaStr(__queryMySQL_processamento__.FieldByName('NUMERO_LOTE').AsString, 16, 1)
      + ' ' + objString.AjustaStr(FormatFloat('0000000000', iObjetosOk), 16, 1)
      + ' ' + objString.AjustaStr(FormatFloat('0000000000', iPesoObjetosOk), 12, 1)
      + ' ' + objString.AjustaStr(FormatFloat('0000000000', iObjetosRetidos), 16, 1)
      + ' ' + objString.AjustaStr(FormatFloat('0000000000', iPesoObjetosRetidos), 12, 1)
      ;
    stlRelatorio.Add(sLinha);

    //=================================================================================================================================================================
    //  INSERE NA TABELA TRACK E CRIA CSV TRACK PRÉVIAS
    //=================================================================================================================================================================
    if not objParametrosDeEntrada.TESTE then
    begin
      sComando := 'INSERT INTO  ' + objParametrosDeEntrada.TABELA_TRACK
                + ' (ARQUIVO_TXT, LOTE, TIMESTAMP, LINHAS, OBJETOS, OBJ_VALIDO, OBJ_INVALIDO, PESO, STATUS_ARQUIVO, MOVIMENTO) '
                + ' VALUES("'
                +         __queryMySQL_processamento__.FieldByName('ARQUIVO').AsString
                + '","' + FormatFloat(objParametrosDeEntrada.FORMATACAO_LOTE_PEDIDO, StrToInt(objParametrosDeEntrada.PEDIDO_LOTE))
                + '","' + FormatDateTime('YYYY-MM-DD hh:mm:ss', objParametrosDeEntrada.TIMESTAMP)
                + '","' + IntToStr(iObjetosOk + iObjetosRetidos)
                + '","' + IntToStr(iObjetosOk + iObjetosRetidos)
                + '","' + IntToStr(iObjetosOk)
                + '","' + IntToStr(iObjetosRetidos)
                + '","' + IntToStr(iPesoObjetosOk + iPesoObjetosRetidos)
                + '","' + '0'
                + '","' + FormatDateTime('YYYYMMDD', objParametrosDeEntrada.MOVIMENTO)
                + '")'
                ;
      objConexao.Executar_SQL(__queryMySQL_Insert_, sComando, 1);
    end;

    //=================================================================================================================================================================

    iTotalObjetosOk          := iTotalObjetosOk          + iObjetosOk;
    iTotalObjetosRetidos     := iTotalObjetosRetidos     + iObjetosRetidos;

    iPesoTotalObjetosOk      := iPesoTotalObjetosOk      + iPesoObjetosOk;
    iPesoTotalObjetosRetidos := iPesoTotalObjetosRetidos + iPesoObjetosRetidos;


    iTotalObjestos  := iTotalObjestos  + iObjetosOk     + iObjetosRetidos;
    iTotalPeso      := iTotalPeso      + iPesoObjetosOk + iPesoObjetosRetidos;
    
    __queryMySQL_processamento__.Next;
  end;

  sLinha :=     '---------- --------------------------------------------------------------------- ---------------- ---------------- ---------------- ------------ ---------------- ------------'
  + #13 + #10 + stringOfChar(' ', 115) + objString.AjustaStr(FormatFloat('0000000000', iTotalObjetosOk), 16, 1)
                                 + ' ' + objString.AjustaStr(FormatFloat('0000000000', iPesoTotalObjetosOk), 12, 1)
                                 + ' ' + objString.AjustaStr(FormatFloat('0000000000', iTotalObjetosRetidos), 16, 1)
                                 + ' ' + objString.AjustaStr(FormatFloat('0000000000', iPesoTotalObjetosRetidos), 12, 1)
  + #13 + #10 + 'TOTAIS'
  + #13 + #10 + '---------------------'
  + #13 + #10 + 'QTD TOTAL  PESO TOTAL'
  + #13 + #10 + '---------- ----------'
  + #13 + #10 + FormatFloat('0000000000', iTotalObjestos) + ' ' + FormatFloat('0000000000', iTotalPeso);
  stlRelatorio.Add(sLinha);

  sArquivoREL := sPathMovimentoRelatorio + 'RELATORIO_DE_QUANTIDADES_' + FormatDateTime('YYYYMMDD', objParametrosDeEntrada.MOVIMENTO) +'.TXT';

  stlRelatorio.SaveToFile(sArquivoREL);
  objLogar.Logar(#13 + #10 + stlRelatorio.Text + #13 + #10);

  objFuncoesWin.ExecutarArquivoComProgramaDefault(sArquivoREL);

  //================================================================================================================================================
  // ARQUIVO DE OBJETOS RETIDOS
  //================================================================================================================================================
  IF stlRelatorioObjRetidosAnalitico.Count > 2 THEN
  Begin
    sArquivoREL := sPathMovimentoRelatorio + 'RELATORIO_DE_OBJETOS_RETIDOS_' + FormatDateTime('YYYYMMDD', objParametrosDeEntrada.MOVIMENTO) +'.TXT';

    stlRelatorioObjRetidosAnalitico.SaveToFile(sArquivoREL);
    objLogar.Logar(#13 + #10 + stlRelatorio.Text + #13 + #10);

    objFuncoesWin.ExecutarArquivoComProgramaDefault(sArquivoREL);
  End;
  //================================================================================================================================================

  //objFuncoesWin.DelTree(sPathMovimentoTMP);
  //==================================================================================================================================================================


  objLogar.Logar('');


end;

procedure TCore.Atualiza_arquivo_conf_C(ArquivoConf, sINP, sOUT, sTMP, sLOG, sRGP: String);
var
  txtEntrada       : TextFile;
  sLinha           : string;
  sParametro       : string;
  stlArquivoConfC  : TStringList;
  sPathSaidaAFP    : string;
begin


  stlArquivoConfC := TStringList.Create();

  AssignFile(txtEntrada, ArquivoConf);
  Reset(txtEntrada);

  while not Eof(txtEntrada) do
  begin

    Readln(txtEntrada, sLinha);

    sParametro := AnsiUpperCase(Trim(objString.getTermo(1, '=', sLinha)));

    if sParametro = 'INP' then
      stlArquivoConfC.Add(sParametro + '=' + sINP);

    if sParametro = 'OUT' then
      stlArquivoConfC.Add(sParametro + '=' + sOUT);

    if sParametro = 'TMP' then
      stlArquivoConfC.Add(sParametro + '=' + sTMP);

    if sParametro = 'LOG' then
      stlArquivoConfC.Add(sParametro + '=' + sLOG);

    if sParametro = 'RGP' then
      stlArquivoConfC.Add(sParametro + '=' + sRGP);

  end;

  CloseFile(txtEntrada);

  stlArquivoConfC.SaveToFile(ArquivoConf);

end;

procedure TCore.execulta_app_c(app, arquivo_conf: string);
begin
  objFuncoesWin.ExecutarPrograma(app + ' "' + arquivo_conf + '"');
end;

function TCore.ArquivoExieteTabelaTrack(Arquivo: string): Boolean;
var
  sComando: string;
begin

  sComando := 'SELECT ARQUIVO_TXT FROM ' + objParametrosDeEntrada.TABELA_TRACK
            + ' WHERE ARQUIVO_TXT = "' + Arquivo + '" ';
  objConexao.Executar_SQL(__queryMySQL_processamento__, sComando, 2);

  if __queryMySQL_processamento__.RecordCount > 0 then
   Result := True
  else
    Result := False;

end;

procedure TCore.getListaDeArquivosJaProcessados();
var
  sComando                   : string;
  sLinha                     : string;
begin

  sComando := 'SELECT * FROM ' + objParametrosDeEntrada.TABELA_TRACK
            + ' WHERE STATUS_ARQUIVO = "0" '
            + ' ORDER BY MOVIMENTO DESC';
  objConexao.Executar_SQL(__queryMySQL_processamento__, sComando, 2);

  objParametrosDeEntrada.STL_LISTA_ARQUIVOS_JA_PROCESSADOS.Clear;

  WHILE NOT __queryMySQL_processamento__.Eof do
  BEGIN

    sLinha := __queryMySQL_processamento__.FieldByName('MOVIMENTO').AsString
    + ' - ' + __queryMySQL_processamento__.FieldByName('ARQUIVO_TXT').AsString;
//    + ' - ' + __queryMySQL_processamento__.FieldByName('ARQUIVO_TXT').AsString;

    objParametrosDeEntrada.STL_LISTA_ARQUIVOS_JA_PROCESSADOS.Add(sLinha);

    __queryMySQL_processamento__.Next;
  end;

end;

procedure TCore.ReverterArquivos();
var
  iContArquivos                       : Integer;
  sArquivoReverter                    : string;
  sComando                            : string;

begin

  for iContArquivos := 0 to objParametrosDeEntrada.STL_LISTA_ARQUIVOS_REVERTER.Count - 1 do
  begin

    sArquivoReverter := objParametrosDeEntrada.STL_LISTA_ARQUIVOS_REVERTER.Strings[iContArquivos];

    //=========================================================================
    //  REVERTE TABEL TRACK
    //=========================================================================
    sComando := 'DELETE FROM ' + objParametrosDeEntrada.TABELA_TRACK
              + ' WHERE ARQUIVO_TXT = "' + sArquivoReverter + '" ';
    objConexao.Executar_SQL(__queryMySQL_processamento__, sComando, 1);

    //=========================================================================
    //  REVERTE TABEL TRACK LINE
    //=========================================================================
    sComando := 'DELETE FROM ' + objParametrosDeEntrada.TABELA_TRACK_LINE
              + ' WHERE ARQUIVO_TXT = "' + sArquivoReverter + '" ';
    objConexao.Executar_SQL(__queryMySQL_processamento__, sComando, 1);

  end;

end;

end.
