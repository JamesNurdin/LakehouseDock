WITH filtered_sales AS (
  SELECT
    ws.ws_web_site_sk,
    ws.ws_web_page_sk,
    ws.ws_net_paid,
    ws.ws_ext_discount_amt,
    ws.ws_order_number,
    wp.wp_url
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
  WHERE d.d_year = 2020
    AND regexp_like(wp.wp_url, '^https?://[^/]+/product/[0-9]+')
    AND wp.wp_url LIKE '%/category/%'
)
SELECT
  w.web_name,
  regexp_extract(wp.wp_url, '/product/([0-9]+)', 1) AS product_id,
  SUM(fs.ws_net_paid) AS total_net_paid,
  COUNT(DISTINCT fs.ws_order_number) AS order_count,
  AVG(fs.ws_ext_discount_amt) AS avg_discount,
  concat(w.web_name, ' - ', substring(CAST(SUM(fs.ws_net_paid) AS VARCHAR), 1, 10)) AS label
FROM filtered_sales fs
JOIN web_site w ON fs.ws_web_site_sk = w.web_site_sk
JOIN web_page wp ON fs.ws_web_page_sk = wp.wp_web_page_sk
WHERE fs.ws_ext_discount_amt > 0
GROUP BY w.web_name, regexp_extract(wp.wp_url, '/product/([0-9]+)', 1)
HAVING SUM(fs.ws_net_paid) > (
  SELECT avg_site_total FROM (
    SELECT AVG(site_total) AS avg_site_total
    FROM (
      SELECT ws2.ws_web_site_sk, SUM(ws2.ws_net_paid) AS site_total
      FROM web_sales ws2
      JOIN date_dim d2 ON ws2.ws_sold_date_sk = d2.d_date_sk
      WHERE d2.d_year = 2020
      GROUP BY ws2.ws_web_site_sk
    ) per_site
  ) avg_tab
)
ORDER BY total_net_paid DESC
LIMIT 100
