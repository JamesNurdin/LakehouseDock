WITH store_purchasers_no_returns AS (
    SELECT DISTINCT c.c_customer_id,
                    c.c_first_name,
                    c.c_last_name
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_fy_year = 2018
      AND NOT EXISTS (
          SELECT 1
          FROM store_returns sr
          WHERE sr.sr_customer_sk = c.c_customer_sk
      )
),
web_return_customers AS (
    SELECT DISTINCT c.c_customer_id,
                    c.c_first_name,
                    c.c_last_name
    FROM web_returns wr
    JOIN customer c ON wr.wr_returning_customer_sk = c.c_customer_sk
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    WHERE d.d_fy_year = 2018
      AND EXISTS (
          SELECT 1
          FROM store_sales ss2
          WHERE ss2.ss_customer_sk = c.c_customer_sk
      )
)
SELECT DISTINCT combined.c_customer_id,
                combined.c_first_name,
                combined.c_last_name
FROM (
    SELECT c_customer_id, c_first_name, c_last_name FROM store_purchasers_no_returns
    UNION ALL
    SELECT c_customer_id, c_first_name, c_last_name FROM web_return_customers
) AS combined
ORDER BY combined.c_customer_id
LIMIT 100
