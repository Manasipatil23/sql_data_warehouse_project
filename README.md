# SQL Data Warehouse Project

Building a modern data warehouse with SQL Server, including ETL processes, data modeling and analytics.

This project consolidates sales data from two source systems (CRM and ERP) into a single SQL Server data warehouse, following the **Medallion Architecture** (Bronze → Silver → Gold).

> Status: 🚧 In progress

---

## 🏗️ Data Architecture

| Layer | Purpose | Object type |
|---|---|---|
| **Bronze** | Raw data loaded as-is from the source CSV files | Tables |
| **Silver** | Cleaned, standardized and normalized data | Tables |
| **Gold** | Business-ready data modeled as a star schema | Views |

## 📂 Repository Structure

```
sql-data-warehouse-project/
├── datasets/          # Raw source data (CRM and ERP CSV files)
│   ├── source_crm/
│   └── source_erp/
├── docs/              # Architecture diagrams, naming conventions, data catalog
├── scripts/           # SQL scripts
│   ├── bronze/        # Create and load raw tables
│   ├── silver/        # Clean and transform data
│   └── gold/          # Create the star schema views
├── tests/             # Data quality checks
├── .gitignore
└── README.md
```

## 🛠️ Tech Stack

- **SQL Server 2022** (Developer Edition) running in **Docker** on macOS (Apple Silicon)
- **VS Code** with the **MSSQL extension** as the SQL editor
- **Git & GitHub** for version control

## 🍎 Running on macOS

SQL Server does not run natively on macOS, so it runs in a Docker container using Rosetta for x86 emulation.

1. Install [Docker Desktop](https://www.docker.com/products/docker-desktop/) and enable Rosetta.
2. Create a `.env` file in the project root (never committed):
   ```
   ACCEPT_EULA=Y
   MSSQL_SA_PASSWORD=<your-strong-password>
   ```
3. Start SQL Server:
   ```bash
   docker run -d --name sql-dwh \
     --platform linux/amd64 \
     --env-file .env \
     -p 1433:1433 \
     -v sqldwh-data:/var/opt/mssql \
     -v "$(pwd)/datasets:/datasets:ro" \
     --restart unless-stopped \
     mcr.microsoft.com/mssql/server:2022-latest
   ```
4. Connect from VS Code (MSSQL extension) to `localhost` with SQL Login `sa` and **Trust server certificate** enabled.

> Note: because SQL Server runs inside a Linux container, `BULK INSERT` paths use the container path (e.g. `/datasets/source_crm/...`) instead of Windows paths.

## 🙏 Acknowledgements

Based on the [SQL Data Warehouse project](https://youtu.be/9GVqKuTVANE) by Data with Baraa, adapted for macOS.

## 👩‍💻 Author

**Manasi Patil** — [GitHub](https://github.com/Manasipatil23)
