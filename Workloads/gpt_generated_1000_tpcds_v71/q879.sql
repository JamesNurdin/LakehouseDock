SELECT
  w.w_warehouse_name,
  d_s.d_year,
  d_s.d_week_seq,
  COUNT(DISTINCT cs.cs_order_number) AS orders,
  SUM(cs.cs_ext_sales_price) AS total_sales,
  MAX(regexp_extract(wp.wp_url, 'https?://([^/]+)/', 1)) FILTER (WHERE regexp_like(wp.wp_url, '^https?://.*\\.com/')) AS example_com_domain,
  MIN(substr(wp.wp_url, 1, 15)) AS url_prefix_sample
FROM catalog_sales cs
JOIN date_dim d_s ON cs.cs_sold_date_sk = d_s.d_date_sk
JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN web_page wp ON wp.wp_creation_date_sk = d_s.d_date_sk
WHERE wp.wp_type LIKE 'C%'
  AND regexp_like(wp.wp_url, '^https?://')
  AND regexp_extract(wp.wp_url, 'https?://([^/]+)/', 1) IS NOT NULL
GROUP BY w.w_warehouse_name, d_s.d_year, d_s.d_week_seq
ORDER BY total_sales DESC, w.w_warehouse_name
LIMIT 100
