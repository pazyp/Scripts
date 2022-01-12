--
-- Run this before to get an idea of the sizes of things prior to the task
--
set lines 140 pages 9999
column table_owner format a10 truncate
column index_owner format a10 truncate
column table_name format a30
column index_name format a30
column columns format a30 word_wrapped
column index_uniqueness format a3 heading "UK?"

column int        format 999,999
column table_megs like int
column index_megs like int

compute sum of index_megs on report
compute sum of table_megs on report
break on table_owner on table_name on index_owner on report

define table_owner=IP_SOAINFRA
--define table_list="('TABLE_1','TABLE_2')"
define table_list="('*ALL*')"

with tables
as   (select t0.owner                     table_owner,
             t0.segment_name              table_name,
             t0.bytes/1024/1024           table_megs 
      from   dba_segments t0
      where  t0.owner = '&table_owner'
      and    t0.segment_type = 'TABLE'
      and   (t0.segment_name in &table_list
       or    &table_list     = '*ALL*')),
     indexes
as   (select t0.*,
             t1.owner                     index_owner, 
             substr(t1.uniqueness,1,1)    index_uniqueness,
             t1.index_name                index_name,
             t2.bytes/1024/1024           index_megs
      from   tables       t0,
             dba_indexes  t1,
             dba_segments t2
      where  t0.table_owner = t1.table_owner
      and    t0.table_name  = t1.table_name
      and    t1.owner       = t2.owner
      and    t1.index_name  = t2.segment_name),
     indexed_columns
as   (select t0.index_owner,
             t0.index_name,
             rtrim (xmlagg (xmlelement (e, t1.column_name || ', ') order by t1.column_position).extract ('//text()'), ', ' ) columns
      from   indexes         t0,
             dba_ind_columns t1
      where  t0.index_owner = t1.index_owner
      and    t0.index_name  = t1.index_name
      group  by t0.index_owner,
                t0.index_name)
select t0.table_owner,
       t0.table_name,
       case
         when row_number() over (partition by t0.table_name 
                                 order     by t0.table_name, t0.index_name) = 1 then t0.table_megs
                                                                                else null
       end table_megs,
       t0.index_owner,
       t0.index_name,
       t0.index_uniqueness,
       t0.index_megs,
       t1.columns
from   indexes         t0,
       indexed_columns t1
where  t0.index_owner = t1.index_owner (+)
and    t0.index_name  = t1.index_name  (+)
order  by t0.table_owner,
          t0.table_name,
          t0.index_owner,
          t0.indeX_name,
          t0.index_uniqueness;

--
-- Run this to loop through all tables shrinking/compacting
--

declare
  v_sqlcode number := 0;
begin
  for c1 in (select owner, 
                    table_name 
             from   dba_tables 
             where  owner = '&table_owner' 
             and   (table_name  in &table_list
              or    &table_list = '*ALL*'))
  loop
    begin
      execute immediate 'alter table '||c1.owner||'.'||c1.table_name||' enable row movement';
    exception 
      when others then
        dbms_output.put_line('Error in enable row movement for '||c1.owner||'.'||c1.table_name);
    end;
    begin
    execute immediate 'alter table '||c1.owner||'.'||c1.table_name||' shrink space cascade';
    exception 
      when others then
        dbms_output.put_line('Error in shrink space for '||c1.owner||'.'||c1.table_name);
    end;
  end loop;
dbms_output.put_line ('Complete!');
exception
  when others then
    dbms_output.put_line('Error ('||sqlcode||') in main block');
end;
/

--
-- Run the first script again and compare sizes to see what has decreased
--

An example for a JDE environment before:


TABLE_OWNE TABLE_NAME                     TABLE_MEGS INDEX_OWNE INDEX_NAME                     UK? INDEX_MEGS COLUMNS
---------- ------------------------------ ---------- ---------- ------------------------------ --- ---------- ------------------------------
CRPCTL     F0002                                   0 CRPCTL     F0002_0                        U            0 NNSY
           F0004                                   1 CRPCTL     F0004_0                        U            0 DTSY, DTRT
                                                                F0004_2                        U            0 DTSY, DTUSEQ, DTRT
           F0004D                                  1 CRPCTL     F0004D_0                       U            0 DTSY, DTRT, DTLNGP
           F0005                                   9 CRPCTL     F0005_0                        U            2 DRSY, DRRT, DRKY
                                                                F0005_2                        U            2 DRSY, DRRT, DRDL02, DRKY
                                                                F0005_3                        N            7 DRSY, DRRT, DRDL01
                                                                F0005_4                        N            3 DRSY, DRRT, DRSPHD
                                                                F0005_VELOS_1                  N            5 DRSY, DRRT, SYS_NC00014$
           F0005D                                 16 CRPCTL     F0005D_0                       U            3 DRSY, DRRT, DRKY, DRLNGP
                                                                F0005D_2                       N           10 DRSY, DRRT, DRLNGP, DRDL01
           F0082                                   0 CRPCTL     F0082_0                        U            0 MNMNI
           F00821                                  2 CRPCTL     F00821_0                       U            0 MZMNI, MZSELN
                                                                F00821_2                       N            0 MZJTOE, MZMNI, MZSLTY
                                                                F00821_3                       N            0 MZMNI, MZMTOE, MZSLTY
                                                                F00821_4                       N            0 MZMNI, MZSLTY
                                                                F00821_5                       N            0 MZOPKY, MZVER, MZMNI, MZSLTY
                                                                F00821_6                       N            0 MZOBNM, MZVER, MZMNI, MZSLTY
           F0083                                   7 CRPCTL     F0083_0                        U            1 MTMNI, MTSELN, MTLNGP
                                                                F0083_2                        U            1 MTMNI, MTLNGP, MTSELN
           F0084                                   2 CRPCTL     F0084_0                        U            1 MPMNI, MPSELN, MPPTHT
                                                                F0084_2                        N            1 MPMNI, MPPTHT, MPSELN
                                                                F0084_3                        N            1 MPPTHT, MPPTH, MPMNI
           F9000                                  39 CRPCTL     F9000_0                        U            1 TMTASKID
                                                                F9000_2                        N            2 TMTASKNM
                                                                F9000_3                        N            1 TMOBNM, TMVER, TMFMNM
                                                                F9000_4                        N            0 TMTASKTYPE
                                                                F9000_5                        N            0 TMRULEID
                                                                F9000_6                        N            0 TMFUFTASK4
                                                                F9000_7                        N            0 TMFUFTASK4, TMFUFTASK6
                                                                F9000_8                        N            0 TMFUFTASK7
                                                                F9000_9                        N            2 TMSY, TMTASCKACT, TMTASKID
           F9001                                  17 CRPCTL     F9001_0                        U            4 TRRLTYPE, TRFRMREL, TRTHRREL,
                                                                                                              TRPARNTTSK, TRCHILDTSK,
                                                                                                              TRPRSSEQ

                                                                F9001_2                        N            2 TRCHILDTSK
                                                                F9001_3                        N            3 TRRLTYPE, TRFRMREL, TRTHRREL,
                                                                                                              TRPARNTTSK, TRPRSSEQ

                                                                F9001_4                        N            4 TRRLTYPE, TRPARNTTSK,
                                                                                                              TRCHILDTSK, TRPRSSEQ,
                                                                                                              TRFRMREL, TRTHRREL

                                                                F9001_5                        N            0 TRRULEID
                                                                F9001_6                        N            1 TRPARNTTSK
                                                                F9001_7                        N            2 TRRLTYPE, TRCHILDTSK,
                                                                                                              TRFRMREL, TRTHRREL

                                                                F9001_8                        N            4 TRRELACTIVE, TRPARNTTSK,
                                                                                                              TRCHILDTSK, TRRLTYPE,
                                                                                                              TRFRMREL, TRTHRREL

           F9002                                  21 CRPCTL     F9002_0                        U            3 TDTASKID, TDLNGP
           F9005                                   0 CRPCTL     F9005_0                        U            0 TVRLTYPE, TVFRMREL, TVTHRREL,
                                                                                                              TVPARNTTSK, TVCHILDTSK,
                                                                                                              TVVARNAME

                                                                F9005_2                        N            0 TVVARNAME
                                                                F9005_3                        N            0 TVRLTYPE, TVFRMREL, TVTHRREL,
                                                                                                              TVCHILDTSK

           F9005D                                  0 CRPCTL     F9005D_0                       U            0 VKRLTYPE, VKFRMREL, VKTHRREL,
                                                                                                              VKPARNTTSK, VKCHILDTSK,
                                                                                                              VKVARNAME, VKLNGP

           F9006                                 184 CRPCTL     F9006_0                        U           30 TDVARNAME, TDRLTYPE, TDFRMREL,
                                                                                                              TDTHRREL, TDPARNTTSK,
                                                                                                              TDCHILDTSK

                                                                F9006_2                        N            5 TDRLTYPE, TDFRMREL, TDTHRREL,
                                                                                                              TDPARNTTSK

                                                                F9006_3                        N            5 TDRLTYPE, TDFRMREL, TDTHRREL,
                                                                                                              TDCHILDTSK

           F9006D                                  1 CRPCTL     F9006D_0                       U            1 DKVARNAME, DKRLTYPE, DKFRMREL,
                                                                                                              DKTHRREL, DKPARNTTSK,
                                                                                                              DKCHILDTSK, DKLNGP

           F9010                                   0 CRPCTL     F9010_0                        U            0 EAANSSET, EAQUESTID, EAANSWVLE
           F9020                                   0 CRPCTL     F9020_0                        U            0 CRRULEID
           F9021                                   0 CRPCTL     F9021_0                        U            0 RARULEID, RAACTSEQ
           F9022                                   0 CRPCTL     F9022_0                        U            0 CDRULEID, CDRULESEQ, CDQUESTID
           F9023                                   0 CRPCTL     F9023_0                        U            0 RBACTIONNAME
           F9025                                   0 CRPCTL     F9025_0                        U            0 CSRLTYPE, CSPARNTTSK,
                                                                                                              CSCHILDTSK, CSPRSSEQ

           F9030                                   1 CRPCTL     F9030_0                        U            1 DITASKID, DIINSTYP, DILNGP
           F9050                                   0 CRPCTL     F9050_0                        U            0 AXSY, AXRT, AXPKY, AXDSPSEQ
                                                                F9050_2                        N            0 AXSY, AXRT, AXPKY, AXCKY
           F91011                                  0 CRPCTL     F91011_0                       U            0 WESY, WESRCHWRD, WESRCHWRD2
                                                                F91011_2                       N            0 WESRCHWRD
                                                                F91011_3                       N            0 WESRCHWRD2
                                                                F91011_4                       N            0 WESY
                                                                F91011_5                       N            0 WESRCHWRD, WESY
           F91012                                  0 CRPCTL     F91012_0                       U            0 IWSY, IWIGNWRD
           F91013                                  0 CRPCTL     F91013_0                       U            0 WSSRCHWRD, WSMNI, WSSELN, WSSY
                                                                F91013_2                       N            0 WSSY
                                                                F91013_3                       N            0 WSSRCHWRD, WSMNI, WSSELN
           F91014                                  8 CRPCTL     F91014_0                       U            6 TMSRCHWRD, TMTASKID, TMSY
                                                                F91014_2                       N            3 TMSRCHWRD
                                                                F91014_3                       N            1 TMOBNM
                                                                F91014_4                       U            3 TMTASKID, TMSRCHWRD
           F960004                                 0 CRPCTL     F960004_0                      U            0 CURLSF, CURLS, CUSY, CURT
           F960005                                 0 CRPCTL     F960005_0                      U            0 CRRLSF, CRRLS, CRSY, CRRT,
                                                                                                              CRKY

           F969000                                 1 CRPCTL     F969000_0                      U            0 CMRLSF, CMRLS, CMTASKID
                                                                F969000_2                      N            0 CMRLSF, CMRLS, CMTASKNM,
                                                                                                              CMOBNM, CMVER

           F969001                                 1 CRPCTL     F969001_0                      U            0 CRRLSF, CRRLS, CRRLTYPE,
                                                                                                              CRPARNTTSK, CRCHILDTSK,
                                                                                                              CRFRMREL, CRTHRREL, CRPRSSEQ

           F969002                                 1 CRPCTL     F969002_0                      U            0 CTRLSF, CTRLS, CTTASKID,
                                                                                                              CTLNGP

           F969005                                 1 CRPCTL     F969005_0                      U            0 CVRLSF, CVRLS, CVRLTYPE,
                                                                                                              CVPARNTTSK, CVCHILDTSK,
                                                                                                              CVFRMREL, CVTHRREL, CVVARNAME

           F969006                                 1 CRPCTL     F969006_0                      U            0 CDRLSF, CDRLS, CDRLTYPE,
                                                                                                              CDPARNTTSK, CDCHILDTSK,
                                                                                                              CDFRMREL, CDTHRREL, CDVARNAME

           F9691100                                0 CRPCTL     F9691100_0                     U            0 FVRLSF, FVRLS, FVFOLDER,
                                                                                                              FVFAVORIT

           F9691400                                0 CRPCTL     F9691400_0                     U            0 DTRLSF, DTRLS, DTRPTTMP
           F9691410                                0 CRPCTL     F9691410_0                     U            0 DTRLSF, DTRLS, DTRPTTMP,
                                                                                                              DTDTAI

           F9691420                                0 CRPCTL     F9691420_0                     U            0 SMRLSF, SMRLS, SMSMTID, SMDTAI
           F9691430                                0 CRPCTL     F9691430_0                     U            0 SMRLSF, SMRLS, SMSMTID, SMDTAI
           F9691500                                0 CRPCTL     F9691500_0                     U            0 TPTIPAPP, TPFMNM, TPVERS,
                                                                                                              TPRLSF, TPRLS

           F9691510                                0 CRPCTL     F9691510_0                     U            0 TPRLSF, TPRLS, TPTIPAPP,
                                                                                                              TPFMNM, TPVERS, TPDTAI

           F9746                                   0 CRPCTL     F9746_0                        U            0 D$RLSF, D$RLS, D$SY, D$RT,
                                                                                                              D$KY

           F9751                                   0 CRPCTL     F9751_0                        U            0 M9RLSF, M9RLS, M9MNI, M9SELN
                                                                F9751_2                        N            0 M9RLSF, M9RLS, M9MNI, M9JTOE,
                                                                                                              M9OPKY, M9VER

           F9752                                   0 CRPCTL     F9752_0                        U            0 M9RLSF, M9RLS, M9MNI
                                                                F9752_2                        N            0 M9RLSF, M9RLS, M9ACN
           F9753                                   0 CRPCTL     F9753_0                        U            0 M9RLSF, M9RLS, M9JTOE
           F9754                                   0 CRPCTL     F9754_0                        U            0 M9RLSF, M9RLS, M9OPKY, M9VER
                                                                F9754_2                        N            0 M9RLSF, M9RLS, M9MNI, M9SELN
                                                                F9754_3                        N            0 M9RLSF, M9RLS, M9PTHT, M9PTH
           F9755                                   0 CRPCTL     F9755_0                        U            0 D$RLSF, D$RLS, D$DTAI
           F9757                                   0 CRPCTL     F9757_0                        U            0 D$RLSF, D$RLS, D$DTAI, D$LNGP,
                                                                                                              D$SYR, D$SCRN

           F9759                                   0 CRPCTL     F9759_0                        U            0 D$RLSF, D$RLS, D$DTAI
           F9760                                   0 CRPCTL     F9760_0                        U            0 D$RLSF, D$DTAI, D$RLS
           F98800                                  0 CRPCTL     F98800_0                       U            0 PMPROCNAME, PMPROCVER
                                                                F98800_2                       N            0 PMPROCNAME, PMVERSTS
                                                                F98800_4                       N            0 PMALTPROCNM
           F98800D                                 0 CRPCTL     F98800D_0                      U            0 PKPROCNAME, PKPROCVER, PKLNGP
           F98800DN                                0 CRPCTL     F98800DN_0                     U            0 PKFRMREL, PKTHRREL,
                                                                                                              PKPROCNAME, PKPROCVER, PKLNGP

           F98800N                                 0 CRPCTL     F98800N_0                      U            0 PMFRMREL, PMTHRREL,
                                                                                                              PMPROCNAME, PMPROCVER

                                                                F98800N_2                      N            0 PMPROCNAME, PMVERSTS
                                                                F98800N_3                      N            0 PMALTPROCNM
           F98800T                                 0 CRPCTL     F98800T_0                      U            0 PTPROCNAME, PTPROCVER
           F98800TN                                0 CRPCTL     F98800TN_0                     U            0 PTFRMREL, PTTHRREL,
                                                                                                              PTPROCNAME, PTPROCVER

           F98810                                  8 CRPCTL     F98810_0                       U            1 AMPROCNAME, AMPROCVER,
                                                                                                              AMACTNAME

                                                                F98810_2                       N            0 AMPROCNAME, AMPROCVER,
                                                                                                              AMACTTYPE

                                                                F98810_3                       N            1 AMACTTYPE, AMACTNAME
           F98810D                                 0 CRPCTL     F98810D_0                      U            0 AKPROCNAME, AKPROCVER,
                                                                                                              AKACTNAME, AKLNGP

           F98810DN                                0 CRPCTL     F98810DN_0                     U            0 AKFRMREL, AKTHRREL,
                                                                                                              AKPROCNAME, AKPROCVER,
                                                                                                              AKACTNAME, AKLNGP

           F98810N                                 0 CRPCTL     F98810N_0                      U            0 AMFRMREL, AMTHRREL,
                                                                                                              AMPROCNAME, AMPROCVER,
                                                                                                              AMACTNAME

                                                                F98810N_2                      N            0 AMPROCNAME, AMPROCVER,
                                                                                                              AMACTTYPE

                                                                F98810N_3                      N            0 AMACTTYPE, AMACTNAME
           F98811                                 15 CRPCTL     F98811_0                       U            1 ATPRDTYP, ATPROCNAME,
                                                                                                              ATPROCVER, ATACTNAME, ATWEVENT

                                                                F98811_1                       N            1 ATPRDTYP, ATAPPLID, ATFORMID,
                                                                                                              ATCTRLID, ATWEVENT

           F98811N                                 0 CRPCTL     F98811N_0                      U            0 ATFRMREL, ATTHRREL, ATPRDTYP,
                                                                                                              ATPROCNAME, ATPROCVER,
                                                                                                              ATACTNAME, ATWEVENT

                                                                F98811N_2                      N            0 ATPRDTYP, ATAPPLID, ATFORMID,
                                                                                                              ATCTRLID, ATWEVENT

                                                                F98811N_3                      N            0 ATPRDTYP, ATPROCNAME,
                                                                                                              ATPROCVER, ATACTNAME, ATWEVENT

           F98830                                  3 CRPCTL     F98830_0                       U            2 ARPROCNAME, ARPROCVER,
                                                                                                              ARACTNAME, ARTRANVLU,
                                                                                                              ARNEXTACT

                                                                F98830_2                       N            2 ARPROCNAME, ARPROCVER,
                                                                                                              ARNEXTACT, ARTRANVLU

                                                                F98830_3                       N            1 ARPROCNAME, ARPROCVER,
                                                                                                              ARACTNAME

                                                                F98830_4                       N            1 ARPROCNAME, ARPROCVER,
                                                                                                              ARTRANVLU

                                                                F98830_5                       N            2 ARPROCNAME, ARPROCVER,
                                                                                                              ARACTNAME, ARTRANVLU

           F98830N                                 0 CRPCTL     F98830N_0                      U            0 ARFRMREL, ARTHRREL,
                                                                                                              ARPROCNAME, ARPROCVER,
                                                                                                              ARACTNAME, ARTRANVLU,
                                                                                                              ARNEXTACT

                                                                F98830N_2                      N            0 ARPROCNAME, ARPROCVER,
                                                                                                              ARNEXTACT, ARTRANVLU

                                                                F98830N_3                      N            0 ARPROCNAME, ARPROCVER,
                                                                                                              ARACTNAME

                                                                F98830N_4                      N            0 ARPROCNAME, ARPROCVER,
                                                                                                              ARTRANVLU

                                                                F98830N_5                      N            0 ARPROCNAME, ARPROCVER,
                                                                                                              ARACTNAME, ARTRANVLU

           F98840                                  0 CRPCTL     F98840_0                       U            0 OMORGMODEL, OMOSTP
           F98840N                                 0 CRPCTL     F98840N_0                      U            0 OMFRMREL, OMTHRREL,
                                                                                                              OMORGMODEL, OMOSTP

           F98845                                  0 CRPCTL     F98845_0                       U            0 ORPROCNAME, ORPROCVER,
                                                                                                              ORACTNAME, ORRULVLU

           F98845N                                 0 CRPCTL     F98845N_0                      U            0 ORFRMREL, ORTHRREL,
                                                                                                              ORPROCNAME, ORPROCVER,
                                                                                                              ORACTNAME, ORRULVLU

           F98860                              1,352 CRPCTL     F98860_0                       U           55 PIPROCNAME, PIPROCVER,
                                                                                                              PIPROCIST

                                                                F98860_2                       N          664 PIPROCNAME, PIPROCVER,
                                                                                                              PIISTKEY

                                                                F98860_3                       N          680 PIPROCSTS, PIPROCNAME,
                                                                                                              PIPROCVER, PIISTKEY

                                                                F98860_4                       N          664 PIPROCSTS, PIPROCNAME,
                                                                                                              PIISTKEY

                                                                F98860_5                       N          321 PIPROCNAME, PIPROCVER,
                                                                                                              PIPROCIST, PISTDATE, PISTTME

                                                                F98860_6                       N          664 PIPROCNAME, PIISTKEY
           F98865                                863 CRPCTL     F98865_0                       U          480 AIPROCNAME, AIPROCVER,
                                                                                                              AIPROCIST, AIACTNAME,
                                                                                                              AIACTIST, AIORGGRP, AISEQUENCE

                                                                F98865_2                       N          248 AIEMAILNO
                                                                F98865_3                       N          240 AISUBPROC, AISUBVER, AISUBIST
                                                                F98865_4                       N          904 AIPROCNAME, AIPROCVER,
                                                                                                              AIPROCIST, AIRESOURCE,
                                                                                                              AIACTNAME, AIACTSTS

                                                                F98865_5                       N          552 AIPROCNAME, AIPROCVER,
                                                                                                              AIPROCIST, AISTDATE, AISTTME,
                                                                                                              AIORGGRP, AISEQUENCE

                                                                F98865_6                       N          520 AIPROCNAME, AIPROCVER,
                                                                                                              AIPROCIST, AISTDATE, AISTTME

                                                                F98865_7                       N          100 AIPROCNAME, AIRESOURCE,
                                                                                                              AIACTSTS, AIDAEXP, AIACTNAME

           F98880                                  0 CRPCTL     F98880_0                       U            0 CDCIFNUM, CDCUSTSITE
           F98882                                  0 CRPCTL     F98882_0                       U            0 RCSY, RCRT, RCKY
           F98885                                  0 CRPCTL     F98885_0                       U            0 GIRT, GIPROCNAME, GIPROCVER,
                                                                                                              GIACTNAME, GIKY

           F98887                                  0 CRPCTL     F98887_0                       U            0 PCRT, PCKY, PCAA10
           F98890                                  0 CRPCTL     F98890_0                       U            0 CMPROCNAME, CMPROCVER
********** ****************************** ---------- **********                                    ----------
sum                                            2,560                                                    6,232





