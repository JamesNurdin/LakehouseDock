WITH
  store_loss AS (
    SELECT
      'store' AS source_type,
      s.s_store_id AS location_id,
      CONCAT(s.s_store_name, ' - ', s.s_city) AS location_desc,
      SUM(sr.sr_net_loss) AS net_loss_total
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE REGEXP_LIKE(r.r_reason_desc, '(?i)damage')
      AND s.s_store_name LIKE 'A%'
    GROUP BY s.s_store_id, s.s_store_name, s.s_city
  ),
  catalog_loss AS (
    SELECT
      'catalog' AS source_type,
      cp.cp_catalog_page_id AS location_id,
      cp.cp_description AS location_desc,
      SUM(cr.cr_net_loss) AS net_loss_total
    FROM catalog_returns cr
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE REGEXP_LIKE(r.r_reason_desc, '(?i)damage')
      AND REGEXP_EXTRACT(cp.cp_description, '(?i).*shirt.*') IS NOT NULL
    GROUP BY cp.cp_catalog_page_id, cp.cp_description
  ),
  combined AS (
    SELECT * FROM store_loss
    UNION ALL
    SELECT * FROM catalog_loss
  )
SELECT
  source_type,
  location_id,
  location_desc,
  net_loss_total,
  CASE
    WHEN net_loss_total > 10000 THEN 'High'
    WHEN net_loss_total > 0 THEN 'Medium'
    ELSE 'Low'
  END AS loss_category,
  net_loss_total / (SELECT AVG(net_loss_total) FROM combined) AS loss_vs_avg
FROM combined
ORDER BY net_loss_total DESC
LIMIT 100
