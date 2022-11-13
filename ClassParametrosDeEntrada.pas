Unit ClassParametrosDeEntrada;

interface

  uses Classes, Dialogs, SysUtils, Forms, Controls, Graphics,
  StdCtrls, ComCtrls;

  type
    TRetorno = record
      bStatus : Boolean;
      sMSG    : string;
      iValor  : Integer;
      sValor  : String;
    end;

  type
    TParametrosDeEntrada= Class
      // Propriedades da Classe ClassParametrosDeEntrada
      HORA_INICIO_PROCESSO                       : TDateTime;
      HORA_FIM_PROCESSO                          : TDateTime;
      INFORMACAO_DOS_ARQUIVOS_SELECIONADOS       : string;

      ID_PROCESSAMENTO                           : STRING;
      LISTADEARQUIVOSDEENTRADA                   : TSTRINGS;
      PATHENTRADA                                : STRING;
      PATHSAIDA                                  : STRING;
      PATHARQUIVO_TMP                            : STRING;

      PATH_TRACK                                 : STRING;

      TABELA_PROCESSAMENTO                       : STRING;
      TABELA_LOTES_PEDIDOS                       : STRING;
      TABELA_PLANO_DE_TRIAGEM                    : STRING;
      CARREGAR_PLANO_DE_TRIAGEM_MEMORIA          : STRING;
      TABELA_BLOCAGEM_INTELIGENTE                : STRING;
      TABELA_BLOCAGEM_INTELIGENTE_RELATORIO      : STRING;

      TABELA_ENTRADA_SP                          : STRING;
      TABELA_AUX_SP                              : STRING;

      TABELA_TRACK                               : STRING;
      TABELA_TRACK_LINE                          : STRING;
      TABELA_TRACK_LINE_HISTORY                  : STRING;

      TABELA_CICLO_POSTAGEM_FAC                  : STRING;

      NUMERO_DE_IMAGENS_PARA_BLOCAGENS           : STRING;
      BLOCAGEM                                   : STRING;
      BLOCAR_ARQUIVO                             : STRING;
      MANTER_ARQUIVO_ORIGINAL                    : STRING;

      LIMITE_DE_SELECT_POR_INTERACOES_NA_MEMORIA : string;

      PEDIDO_LOTE                                : string;
      FORMATACAO_LOTE_PEDIDO                     : string;
      lista_de_caracteres_invalidos              : string;

      ENVIAR_EMAIL                               : string;

      EXTENCAO_ARQUIVOS                          : string;

      COPIAR_LOG_PARA_SAIDA                      : Boolean;

      TESTE                                      : Boolean;
      CRIAR_CSV_TRACK                            : Boolean;

      APP_C_GERA_IDX_EXE                         : string;
      APP_C_GERA_IDX_CFG                         : string;

      DIAS_PARA_POSTAGEM_APOS_PROCESSAMENTO      : string;

      MOVIMENTO                                  : Double;
      DATA_POSTAGEM                              : Double;
      TIMESTAMP                                  : Double;

      DEFINIR_DATA_POSTAGEM                      : Boolean;

      TEM_ARQUIVO_RETENCAO                       : Boolean;

      STL_SP001                                  : TStringList; // Stored Procedure
      STL_SP002                                  : TStringList; // Stored Procedure
      STL_SP003                                  : TStringList; // Stored Procedure

      STL_LISTA_ARQUIVOS_JA_PROCESSADOS          : TStringList; // Stored Procedure
      STL_LISTA_ARQUIVOS_REVERTER                : TStringList; // Stored Procedure

      SP_001                                     : string;
      SP_002                                     : string;
      SP_003                                     : string;

      SP_001_NAME                                : string;
      SP_002_NAME                                : string;
      SP_003_NAME                                : string;

      app_7z_32bits                              : string;
      app_7z_64bits                              : string;
      ARQUITETURA_WINDOWS                        : string;

      stlRelatorioQTDE                           : TStringList;
      PEDIDO_LOTE_TMP                            : string; // USADO PARA SALVAR RELATORIO

      rStatus                                    : TRetorno;

      LOGAR                                      : STRING;

      NUMERO_CONTRATO                            : STRING;
      CODIGO_UNIDADE_POSTAGEM                    : STRING;
      CEP_UNIDADE_POSTAGEM                       : STRING;
      CODIGO_AVALIACAO_TECNICA                   : STRING;
      DNE_ATUALIZADO                             : STRING;


      NUMERO_CARTAO                              : STRING;
      CODIGO_MUTIPLO                             : STRING;
      CODIGO_CONTEUDO                            : STRING;
      CODIGO_SERVICO_ADICIONAL                   : STRING;
      VALOR_DECLARADO                            : STRING;

      PESO                                       : STRING;

      FAC_SIMPLES_LOCAL                          : STRING;
      FAC_SIMPLES_ESTADUAL                       : STRING;
      FAC_SIMPLES_NACIONAL                       : STRING;

      COMPACTAR_MIDIA                            : STRING;
      USAR_PATH_PERSONALIZADO_CIF                : STRING;
      PATH_DEFAULT_ARQUIVOS_SAIDA_CIF            : STRING;      

      //================
      //    HOSTNAME
      //================
      HOSTNAME                                  : STRING;
      IP                                        : STRING;
      USUARIO_SO                                : STRING;

      //================
      //  LOGA USU�RIO
      //=======================================================
      APP_LOGAR                                  : STRING;
      USUARIO_LOGADO_APP                         : STRING;
      STL_ARQUIVO_USUARIO_LOGADO                 : TStringList;
      TOTAL_PROCESSADOS_LOG                      : Integer;
      TOTAL_PROCESSADOS_INVALIDOS_LOG            : Integer;
      //=======================================================

      //=========================================================
      //  CHAVES PARA ENCONTRAR REGISTRO NA TABELA LOGAR E LOTES
      //=========================================================
      //APP_LOGAR_USUARIO_LOGADO_APP               : STRING;
      APP_LOGAR_CHAVE_APP                        : STRING;
      APP_LOGAR_LOTE                             : STRING;
      APP_LOGAR_USUARIO_LOGADO_WIN               : STRING;
      APP_LOGAR_IP                               : STRING;
      APP_LOGAR_ID                               : STRING;

      TABELA_LOTES_PEDIDOS_LOGIN                 : STRING;
      STL_LOG_TXT                                : TStringList;
      STATUS_PROCESSAMENTO                       : STRING;

      APP_LOGAR_PARAMETRO_TAB_INDEX              : STRING;
      APP_LOGAR_PARAMETRO_NOME_APLICACAO         : STRING;
      APP_LOGAR_PARAMETRO_ARQUIVO_LOGAR          : STRING;      
      //===================================================      

      // Par�metros para o envio de e-mail
      eHost                                    : string;
      eUser                                    : string;
      eFrom                                    : string;
      eTo                                      : string;      

    end;

implementation


End.
