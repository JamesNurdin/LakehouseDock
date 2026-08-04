WITH sales_page AS (
  SELECT
    cp.cp_catalog_page_sk,
    cp.cp_catalog_page_id,
    cp.cp_description,
    cp.cp_type,
    SUBSTR(cp.cp_catalog_page_id, 1, 5) AS page_prefix,
    REGEXP_EXTRACT(cp.cp_description, '(\\d{4})', 1) AS year_in_desc,
    cs.cs_order_number,
    cs.cs_net_profit
  FROM tpcds.catalog_sales cs
  JOIN tpcds.catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  WHERE
    REGEXP_LIKE(cp.cp_description, '[A-Z]{3,}')
    AND cp.cp_type LIKE 'A%'
),

returns_agg AS (
  SELECT
    cr.cr_catalog_page_sk,
    COUNT(*) AS returns_cnt,
    COUNT(DISTINCT r.r_reason_id) AS distinct_reason_cnt
  FROM tpcds.catalog_returns cr
  JOIN tpcds.reason r
    ON cr.cr_reason_sk = r.r_reason_sk
  GROUP BY cr.cr_catalog_page_sk
)

SELECT
  sp.cp_catalog_page_id,
  sp.page_prefix,
  sp.year_in_desc,
  CONCAT(sp.cp_catalog_page_id, '_', COALESCE(sp.year_in_desc, 'UNK')) AS page_key,
  SUM(sp.cs_net_profit) AS total_net_profit,
  COUNT(DISTINCT sp.cs_order_number) AS distinct_orders,
  COALESCE(SUM(ra.returns_cnt), 0) AS total_returns,
  COALESCE(SUM(ra.distinct_reason_cnt), 0) AS distinct_reason_count
FROM sales_page sp
LEFT JOIN returns_agg ra
  ON sp.cp_catalog_page_sk = ra.cr_catalog_page_sk
GROUP BY
  sp.cp_catalog_page_id,
  sp.page_prefix,
  sp.year_in_desc,
  CONCAT(sp.cp_catalog_page_id, '_', COALESCE(sp.year_in_desc, 'UNK'))
ORDER BY total_net_profit DESC
LIMIT 100
