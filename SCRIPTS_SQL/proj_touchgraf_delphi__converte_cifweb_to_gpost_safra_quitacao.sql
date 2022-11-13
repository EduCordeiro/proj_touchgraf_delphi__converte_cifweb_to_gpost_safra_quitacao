CREATE DATABASE IF NOT EXISTS proj_touchgraf_delphi__converte_cifweb_to_gpost_safra_quitacao;

DROP TABLE IF EXISTS proj_touchgraf_delphi__converte_cifweb_to_gpost_safra_quitacao.debug_sql;
CREATE TABLE IF NOT EXISTS proj_touchgraf_delphi__converte_cifweb_to_gpost_safra_quitacao.debug_sql (
  interacoes varchar(10) default NULL,
  inte varchar(10) default NULL,
  reg_lidos varchar(10) default NULL,
  timestamp varchar(20) default NULL
);

DROP TABLE IF EXISTS proj_touchgraf_delphi__converte_cifweb_to_gpost_safra_quitacao.processamento;
CREATE TABLE IF NOT EXISTS proj_touchgraf_delphi__converte_cifweb_to_gpost_safra_quitacao.processamento (
   SEQUENCIA                  INTEGER
  ,NOME_CLIENTE_ENDERECO      varchar(030) default NULL
  ,NUMERO_CONTRATO            varchar(010) default NULL
  ,NUMERO_CARTAO              varchar(010) default NULL
  ,NUMERO_LOTE                varchar(010) default NULL
  ,MCU_UNIDADE_POSTAGEM       varchar(008) default NULL
  ,CEP_UNIDADE_POSTAGEM       varchar(008) default NULL
  ,CODIGO_AVALIACAO_TECNICA   varchar(008) default NULL
  ,CICLO_POSTAGEM             varchar(002) default NULL
  ,ANO_POSTAGEM               varchar(004) default NULL
  ,DNE_ATUALIZADO             varchar(001) default NULL
  ,SEQUENCIA_OBJETO           varchar(011) default NULL
  ,PESO                       varchar(006) default NULL
  ,CODIGO_SERVICO             varchar(005) default NULL
  ,CODIGO_MULTIPLO            varchar(001) default NULL
  ,CODIGO_CONTEUDO            varchar(002) default NULL
  ,CODIGO_SERVICO_ADICIONAL   varchar(003) default NULL
  ,VALOR_DECLARADO            varchar(010) default NULL
  ,CEP_DESTINO                varchar(008) default NULL
  ,CEP_STATUS                 varchar(008) default NULL  
  ,DATA_POSTAGEM              varchar(006) default NULL
  ,MOVIMENTO                  varchar(008) default NULL
  ,ARQUIVO                    varchar(100) default NULL
  ,PRODUTO                    varchar(100) default NULL
);

drop table if exists proj_touchgraf_delphi__converte_cifweb_to_gpost_safra_quitacao.tbl_entrada;
create table proj_touchgraf_delphi__converte_cifweb_to_gpost_safra_quitacao.tbl_entrada(
  seq int auto_increment,
  tipo_reg varchar(2),
  OPERADORA varchar(3),
  CONTRATO varchar(9),
  arquivo varchar(100),
  textolinha VARCHAR(959),
  PRIMARY KEY(seq)
);
/*CREATE INDEX idx_tbl_entrada ON proj_touchgraf_delphi__converte_cifweb_to_gpost_safra_quitacao.tbl_entrada (seq, tipo_reg, OPERADORA, CONTRATO, arquivo);*/


/*
===============================================================================================================================================
                                          CICLO_POSTAGEM_FAC
===============================================================================================================================================
*/
drop table if exists proj_touchgraf_delphi__converte_cifweb_to_gpost_safra_quitacao.CICLO_POSTAGEM_FAC;
CREATE TABLE IF NOT EXISTS proj_touchgraf_delphi__converte_cifweb_to_gpost_safra_quitacao.CICLO_POSTAGEM_FAC (
  MES                  varchar(5)            NOT NULL,
  CICLO                varchar(5)            NOT NULL,
  PRIMARY KEY (MES),
  KEY idx_codigo_servico_fac (MES)
);

insert into proj_touchgraf_delphi__converte_cifweb_to_gpost_safra_quitacao.CICLO_POSTAGEM_FAC values("01", "01");
insert into proj_touchgraf_delphi__converte_cifweb_to_gpost_safra_quitacao.CICLO_POSTAGEM_FAC values("02", "01");
insert into proj_touchgraf_delphi__converte_cifweb_to_gpost_safra_quitacao.CICLO_POSTAGEM_FAC values("03", "02");
insert into proj_touchgraf_delphi__converte_cifweb_to_gpost_safra_quitacao.CICLO_POSTAGEM_FAC values("04", "02");
insert into proj_touchgraf_delphi__converte_cifweb_to_gpost_safra_quitacao.CICLO_POSTAGEM_FAC values("05", "03");
insert into proj_touchgraf_delphi__converte_cifweb_to_gpost_safra_quitacao.CICLO_POSTAGEM_FAC values("06", "03");
insert into proj_touchgraf_delphi__converte_cifweb_to_gpost_safra_quitacao.CICLO_POSTAGEM_FAC values("07", "04");
insert into proj_touchgraf_delphi__converte_cifweb_to_gpost_safra_quitacao.CICLO_POSTAGEM_FAC values("08", "04");
insert into proj_touchgraf_delphi__converte_cifweb_to_gpost_safra_quitacao.CICLO_POSTAGEM_FAC values("09", "05");
insert into proj_touchgraf_delphi__converte_cifweb_to_gpost_safra_quitacao.CICLO_POSTAGEM_FAC values("10", "05");
insert into proj_touchgraf_delphi__converte_cifweb_to_gpost_safra_quitacao.CICLO_POSTAGEM_FAC values("11", "06");
insert into proj_touchgraf_delphi__converte_cifweb_to_gpost_safra_quitacao.CICLO_POSTAGEM_FAC values("12", "06");
/*
==============================================================================================================================================
*/


/*DROP TABLE IF EXISTS proj_touchgraf_delphi__converte_cifweb_to_gpost_safra_quitacao.controle_arquivos;*/
CREATE TABLE IF NOT EXISTS proj_touchgraf_delphi__converte_cifweb_to_gpost_safra_quitacao.controle_arquivos (
  LOTE                 int(10)      unsigned NOT NULL,
  DATA_INSERSAO        datetime              NOT NULL,
  ARQUIVO              varchar(100)          NOT NULL,
  PAGINAS              varchar(010)          NOT NULL,
  OBJETOS              varchar(010)          NOT NULL,
  PRIMARY KEY (LOTE, ARQUIVO),
  KEY idx_controle_arquivo (ARQUIVO)
);


DROP TABLE IF EXISTS proj_touchgraf_delphi__converte_cifweb_to_gpost_safra_quitacao._AUX_;
create table proj_touchgraf_delphi__converte_cifweb_to_gpost_safra_quitacao._aux_(
    seq int auto_increment,
    tipo_reg varchar(2),
    OPERADORA varchar(3),
    CONTRATO varchar(9),
    CEP VARCHAR(8),
    FLAG_EMAIL VARCHAR(1),
    FLAG_STATUS VARCHAR(1),
    arquivo varchar(100),
    textolinha VARCHAR(959),
    PRIMARY KEY(seq)
);
/*CREATE INDEX idx___aux__ ON proj_touchgraf_delphi__converte_cifweb_to_gpost_safra_quitacao._AUX_ (seq, tipo_reg, OPERADORA, CONTRATO, CEP, FLAG_EMAIL, FLAG_STATUS);*/

CREATE TABLE IF NOT EXISTS proj_touchgraf_delphi__converte_cifweb_to_gpost_safra_quitacao.LOTES_PEDIDOS (
  LOTE_PEDIDO      int     NOT NULL auto_increment,
  VALIDO           CHAR(1) NOT NULL default 'N',

  DATA_CRIACAO     DATETIME,
  CHAVE            VARCHAR(17),
  ID               VARCHAR(17),
  USUARIO_WIN      VARCHAR(20),
  USUARIO_APP      VARCHAR(20),
  IP               VARCHAR(14),
  LOTE_LOGIN       INT,

  RELATORIO_QTD    MEDIUMBLOB,
  HOSTNAME         varchar(15),
  PRIMARY KEY  (LOTE_PEDIDO)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

DROP TABLE IF EXISTS proj_touchgraf_delphi__converte_cifweb_to_gpost_safra_quitacao.tbl_blocagem;

CREATE TABLE IF NOT EXISTS proj_touchgraf_delphi__converte_cifweb_to_gpost_safra_quitacao.tbl_blocagem(
  linha VARCHAR(5000),
  diconix integer,
  numeroDaImagem integer,
  lote integer,
  sequencia integer
) CHARACTER SET latin1 COLLATE latin1_swedish_ci;

CREATE INDEX idx_blocagem ON proj_touchgraf_delphi__converte_cifweb_to_gpost_safra_quitacao.tbl_blocagem (Diconix, numeroDaImagem, lote, sequencia);

CREATE TABLE IF NOT EXISTS proj_touchgraf_delphi__converte_cifweb_to_gpost_safra_quitacao.tbl_blocagemRelatorio(
  id BIGINT AUTO_INCREMENT,
  data VARCHAR(10),
  duracao VARCHAR(50),
  arquivo VARCHAR(600),
  tamanhoArquivo VARCHAR(50),
  qtdeImagensNoArquivo BIGINT,
  parQtdeImagensBlocagem BIGINT, 
  parBlocagem BIGINT, 
  saidaQtdeLotesComBlocagemPadrao BIGINT,
  saidaSobra BIGINT, 
  saidaBlocagemParaSobra BIGINT, 
  saidaQtdeImagensDesperdicadas BIGINT,
  PRIMARY KEY(id)
) CHARACTER SET latin1 COLLATE latin1_swedish_ci;

CREATE TABLE IF NOT EXISTS proj_touchgraf_delphi__converte_cifweb_to_gpost_safra_quitacao.track (
  ARQUIVO_ZIP              VARCHAR(60) NOT NULL,
  ARQUIVO_AFP              VARCHAR(60) NOT NULL,
  ARQUIVO_TXT              VARCHAR(60) NOT NULL,
  LOTE                     INT(11) NOT NULL,
  TIMESTAMP                DATETIME NOT NULL,
  LINHAS                   INT(11) NOT NULL DEFAULT '0',
  OBJETOS                  INT(11) NOT NULL DEFAULT '0',
  FOLHAS                   INT(11) NOT NULL DEFAULT '0',
  PAGINAS                  INT(11) NOT NULL DEFAULT '0',
  PESO                     INT(11) NOT NULL DEFAULT '0',
  OBJ_VALIDO               INT(11) NOT NULL DEFAULT '0',
  OBJ_INVALIDO             INT(11) NOT NULL DEFAULT '0',
  STATUS_ARQUIVO           INT(11) NOT NULL DEFAULT '0',
  MOVIMENTO                VARCHAR(8) NOT NULL,
  PRIMARY KEY  (ARQUIVO_ZIP, ARQUIVO_AFP,ARQUIVO_TXT)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;


CREATE TABLE IF NOT EXISTS proj_touchgraf_delphi__converte_cifweb_to_gpost_safra_quitacao.track_line (
  ARQUIVO_ZIP            VARCHAR(60) NOT NULL,
  ARQUIVO_AFP            VARCHAR(60) NOT NULL,
  ARQUIVO_TXT            VARCHAR(60) NOT NULL,
  SEQUENCIA_REGISTRO     INT(11) NOT NULL,
  TIMESTAMP              DATETIME NOT NULL,
  LOTE_PROCESSAMENTO     INT(11) NOT NULL,
  MOVIMENTO              VARCHAR(8) NOT NULL,
  ACABAMENTO             VARCHAR(20) NOT NULL,
  PAGINAS                INT(11) NOT NULL DEFAULT '0',
  FOLHAS                 INT(11) NOT NULL DEFAULT '0',
  ENCARTES               INT(11) NOT NULL DEFAULT '0',
  OF_ENVELOPE            VARCHAR(15) NOT NULL,
  OF_FORMULARIO          VARCHAR(15) NOT NULL,
  DATA_POSTAGEM          VARCHAR(10) NOT NULL,
  LOTE                   VARCHAR(5) NOT NULL,
  CARTAO                 VARCHAR(12) NOT NULL,
  CIF                    VARCHAR(34) NOT NULL,
  PESO                   VARCHAR(10) NOT NULL,
  DIRECAO                INT(11) NOT NULL,
  CATEGORIA              INT(11) NOT NULL,
  PORTE                  INT(11) NOT NULL,
  STATUS_REGISTRO        VARCHAR(20) NOT NULL,
  PAPEL                  VARCHAR(10) NOT NULL,
  TIPO_DOCUMENTO         VARCHAR(10) NOT NULL,
  LINHA                  TEXT,
  PRIMARY KEY  (ARQUIVO_ZIP,ARQUIVO_AFP,ARQUIVO_TXT,SEQUENCIA_REGISTRO)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS proj_touchgraf_delphi__converte_cifweb_to_gpost_safra_quitacao.track_line_history (
  ARQUIVO_ZIP            VARCHAR(60) NOT NULL,
  ARQUIVO_AFP            VARCHAR(60) NOT NULL,
  ARQUIVO_TXT            VARCHAR(60) NOT NULL,
  SEQUENCIA_REGISTRO     INT(11) NOT NULL,
  TIMESTAMP              DATETIME NOT NULL,
  LOTE_PROCESSAMENTO     INT(11) NOT NULL,
  MOVIMENTO              VARCHAR(8) NOT NULL,
  ACABAMENTO             VARCHAR(20) NOT NULL,
  PAGINAS                INT(11) NOT NULL DEFAULT '0',
  FOLHAS                 INT(11) NOT NULL DEFAULT '0',
  ENCARTES               INT(11) NOT NULL DEFAULT '0',
  OF_ENVELOPE            VARCHAR(15) NOT NULL,
  OF_FORMULARIO          VARCHAR(15) NOT NULL,
  DATA_POSTAGEM          VARCHAR(10) NOT NULL,
  LOTE                   VARCHAR(5) NOT NULL,
  CARTAO                 VARCHAR(12) NOT NULL,
  CIF                    VARCHAR(34) NOT NULL,
  PESO                   VARCHAR(10) NOT NULL,
  DIRECAO                INT(11) NOT NULL,
  CATEGORIA              INT(11) NOT NULL,
  PORTE                  INT(11) NOT NULL,
  STATUS_REGISTRO        VARCHAR(20) NOT NULL,
  PAPEL                  VARCHAR(10) NOT NULL,
  TIPO_DOCUMENTO         VARCHAR(10) NOT NULL,
  LINHA                  TEXT,  
  PRIMARY KEY  (ARQUIVO_ZIP,ARQUIVO_AFP,ARQUIVO_TXT,SEQUENCIA_REGISTRO)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

