WITH
  sales AS (
    SELECT
      cs.cs_order_number AS order_number,
      cs.cs_item_sk AS item_sk,
      d.d_date AS event_date,
      cs.cs_ext_sales_price AS amount,
      CASE WHEN cs.cs_net_profit > 0 THEN 'PROFIT' ELSE 'LOSS' END AS flag,
      'SALE' AS record_type,
      regexp_extract(d.d_day_name, '(\\w+)', 1) AS day_prefix
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE regexp_like(d.d_day_name, '^Mon|Tue')
      AND d.d_year = 2001
  ),
  returns AS (
    SELECT
      cr.cr_order_number AS order_number,
      cr.cr_item_sk AS item_sk,
      d.d_date AS event_date,
      cr.cr_return_amount AS amount,
      CASE WHEN cr.cr_net_loss > 0 THEN 'LOSS' ELSE 'NO_LOSS' END AS flag,
      'RETURN' AS record_type,
      regexp_extract(d.d_holiday, '(\\w+)', 1) AS holiday_prefix
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE d.d_holiday LIKE '%Holiday%'
      AND d.d_year = 2001
  ),
  combined AS (
    SELECT order_number, item_sk, event_date, amount, flag, record_type
    FROM sales
    UNION ALL
    SELECT order_number, item_sk, event_date, amount, flag, record_type
    FROM returns
  )
SELECT
  c.order_number,
  c.item_sk,
  c.event_date,
  c.amount,
  c.flag,
  c.record_type,
  concat('ORD-', cast(c.order_number AS varchar)) AS order_key,
  substring(cast(c.amount AS varchar), 1, 5) AS amount_prefix
FROM combined c
WHERE NOT EXISTS (
  SELECT 1
  FROM web_returns wr
  JOIN date_dim dwr ON wr.wr_returned_date_sk = dwr.d_date_sk
  WHERE wr.wr_order_number = c.order_number
)
ORDER BY c.amount DESC, c.event_date
LIMIT 100
