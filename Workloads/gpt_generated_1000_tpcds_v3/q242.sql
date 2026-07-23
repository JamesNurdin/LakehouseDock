WITH avg_catalog_profit AS (
    SELECT AVG(cs.cs_net_profit) AS avg_profit
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_date BETWEEN DATE '2020-01-01' AND DATE '2020-12-31'
)
SELECT
    c.c_customer_id AS customer_id,
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
    'catalog_profit' AS metric_type,
    SUM(cs.cs_net_profit) AS metric_amount,
    (SELECT MAX(d_year) FROM date_dim) AS max_year
FROM catalog_sales cs
JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
WHERE d.d_date BETWEEN DATE '2020-01-01' AND DATE '2020-12-31'
  AND cs.cs_net_profit > (SELECT avg_profit FROM avg_catalog_profit)
  AND EXISTS (
      SELECT 1
      FROM store_returns sr
      JOIN date_dim d2 ON sr.sr_returned_date_sk = d2.d_date_sk
      WHERE sr.sr_customer_sk = c.c_customer_sk
        AND d2.d_date BETWEEN DATE '2020-01-01' AND DATE '2020-12-31'
  )
GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name

UNION ALL

SELECT
    c.c_customer_id AS customer_id,
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
    'store_loss' AS metric_type,
    SUM(sr.sr_net_loss) AS metric_amount,
    (SELECT MAX(d_year) FROM date_dim) AS max_year
FROM store_returns sr
JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
WHERE d.d_date BETWEEN DATE '2020-01-01' AND DATE '2020-12-31'
  AND EXISTS (
      SELECT 1
      FROM catalog_sales cs2
      JOIN date_dim d2 ON cs2.cs_sold_date_sk = d2.d_date_sk
      WHERE cs2.cs_bill_customer_sk = c.c_customer_sk
        AND cs2.cs_net_profit > (SELECT avg_profit FROM avg_catalog_profit)
        AND d2.d_date BETWEEN DATE '2020-01-01' AND DATE '2020-12-31'
  )
GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name

ORDER BY metric_amount DESC
LIMIT 100
