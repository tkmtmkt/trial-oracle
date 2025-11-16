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


## 参考

- [DockerでOracle Databaseを構築してみる #oracle - Qiita](https://qiita.com/h-i-ist/items/a67acbce0e7c6bdebd69)
