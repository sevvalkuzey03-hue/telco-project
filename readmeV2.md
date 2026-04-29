# Telco SQL Homework (Oracle XE)

Hi, this repo contains the files I prepared for the homework.
Goal: set up the database on Oracle XE, import CSV files, and run the required SQL queries.

## Which files are in this project?

- `docker-compose.yml` -> to start the Oracle XE container
- `sql/TABLE_CREATION_SCRIPTS.sql` -> to create tables
- `sql/SOLUTIONS.sql` -> SQL answers for the questions

## 1) Start Oracle with Docker

Docker Desktop should be installed on your computer.

Run this command in the project folder:

```bash
docker compose up -d
```

To check status:

```bash
docker ps
docker logs -f telco-oracle-xe
```

Connection details:

- Host: `localhost`
- Port: `1521`
- Service Name: `XEPDB1`
- User: `telco_user`
- Password: `telco_pass`

Note: when the container starts for the first time, `TABLE_CREATION_SCRIPTS.sql` runs automatically.

## 2) Connect with DBeaver

1. Open DBeaver
2. Click `New Database Connection`
3. Select `Oracle`
4. Enter the connection details above
5. Click `Test Connection`
6. Save

## 3) Import CSV files

Used files:

- `TARIFFS.csv`
- `CUSTOMERS.csv`
- `MONTHLY_STATS.csv`

Order is important, import in this order:

1. `tariffs`
2. `customers`
3. `monthly_stats`

Import steps:

- Right click the related table
- Click `Import Data`
- Select CSV
- Check column mappings

Important notes:

- For `SIGNUP_DATE` in `CUSTOMERS.csv`, date format should be `DD/MM/YYYY`
- `PAYMENT_STATUS` values in `MONTHLY_STATS.csv` are: `PAID`, `LATE`, `UNPAID`

## 4) Run the queries

1. Open `sql/SOLUTIONS.sql` in DBeaver SQL Editor
2. Run queries one by one
3. Take screenshots of the outputs

## 5) Short checklist

- [x] Table script is ready
- [x] Query script is ready
- [x] Environment starts with Docker
- [ ] CSV import completed
- [ ] Query result screenshots taken

## 6) Suggested screenshot names

You can save them under `docs/` like this:

- `docs/01-docker-running.png`
- `docs/02-dbeaver-connection-test.png`
- `docs/03-import-tariffs.png`
- `docs/04-import-customers.png`
- `docs/05-import-monthly-stats.png`
- `docs/06-query-results.png`

