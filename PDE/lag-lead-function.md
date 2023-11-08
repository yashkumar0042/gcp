The `LAG` and `LEAD` functions are analytical functions in SQL that allow you to access data from previous or subsequent rows in a result set without using self-joins or subqueries. These functions are commonly used for tasks like calculating the difference between consecutive rows or accessing values from adjacent rows. Here's how they work with examples:

### LAG Function:

The `LAG` function retrieves data from a previous row within the result set. It is often used to calculate the difference between the current row and the previous row. The `LAG` function takes three arguments:

- The expression to retrieve data from the previous row.
- The number of rows back to look (offset). The default is 1, which means the previous row.
- A default value to return if no previous row is found (optional).

**Syntax:**
```sql
LAG (expression, offset, default) OVER (PARTITION BY partition_column ORDER BY sort_column)
```

### LEAD Function:

The `LEAD` function retrieves data from a subsequent row within the result set. It is used to access data from the following row. The `LEAD` function also takes three arguments:

- The expression to retrieve data from the subsequent row.
- The number of rows ahead to look (offset). The default is 1, which means the next row.
- A default value to return if no subsequent row is found (optional).

**Syntax:**
```sql
LEAD (expression, offset, default) OVER (PARTITION BY partition_column ORDER BY sort_column)
```

### Example:

Let's say you have a table named `sales` with the following data:

```sql
+------+-------+
| year | revenue |
+------+-------+
| 2019 | 1000    |
| 2020 | 1500    |
| 2021 | 1200    |
| 2022 | 1800    |
+------+-------+
```

Now, you want to calculate the revenue growth (difference) from the previous year and the revenue forecast (next year's revenue) for each year. You can use the `LAG` and `LEAD` functions for this:

```sql
SELECT
  year,
  revenue,
  LAG(revenue, 1, 0) OVER (ORDER BY year) AS prev_year_revenue,
  LEAD(revenue, 1, 0) OVER (ORDER BY year) AS next_year_revenue
FROM sales
ORDER BY year;
```

The result will be:

```sql
+------+-------+--------------------+-------------------+
| year | revenue | prev_year_revenue | next_year_revenue |
+------+-------+--------------------+-------------------+
| 2019 | 1000    | 0                  | 1500              |
| 2020 | 1500    | 1000               | 1200              |
| 2021 | 1200    | 1500               | 1800              |
| 2022 | 1800    | 1200               | 0                 |
+------+-------+--------------------+-------------------+
```

In this example, the `LAG` function calculates the previous year's revenue, and the `LEAD` function calculates the next year's revenue for each year. If there's no data for the previous or next year, the default value of 0 is used.

These functions are powerful for various analytical tasks, including calculating differences, identifying trends, and making forecasts in your SQL queries.
