WITH
  store_returns_agg AS (
    SELECT
      'store_return' AS source,
      d.d_year AS year,
      cd.cd_credit_rating AS category,
      CAST(SUM(sr.sr_net_loss) AS double) AS metric_value,
      (SELECT AVG(sr2.sr_return_quantity) FROM store_returns sr2) AS avg_qty,
      CAST(NULL AS double) AS avg_url_len
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
      AND EXISTS (
        SELECT 1
        FROM store_returns sr2
        WHERE sr2.sr_customer_sk = sr.sr_customer_sk
          AND sr2.sr_return_amt > 500
      )
    GROUP BY d.d_year, cd.cd_credit_rating
  ),
  web_page_agg AS (
    SELECT
      'web_page' AS source,
      d.d_year AS year,
      wp.wp_type AS category,
      CAST(SUM(wp.wp_char_count) AS double) AS metric_value,
      CAST(NULL AS double) AS avg_qty,
      AVG(l.url_len) AS avg_url_len
    FROM (
      SELECT * FROM web_page TABLESAMPLE BERNOULLI (5)
    ) wp
    JOIN date_dim d ON wp.wp_creation_date_sk = d.d_date_sk
    CROSS JOIN LATERAL (
      SELECT LENGTH(wp.wp_url) AS url_len
    ) l
    WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
    GROUP BY d.d_year, wp.wp_type
  )
SELECT
  source,
  year,
  category,
  metric_value,
  avg_qty,
  avg_url_len
FROM store_returns_agg
UNION ALL
SELECT
  source,
  year,
  category,
  metric_value,
  avg_qty,
  avg_url_len
FROM web_page_agg
LIMIT 100
