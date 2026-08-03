WITH filtered_pages AS (
  SELECT
    wp_web_page_sk,
    wp_url,
    wp_type,
    wp_image_count,
    wp_rec_start_date,
    wp_rec_end_date,
    regexp_extract(wp_url, '(https?://[^/]+)') AS domain,
    wp_url || '/' || wp_type AS full_path
  FROM tpcds.web_page
  WHERE wp_url LIKE '%example%'
    AND regexp_like(wp_url, '^https?://')
),
sales_agg AS (
  SELECT
    ws_web_page_sk,
    SUM(ws_net_paid_inc_ship_tax) AS total_net_paid,
    COUNT(*) AS sales_cnt,
    AVG(ws_quantity) AS avg_qty
  FROM tpcds.web_sales
  WHERE ws_quantity > 0
  GROUP BY ws_web_page_sk
)
SELECT
  fp.wp_web_page_sk,
  fp.domain,
  fp.full_path,
  fp.wp_image_count,
  sa.total_net_paid,
  sa.sales_cnt,
  sa.avg_qty
FROM filtered_pages fp
FULL OUTER JOIN sales_agg sa
  ON fp.wp_web_page_sk = sa.ws_web_page_sk
WHERE fp.wp_web_page_sk NOT IN (
  SELECT ws_web_page_sk
  FROM tpcds.web_sales
  WHERE ws_web_page_sk IS NOT NULL
)
ORDER BY fp.wp_web_page_sk
LIMIT 100
