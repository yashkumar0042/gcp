In PostgreSQL, you can use the `psql` command-line tool to interact with the database. Here are some common PostgreSQL commands that you can use in the command line:

1. **Connect to a Database**:
   ```
   psql -U username -d database_name
   ```
   - `-U`: Specifies the username to connect to the database.
   - `-d`: Specifies the name of the database to connect to.

2. **List Databases**:
   ```
   \l
   ```
   This command lists all databases available on the PostgreSQL server.

3. **Connect to a Specific Database**:
   ```
   \c database_name
   ```
   This command connects to the specified database.

4. **List Tables**:
   ```
   \dt
   ```
   This command lists all tables in the current database.

5. **Describe Table**:
   ```
   \d table_name
   ```
   This command describes the structure of the specified table, including columns, data types, and constraints.

6. **Execute SQL Query**:
   ```
   SELECT * FROM table_name;
   ```
   This command executes a SQL query to retrieve data from the specified table. You can replace `*` with specific columns to select.

7. **Exit psql**:
   ```
   \q
   ```
   This command exits the psql command-line interface.

8. **Help**:
   ```
   \?
   ```
   This command provides help and lists available psql commands.

These are some of the basic PostgreSQL commands you can use in the command-line interface. There are many more commands available for managing databases, tables, users, and permissions, depending on your requirements. You can explore more commands and options by using the `\?` command or by referring to the PostgreSQL documentation.
