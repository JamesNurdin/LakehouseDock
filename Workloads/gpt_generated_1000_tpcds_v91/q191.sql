WITH combined_sales AS (
  SELECT
    c.c_customer_id AS customer_id,
    d.d_year AS year,
    SUM(sr.sr_net_loss) AS total_amount,
    'store' AS source_type
  FROM store_returns sr
  JOIN date_dim d
    ON sr.sr_returned_date_sk = d.d_date_sk
  JOIN customer c
    ON sr.sr_customer_sk = c.c_customer_sk
  GROUP BY c.c_customer_id, d.d_year

  UNION ALL

  SELECT
    c.c_customer_id AS customer_id,
    d.d_year AS year,
    SUM(ws.ws_net_paid) AS total_amount,
    'web' AS source_type
  FROM web_sales ws
  JOIN date_dim d
    ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN customer c
    ON ws.ws_bill_customer_sk = c.c_customer_sk
  GROUP BY c.c_customer_id, d.d_year
)
SELECT
  cs.customer_id,
  cs.year,
  cs.total_amount,
  cs.source_type,
  (
    SELECT COUNT(DISTINCT ws_inner.ws_promo_sk)
    FROM web_sales ws_inner
    JOIN customer c_inner
      ON ws_inner.ws_bill_customer_sk = c_inner.c_customer_sk
    JOIN date_dim d_inner
      ON ws_inner.ws_sold_date_sk = d_inner.d_date_sk
    WHERE c_inner.c_customer_id = cs.customer_id
      AND d_inner.d_year = cs.year
  ) AS promo_count
FROM combined_sales cs
ORDER BY cs.total_amount DESC, cs.year, cs.customer_id
LIMIT 100
