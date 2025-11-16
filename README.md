# trial oracle at docker

### dockerイメージ作成

```sh
git clone https://github.com/oracle/docker-images.git
cd docker-images/OracleDatabase/SingleInstance/dockerfiles
./buildContainerImage.sh -v 11.2.0.2 -x
./buildContainerImage.sh -v 18.4.0 -x
```
```
 1 warning found (use docker --debug to expand):
 - UndefinedVar: Usage of undefined variable '$HOME' (line 38)

  Oracle Database container image for 'xe' version 18.4.0 is ready to be extended: 

    --> oracle/database:18.4.0-xe

  Build completed in 585 seconds.
```

### dockerコンテナ起動

```sh
# ディレクトリ作成
mkdir -p ./db/opt/oracle/oradata
chmod a+w ./db/opt/oracle/oradata

# コンテナ起動
docker compose up -d
```

### コンテナ確認

```sh
docker compose ps
```
```
NAME          IMAGE                          COMMAND                   SERVICE   CREATED         STATUS                   PORTS
oracle-db-1   oracle/database:23.26.0-free   "/bin/bash -c 'exec …"   db        9 minutes ago   Up 9 minutes (healthy)   1521/tcp
```

### SQLPlus起動

```sh
# bashログイン
docker compose exec -u oracle db bash

# NLS環境変数設定
export NLS_LANG=Japanese_Japan.AL32UTF8
export NLS_DATE_FORMAT='YYYY-MM-DD HH24:MI:SS'
export NLS_TIMESTAMP_FORMAT='YYYY-MM-DD HH24:MI:SSXFF'

# SQLPlus起動
sqlplu / as sysdba
sqlplus sys/Passw0rd@//localhost:1521/XE as sysdba
sqlplus system/Passw0rd@//localhost:1521/XE
sqlplus pdbadmin/Passw0rd@//localhost:1521/XEPDB1
```

### PDB操作

PDB名表示
```sql
SQL> SHOW CON_NAME

CON_NAME
------------------------------
CDB$ROOT
```

PDBクローズ
```sql
SQL> ALTER PLUGGABLE DATABASE XEPDB1 CLOSE;

プラガブル・データベースが変更されました。

SQL> SHOW PDBS

    CON_ID CON_NAME                       OPEN MODE  RESTRICTED
---------- ------------------------------ ---------- ----------
         2 PDB$SEED                       READ ONLY  NO
         3 XEPDB1                         MOUNTED
```

PDBオープン
```sql
SQL> ALTER PLUGGABLE DATABASE XEPDB1 OPEN;

プラガブル・データベースが変更されました。

SQL> SHOW PDBS

    CON_ID CON_NAME                       OPEN MODE  RESTRICTED
---------- ------------------------------ ---------- ----------
         2 PDB$SEED                       READ ONLY  NO
         3 XEPDB1                         READ WRITE NO
```

PDB接続先切り替え
```sql
SQL> ALTER SESSION SET CONTAINER = XEPDB1;

セッションが変更されました。

SQL> SHOW CON_NAME

CON_NAME
------------------------------
XEPDB1
```

### PDB作成

OMF有効化
```sql
SQL> ALTER SYSTEM SET db_create_file_dest = '/opt/oracle/oradata';

システムが変更されました。
```

PDB作成
```sql
SQL> CREATE PLUGGABLE DATABASE PDB2
  ADMIN USER pdbadmin IDENTIFIED BY Passw0rd
  FILE_NAME_CONVERT=('/pdbseed/', '/PDB2/');

プラガブル・データベースが作成されました。

SQL> SHOW PDBS

    CON_ID CON_NAME                       OPEN MODE  RESTRICTED
---------- ------------------------------ ---------- ----------
         2 PDB$SEED                       READ ONLY  NO
         3 XEPDB1                         READ WRITE NO
         4 PDB2                           MOUNTED
```

PDBオープン（起動時にオープン状態になるように設定する）
```sql
SQL> ALTER PLUGGABLE DATABASE PDB2 OPEN;

プラガブル・データベースが変更されました。

SQL> ALTER PLUGGABLE DATABASE PDB2 SAVE STATE;

プラガブル・データベースが変更されました。

SQL> SHOW PDBS

    CON_ID CON_NAME                       OPEN MODE  RESTRICTED
---------- ------------------------------ ---------- ----------
         2 PDB$SEED                       READ ONLY  NO
         3 XEPDB1                         READ WRITE NO
         4 PDB2                           READ WRITE NO
```

PDB接続切り替え
```sql
SQL> ALTER SESSION SET CONTAINER = PDB2;

セッションが変更されました。

SQL> SHOW CON_NAME

CON_NAME
------------------------------
PDB2
```

表領域作成
```sql
SQL> CREATE TABLESPACE HOGE;

表領域が作成されました。

SQL> SET PAGES 9999
SQL> SET LINES 160
SQL> COL tablespace_name FORMAT A10
SQL> COL file_name FORMAT A90
SQL> SELECT
    tablespace_name,
    file_name,
    bytes / 1024 / 1024 AS size_mb,
    maxbytes / 1024 / 1024 AS max_size_mb
FROM
    dba_data_files;
TABLESPACE FILE_NAME                                                                                     SIZE_MB MAX_SIZE_MB
---------- ------------------------------------------------------------------------------------------ ---------- -----------
SYSTEM     /opt/oracle/oradata/XE/PDB2/system01.dbf                                                          250  32767.9844
SYSAUX     /opt/oracle/oradata/XE/PDB2/sysaux01.dbf                                                          370  32767.9844
UNDOTBS1   /opt/oracle/oradata/XE/PDB2/undotbs01.dbf                                                         100  32767.9844
HOGE       /opt/oracle/oradata/XE/43AFCE057AED0F44E063020016ACACF2/datafile/o1_mf_hoge_nklotp0j_.dbf         100  32767.9844
```

### データファイル確認
```
[oracle@oracle ~]$ tree -F --dirsfirst /opt/oracle/oradata/XE
/opt/oracle/oradata/XE
|-- 43AFCE057AED0F44E063020016ACACF2/
|   `-- datafile/
|       `-- o1_mf_hoge_nklotp0j_.dbf
|-- PDB2/
|   |-- sysaux01.dbf
|   |-- system01.dbf
|   |-- temp012025-11-16_02-42-22-195-AM.dbf
|   `-- undotbs01.dbf
|-- XEPDB1/
|   |-- sysaux01.dbf
|   |-- system01.dbf
|   |-- temp01.dbf
|   |-- undotbs01.dbf
|   `-- users01.dbf
|-- pdbseed/
|   |-- sysaux01.dbf
|   |-- system01.dbf
|   |-- temp012025-11-16_02-42-22-195-AM.dbf
|   `-- undotbs01.dbf
|-- control01.ctl
|-- control02.ctl
|-- redo01.log
|-- redo02.log
|-- redo03.log
|-- sysaux01.dbf
|-- system01.dbf
|-- temp01.dbf
|-- undotbs01.dbf
`-- users01.dbf

5 directories, 24 files
```

## 参考

- [DockerでOracle Databaseを構築してみる #oracle - Qiita](https://qiita.com/h-i-ist/items/a67acbce0e7c6bdebd69)
