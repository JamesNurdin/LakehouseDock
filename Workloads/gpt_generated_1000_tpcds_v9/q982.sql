WITH store_profit AS (
  SELECT
    'store_sales' AS source_type,
    concat(s.s_city, ', ', s.s_state) AS description,
    sum(ss.ss_net_profit) AS total_amount
  FROM store_sales ss
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  WHERE d.d_year = 2002
    AND s.s_store_name LIKE '%Store%'
    AND (
      s.s_city LIKE 'A%'
      OR s.s_city LIKE 'E%'
      OR s.s_city LIKE 'I%'
      OR s.s_city LIKE 'O%'
      OR s.s_city LIKE 'U%'
    )
  GROUP BY concat(s.s_city, ', ', s.s_state)
),
catalog_loss AS (
  SELECT
    'catalog_returns' AS source_type,
    regexp_extract(r.r_reason_desc, '(better price)', 1) AS description,
    sum(cr.cr_net_loss) AS total_amount
  FROM catalog_returns cr
  JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
  JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
  WHERE d.d_year = 2002
    AND regexp_like(r.r_reason_desc, '(?i)better price')
  GROUP BY regexp_extract(r.r_reason_desc, '(better price)', 1)
)
SELECT DISTINCT source_type, description, total_amount
FROM store_profit
UNION DISTINCT
SELECT DISTINCT source_type, description, total_amount
FROM catalog_loss
ORDER BY total_amount DESC
LIMIT 100
