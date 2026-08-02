WITH sales_no_returns AS (
    SELECT
        c.c_customer_id,
        d.d_year AS d_year,
        SUM(ss.ss_net_paid) AS total_spent
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    WHERE d.d_year BETWEEN 2001 AND 2002
      AND NOT EXISTS (
          SELECT 1
          FROM web_returns wr
          WHERE wr.wr_returning_customer_sk = c.c_customer_sk
            AND wr.wr_item_sk = ss.ss_item_sk
      )
    GROUP BY c.c_customer_id, d.d_year
),
sales_no_returns_discount AS (
    SELECT
        c.c_customer_id,
        d.d_year AS d_year,
        SUM(ss.ss_net_paid) * 0.95 AS total_spent
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    WHERE d.d_year = 2003
      AND NOT EXISTS (
          SELECT 1
          FROM web_returns wr
          WHERE wr.wr_returning_customer_sk = c.c_customer_sk
            AND wr.wr_item_sk = ss.ss_item_sk
      )
    GROUP BY c.c_customer_id, d.d_year
)
SELECT
    combined.c_customer_id,
    combined.d_year,
    combined.total_spent
FROM (
    SELECT c_customer_id, d_year, total_spent FROM sales_no_returns
    UNION ALL
    SELECT c_customer_id, d_year, total_spent FROM sales_no_returns_discount
) AS combined
ORDER BY combined.total_spent DESC
LIMIT 100
