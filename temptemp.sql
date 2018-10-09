PROCEDURE "SYSTEM"."skye::hub"(IN tabellnavn varchar(30),staging_tabell varchar(50),business_key varchar(50))
       LANGUAGE SQLSCRIPT
       SQL SECURITY INVOKER
       DEFAULT SCHEMA SYSTEM
       AS
BEGIN
DECLARE finnes integer;
call  "SYSTEM"."skye::existable"('HUB_'||:tabellnavn,'SYSTEM',finnes);
IF (:finnes = 0 ) then
EXEC 'CREATE COLUMN TABLE HUB_'||:tabellnavn||'(
hubhashkey VARBINARY(32),
recorsource NVARCHAR(100),
loaddate timestamp,
business_key NVARCHAR(100),
PRIMARY KEY (hubhashkey))
UNLOAD PRIORITY 0 AUTO MERGE';
END IF;
EXEC 'CREATE COLUMN TABLE delta_'||:tabellnavn||'(
hubhashkey VARBINARY(32),
recorsource NVARCHAR(100),
loaddate timestamp,
business_key NVARCHAR(100),
PRIMARY KEY (hubhashkey))
UNLOAD PRIORITY 0 AUTO MERGE';
EXEC 'INSERT INTO delta_'||:tabellnavn||' (hubHashkey,recorsource,LoadDate,business_key)
(SELECT distinct(HASH_MD5(to_binary("'||:business_key||'"))),''Min kilde'',to_date(current_timestamp),"'||:business_key||'"
FROM "'||:staging_tabell||'" AS c
WHERE NOT EXISTS
(
  SELECT business_key
    FROM "HUB_'||:tabellnavn||'"
    WHERE business_key = "'||:business_key||'") AND ("'||:business_key||'" is not null))';
 
EXEC 'INSERT INTO HUB_'||:tabellnavn||'
SELECT *
FROM delta_'||:tabellnavn||'';
EXEC 'unload delta_' ||:tabellnavn||'';
EXEC 'drop table delta_' ||:tabellnavn||'';
END;
 
 
 
 
PROCEDURE "SYSTEM"."skye::satellite"(IN tabellnavn varchar(80),tabel_kilde varchar(120),key varchar(100),diff varchar(200),kilde varchar(80),attributes varchar(600))
       LANGUAGE SQLSCRIPT
       SQL SECURITY INVOKER
       DEFAULT SCHEMA SYSTEM
AS
BEGIN
DECLARE finnes integer;
call  "SYSTEM"."skye::existable"('SAT_'||:tabellnavn,'SYSTEM',finnes);
/*Bygge stage tabel*/
EXEC 'create column table "SYSTEM"."STAGE_'||:tabellnavn||'"  as
(
select distinct
HASH_MD5(to_binary('||:key||')) as sathashkey,
HASH_MD5(to_binary('||:diff||')) as sathashkey_diff,
''ii'' as recorsource,
now() as date_added,
'||:attributes||' from "'||:tabel_kilde||'")';
/*Bygge temp tabel*/
EXEC 'create column table "SYSTEM"."TEMP_'||:tabellnavn||'"  as
(
select distinct
HASH_MD5(to_binary('||:key||')) as sathashkey,
HASH_MD5(to_binary('||:diff||')) as sathashkey_diff,
''Min kilde'' as recorsource,
now() as date_added,
now() as date_expire,
'||:attributes||' from "'||:tabel_kilde||'") WITH NO DATA';
/*Bygge sat tabel*/
IF (:finnes = 0 ) then
EXEC 'create column table "SYSTEM"."SAT_'||:tabellnavn||'"  as
(
select * from  "SYSTEM"."TEMP_'||:tabellnavn||'")WITH NO DATA';
END IF;
/*Legge til eksiterende rader*/
EXEC 'insert into "SYSTEM"."TEMP_'||:tabellnavn||'"
SELECT * from "SYSTEM"."SAT_'||:tabellnavn||'"
WHERE date_expire <>''''';
/*Legge til eksiterende rader som er nye*/
EXEC 'insert into "SYSTEM"."TEMP_'||:tabellnavn||'"
SELECT sathashkey,a.sathashkey_diff,'''||:kilde||''',now(),'''','||:attributes||'
FROM "SYSTEM"."STAGE_'||:tabellnavn||'" as a
WHERE (NOT EXISTS
( SELECT b.sathashkey
    FROM "SYSTEM"."SAT_'||:tabellnavn||'" as b
WHERE (b.sathashkey = a.sathashkey) AND (b.sathashkey_diff = a.sathashkey_diff) AND (date_expire = '''')))';
/*Legge til eksiterende rader som ikke er nye*/
EXEC 'insert into "SYSTEM"."TEMP_'||:tabellnavn||'"
SELECT *
FROM "SYSTEM"."SAT_'||:tabellnavn||'" as a
WHERE (a.date_expire ='''') AND
(EXISTS
(SELECT sathashkey
    FROM "SYSTEM"."STAGE_'||:tabellnavn||'" as b
WHERE (b.sathashkey = a.sathashkey) AND (b.sathashkey_diff = a.sathashkey_diff )))';
/*Legge til eksiterende rader som ikke er nye*/
EXEC 'insert into "SYSTEM"."TEMP_'||:tabellnavn||'"
SELECT sathashkey,sathashkey_diff,recorsource,date_added,now(),'||:attributes||'
FROM "SYSTEM"."SAT_'||:tabellnavn||'" as a
WHERE (a.date_expire ='''') AND
(EXISTS
(SELECT sathashkey
    FROM "SYSTEM"."STAGE_'||:tabellnavn||'" as b
WHERE (b.sathashkey = a.sathashkey) AND (b.sathashkey_diff <> a.sathashkey_diff)))';
/*Legge til eksiterende rader som ikke er nye*/
EXEC 'insert into "SYSTEM"."TEMP_'||:tabellnavn||'"
SELECT *
FROM "SYSTEM"."SAT_'||:tabellnavn||'" as a
WHERE (a.date_expire ='''') AND
(NOT EXISTS
(SELECT sathashkey
    FROM "SYSTEM"."STAGE_'||:tabellnavn||'" as b
WHERE (b.sathashkey = a.sathashkey)))';
/*slette eksisterende sat tabell*/
EXEC 'drop table "SYSTEM"."SAT_'||:tabellnavn||'"';
/*Døpe om TEMP tabellen til SAT*/
EXEC 'rename table "SYSTEM"."TEMP_'||:tabellnavn||'" to "SYSTEM"."SAT_'||:tabellnavn||'"';
--------call "SYSTEM"."My_package::existstable"(:tabellnavn||'_STAGE','SYSTEM');
EXEC 'drop table "SYSTEM"."STAGE_'||:tabellnavn||'"';
END
 
 
PROCEDURE "SYSTEM"."skye::link_two"(tabellnavn varchar(30),tabel_kilde varchar(50),linktabel1 varchar(30),linktabel1_key varchar(300),linktabel2 varchar(30),linktabel2_key varchar(300))
       LANGUAGE SQLSCRIPT
       SQL SECURITY INVOKER
       DEFAULT SCHEMA SYSTEM
 AS
BEGIN
DECLARE finnes integer;
call "SYSTEM"."skye::existable"('LINK_'||:tabellnavn,'SYSTEM',finnes);
call "SYSTEM"."skye::existable"('LINK_TEMP_'||:tabellnavn,'SYSTEM',finnes);
EXEC 'CREATE COLUMN TABLE LINK_TEMP_'||:tabellnavn||'(
linkhashkey VARBINARY(32),
loaddate timestamp,
HUB_'||linktabel1||' VARBINARY(32),
HUB_'||linktabel2||' VARBINARY(32))
UNLOAD PRIORITY 5 AUTO MERGE';
EXEC 'CREATE COLUMN TABLE LINK_'||:tabellnavn||'(
linkhashkey VARBINARY(32),
loaddate timestamp,
HUB_'||linktabel1||' VARBINARY(32),
HUB_'||linktabel2||' VARBINARY(32))
UNLOAD PRIORITY 5 AUTO MERGE';
EXEC 'insert into LINK_TEMP_'||:tabellnavn||'
select DISTINCT B.hubhashkey||C.hubhashkey,to_date(current_timestamp),B.hubhashkey,C.hubhashkey  
from "'||:tabel_kilde||'" as A
join HUB_'||:linktabel1||' B on B.hubhashkey = HASH_MD5(to_binary('||:linktabel1_key||'))
join HUB_'||:linktabel2||' C on C.hubhashkey = HASH_MD5(to_binary('||:linktabel2_key||'))';
EXEC 'insert into LINK_'||:tabellnavn||'
SELECT *
FROM  LINK_TEMP_'||:tabellnavn||' a
WHERE
(NOT EXISTS
(SELECT LinkHashKey
    FROM  LINK_'||:tabellnavn||' as b
WHERE (b.LinkHashKey = a.LinkHashKey)))';
EXEC 'drop table LINK_TEMP_'||:tabellnavn||'';
END;