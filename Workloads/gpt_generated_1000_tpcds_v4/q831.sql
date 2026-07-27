SELECT
  w.w_warehouse_name,
  sm.sm_type,
  regexp_extract(wp.wp_url, 'https?://([^/]+)/', 1) AS domain,
  SUM(cr.cr_return_amount) AS total_return_amount,
  COUNT(*) AS returns_cnt
FROM tpcds.catalog_returns AS cr
JOIN tpcds.date_dim AS d
  ON cr.cr_returned_date_sk = d.d_date_sk
JOIN tpcds.web_page AS wp
  ON wp.wp_creation_date_sk = d.d_date_sk
JOIN tpcds.warehouse AS w
  ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN tpcds.ship_mode AS sm
  ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
WHERE d.d_year = 2022
  AND wp.wp_url LIKE '%promo%'
  AND regexp_like(wp.wp_url, '^https?://[^/]+\\.com/')
GROUP BY
  w.w_warehouse_name,
  sm.sm_type,
  regexp_extract(wp.wp_url, 'https?://([^/]+)/', 1)
ORDER BY total_return_amount DESC
LIMIT 100
