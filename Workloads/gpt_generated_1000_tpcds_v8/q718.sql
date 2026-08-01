WITH returns_sample AS (
  SELECT
    c.c_customer_sk,
    c.c_first_name,
    c.c_last_name,
    cr.cr_return_amount AS amount,
    d.d_date AS trans_date,
    (
      SELECT SUM(ws.ws_net_paid)
      FROM web_sales ws
      WHERE ws.ws_bill_customer_sk = c.c_customer_sk
    ) AS total_web_sales
  FROM catalog_returns cr
  TABLESAMPLE BERNOULLI (10)
  JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
  JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
  WHERE NOT EXISTS (
        SELECT 1
        FROM reason r
        WHERE r.r_reason_sk = cr.cr_reason_sk
          AND r.r_reason_desc = 'Damaged'
      )
),

sales_distinct AS (
  SELECT DISTINCT
    c.c_customer_sk,
    c.c_first_name,
    c.c_last_name,
    ws.ws_ext_sales_price AS amount,
    d.d_date AS trans_date,
    (
      SELECT SUM(ws2.ws_net_paid)
      FROM web_sales ws2
      WHERE ws2.ws_bill_customer_sk = c.c_customer_sk
    ) AS total_web_sales
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
  WHERE d.d_year = 2002
    AND ws.ws_net_profit > 0
)

SELECT *
FROM (
    SELECT * FROM returns_sample
    UNION ALL
    SELECT * FROM sales_distinct
) combined
ORDER BY total_web_sales DESC
OFFSET 0 ROWS FETCH NEXT 20 ROWS ONLY
