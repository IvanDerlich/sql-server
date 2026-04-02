# SQL Server / DbGate

Base project to run DbGate with Docker Compose and connect it to SQL Server.

## Requirements

- Docker
- Docker Compose

## Main Files

- [docker-compose.yml](docker-compose.yml): defines the `client` and `mssql` services plus the project network.
- [Dockerfile.client](Dockerfile.client): DbGate client image.
- [Dockerfile.server](Dockerfile.server): SQL Server base image.
- [Dockerfile.cli-tool](Dockerfile.cli-tool): CLI container with sqlcmd tooling.
- [.env](.env): local environment variables.
- [.env.example](.env.example): example of the expected variables.

## Configuration

The client port is read from `CLIENT_PORT` in the `.env` file.

Example:

```env
CLIENT_PORT=3000
```

The SQL Server service uses these variables from `.env`:

```env
SQLSERVER_PORT=1433
MSSQL_PID=Developer
ACCEPT_EULA=Y
MSSQL_SA_PASSWORD=YourStrong!Passw0rd123
```

Application bootstrap variables:

```env
APP_DB_NAME=appdb
APP_DB_USER=app_user
APP_DB_PASSWORD=AppUser!Pass123
```

## Usage

1. Copy `.env.example` to `.env` if it does not exist yet.
2. Adjust `CLIENT_PORT` or `SQLSERVER_PORT` if you need different ports.
3. Set a strong `MSSQL_SA_PASSWORD`.
4. Start the stack:

```bash
docker compose up -d
```

5. Run the one-time database bootstrap container (removed automatically after it finishes):

```bash
docker compose --profile init run --rm db-init
```

6. Open DbGate at:

```text
http://localhost:3000
```

## Local Persistence

Client data is stored in `volumes/client` inside the repository.

That folder works as a bind mount, so:
- data persists across container restarts
- you do not need to look for an internal Docker volume
- you should not commit real local environment data

## SQL Server

The project also includes a SQL Server container based on the free Developer edition.

Connection settings:

- host: `mssql`
- port: `SQLSERVER_PORT` from `.env`
- user: `sa`
- password: `MSSQL_SA_PASSWORD` from `.env`

Its data is stored in `volumes/mssql`.

## Manual check

## Connect to the server from the container
Run an interactive shell in the tooling container:

```bash
docker compose exec -it cli-tool bash
```
## Connect to the server from the container

sqlcmd -S localhost,$SQLSERVER_PORT -U sa -P '$MSSQL_SA_PASSWORD' -C

## Then run commands like these:

```bash
sqlcmd -S mssql,1433 -U sa -P '$MSSQL_SA_PASSWORD' -C
```

```bash
sqlcmd -S mssql,1433 -U sa -P '$MSSQL_SA_PASSWORD' -C -Q "SELECT @@VERSION"
```

Inside interactive `sqlcmd`:

```sql
SELECT name FROM sys.databases;
GO
```

```sql
SELECT GETDATE();
GO
```

## Connect From DbGate

After the containers are running, open DbGate at:

```text
http://localhost:$CLIENT_PORT
```

Use these SQL Server connection settings in DbGate:

- Server: `mssql`
- Port: `SQLSERVER_PORT` (from `.env`)
- User: `sa`
- Password: `MSSQL_SA_PASSWORD` (from `.env`)

Notes:

- The SQL Server admin user is `sa` (not `root`).
- The SQL Server port is configured through `SQLSERVER_PORT` in `.env`.

