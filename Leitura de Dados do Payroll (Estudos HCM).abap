REPORT z_algj_43.

TYPE-POOLS: slis.

TABLES: pa0001.

TYPES:

  BEGIN OF type_pa0001,
    pernr TYPE pa0001-pernr,
    subty TYPE pa0001-subty,
    objps TYPE pa0001-objps,
    sprps TYPE pa0001-sprps,
    endda TYPE pa0001-endda,
    begda TYPE pa0001-begda,
    seqnr TYPE pa0001-seqnr,
    abkrs TYPE pa0001-abkrs,
    orgeh TYPE pa0001-orgeh,
    ename TYPE pa0001-ename,
  END OF type_pa0001,

  BEGIN OF type_saida,
    sno   TYPE  i,
    orgeh TYPE pa0001-orgeh,
    ortx  TYPE t527x-orgtx,
    pernr TYPE pa0001-pernr,
    ename TYPE pa0001-ename,
    lgart TYPE pa0008-lga01,
    betgr TYPE netwr,
  END OF type_saida.

DATA:
  i_pa0001  TYPE TABLE OF type_pa0001,
  it_rgdir  TYPE TABLE OF pc261,
  i_rgdir   TYPE TABLE OF pc261,
  it_output TYPE TABLE OF type_saida.

DATA:
  fs_pa0001 TYPE type_pa0001,
  fs_rgdir  TYPE pc261.

DATA:
  v_begda TYPE begda,
  v_endda TYPE endda,
  v_atext TYPE t549t-atext,
  v_error TYPE c.


DATA:
  v_mname(15),
  v_mmane(20).

CONSTANTS:
           c_x TYPE char1 VALUE 'X'.

SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE text-001.
PARAMETERS: p_abkrs TYPE pa0001-abkrs OBLIGATORY.
SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 01(20) text-002 FOR FIELD p_month1.
SELECTION-SCREEN POSITION 33.
PARAMETERS: p_month1(2) TYPE n OBLIGATORY,
            p_fyear1(4) TYPE n  OBLIGATORY.
SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN END OF BLOCK b1.

AT SELECTION-SCREEN ON p_month1.
  IF p_month1 > '12'.
    MESSAGE 'Insira um Periodo Válido!' TYPE 'S' DISPLAY LIKE 'E'.
  ENDIF.

AT SELECTION-SCREEN ON p_abkrs.
  PERFORM validate_payroll_area.

START-OF-SELECTION.
  PERFORM get_period.
  PERFORM get_perns.

END-OF-SELECTION.
FORM get_perns.

  FIELD-SYMBOLS: <payresult>    TYPE any,
                 <lv_payresult> TYPE h99_clst_s_payresult,
                 <lv_versc>     TYPE pc202,
                 <li_rt>        TYPE hrpay99_rt,
                 <li_ddntk>     TYPE hrpay99_ddntk.

  DATA: lfs_rt        TYPE pc207,
        lfs_ddntk     TYPE pc23e,
        lv_relid      TYPE  relid_pcl,
        lv_type       TYPE t52relid-typename,
        lv_typename   TYPE hrpclx_type,
        ref_payresult TYPE REF TO data,
        lv_molga      TYPE molga,
        lv_type_1     TYPE tadir-obj_name,
        lv_tadir      TYPE tadir-obj_name,
        lv_unpaid     TYPE ktsol,
        lv_paid       TYPE ktsol.

  SELECT pernr
         subty
         objps
         sprps
         endda
         begda
         seqnr
         abkrs
         orgeh
         ename
    FROM pa0001
    INTO TABLE i_pa0001
   WHERE endda => v_begda
     AND begda <= v_endda
     AND abkrs = p_abkrs.

  IF sy-subrc <> 0.
    MESSAGE 'Nenhum Empregado Ativo para o Periodo!' TYPE 'S' DISPLAY LIKE 'E'.
    v_error = c_x.
    STOP.
  ENDIF.

  SORT: i_pa0001 BY pernr
                    begda.
  DELETE ADJACENT DUPLICATES FROM i_pa0001 COMPARING pernr.
  SORT: i_pa0001 BY orgeh
                    pernr.

  LOOP AT i_pa0001 INTO fs_pa0001.
    REFRESH: it_rgdir,
             i_rgdir.

    CLEAR fs_rgdir.

    CALL FUNCTION 'CU_READ_RGDIR'
      EXPORTING
        persnr          = fs_pa0001-pernr
      TABLES
        in_rgdir        = it_rgdir
      EXCEPTIONS
        no_record_found = 1
        OTHERS          = 2.
    IF sy-subrc = 0.

      CALL FUNCTION 'PYXX_GET_RELID_FROM_PERNR'
        EXPORTING
          employee                    = fs_pa0001-pernr
        IMPORTING
          relid                       = lv_relid
          molga                       = lv_molga
        EXCEPTIONS
          error_reading_infotype_0001 = 1
          error_reading_molga         = 2
          error_reading_relid         = 3
          OTHERS                      = 4.
      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.

    ENDIF. "IF sy-subrc <> 0. Da Primeira Função

    SELECT SINGLE typename
      FROM t52relid
      INTO lv_type
     WHERE relid   = lv_relid
       AND tabname = 'PCL2'.

    IF sy-subrc <> 0.
      lv_relid = 'IN'.
      lv_type  = 'PAYIN_RESULT'.
    ENDIF.

    lv_typename = lv_type.
    CREATE DATA ref_payresult TYPE (lv_typename).
    ASSIGN ref_payresult->* TO <payresult>.
    DELETE it_rgdir WHERE srtza = 'A'.

    LOOP AT it_rgdir INTO fs_rgdir WHERE payty = ''
                                     AND fpbeg => v_begda
                                     AND fpend <= v_endda.
      APPEND fs_rgdir TO i_rgdir.
    ENDLOOP.

    SORT i_rgdir BY seqnr.
    CLEAR: lv_unpaid,
           lv_paid.

    LOOP AT i_rgdir INTO fs_rgdir.

      CALL FUNCTION 'PYXX_READ_PAYROLL_RESULT'
        EXPORTING
          clusterid                    = lv_relid
          employeenumber               = fs_pa0001-pernr
          sequencenumber               = fs_rgdir-seqnr
        CHANGING
          payroll_result               = <payresult>
        EXCEPTIONS
          illegal_isocode_or_clusterid = 1
          error_generating_import      = 2
          import_mismatch_error        = 3
          subpool_dir_full             = 4
          no_read_authority            = 5
          no_record_found              = 6
          versions_do_not_match        = 7
          error_reading_archive        = 8
          error_reading_relid          = 9
          OTHERS                       = 10.
      IF sy-subrc = 0.
        ASSIGN COMPONENT 'INTER-RT' OF STRUCTURE <payresult> TO <li_rt>.

    SKIP 2.
    FORMAT RESET.
    WRITE: /01 'Nº pessoal:',15 fs_pa0001-pernr.

    SKIP 2.

    FORMAT COLOR 7 INTENSIFIED ON.
    WRITE: sy-uline(65).
    WRITE: /01 sy-vline,
            02 'Rubrica salarial',
            29 sy-vline,
            30 'Cálculo das folhas de pagamento',
            65 sy-vline.

        LOOP AT <li_rt> INTO lfs_rt.

          FORMAT RESET.
          FORMAT COLOR 7 INTENSIFIED OFF.
          WRITE: /01 sy-vline,
                  02 lfs_rt-lgart,
                  29 sy-vline,
                  30 lfs_rt-betrg,
                  65 sy-vline.
        ENDLOOP.

        WRITE: /01 sy-uline(65).

      ENDIF.


    ENDLOOP.

  ENDLOOP.



ENDFORM. "FORM get_perns

FORM get_period.

  SELECT SINGLE begda
                endda
    FROM t549q
    INTO (v_begda, v_endda)
   WHERE permo = '01'
     AND pabrj = p_fyear1
     AND pabrp = p_month1.

  IF sy-subrc <> 0.
    MESSAGE 'Erro no Periodo Calculado' TYPE 'S' DISPLAY LIKE 'E'.
    v_error = 'X'.
    STOP.
  ENDIF.
ENDFORM.

FORM validate_payroll_area.

  DATA: lv_abkrs TYPE t549a-abkrs.

  SELECT SINGLE abkrs
    FROM t549a
    INTO lv_abkrs
   WHERE abkrs EQ p_abkrs.

  IF sy-subrc <> 0.
    MESSAGE 'Entre com um Payroll area valido' TYPE 'S' DISPLAY LIKE 'E'.
  ENDIF.
ENDFORM.
