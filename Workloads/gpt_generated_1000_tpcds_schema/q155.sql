WITH store_part AS (
  SELECT
    'store' AS entity_type,
    s.s_store_id AS entity_id,
    s.s_store_name AS entity_name,
    s.s_city AS city,
    d.d_fy_year AS fiscal_year,
    (SELECT COUNT(*) FROM web_site ws WHERE ws.web_mkt_id = s.s_market_id) AS related_count
  FROM store s TABLESAMPLE BERNOULLI (10)
  JOIN date_dim d ON s.s_closed_date_sk = d.d_date_sk
  WHERE d.d_fy_year = 1914
    AND s.s_state = 'CA'
    AND EXISTS (
          SELECT 1 FROM web_site w
          WHERE w.web_state = s.s_state
            AND w.web_open_date_sk = d.d_date_sk
        )
),
website_part AS (
  SELECT
    'web_site' AS entity_type,
    w.web_site_id AS entity_id,
    w.web_name AS entity_name,
    w.web_city AS city,
    d.d_fy_year AS fiscal_year,
    (SELECT COUNT(*) FROM store s2 WHERE s2.s_market_id = w.web_mkt_id) AS related_count
  FROM web_site w TABLESAMPLE BERNOULLI (10)
  JOIN date_dim d ON w.web_open_date_sk = d.d_date_sk
  WHERE d.d_fy_year = 1914
    AND w.web_state = 'CA'
    AND w.web_tax_percentage > 0
    AND w.web_mkt_id IN (SELECT DISTINCT s_market_id FROM store WHERE s_state = 'CA')
)
SELECT *
FROM store_part
UNION ALL
SELECT *
FROM website_part
ORDER BY fiscal_year DESC, entity_type, entity_id
LIMIT 100
