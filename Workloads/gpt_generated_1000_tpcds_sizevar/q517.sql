WITH page_sales AS (
  SELECT
    wp.wp_web_page_sk,
    wp.wp_url,
    c.c_first_name,
    c.c_last_name,
    ws.ws_sold_date_sk,
    ws.ws_net_paid,
    split(wp.wp_url, '/') AS url_parts
  FROM web_page wp
  JOIN web_sales ws ON ws.ws_web_page_sk = wp.wp_web_page_sk
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
  WHERE d.d_year = 2001
    AND regexp_like(wp.wp_url, '^https?://.*example\\.com')
    AND wp.wp_url LIKE '%/sale%'
),
exploded AS (
  SELECT
    ps.wp_web_page_sk,
    ps.wp_url,
    ps.c_first_name,
    ps.c_last_name,
    ps.ws_sold_date_sk,
    ps.ws_net_paid,
    part AS url_segment
  FROM page_sales ps
  CROSS JOIN UNNEST(ps.url_parts) AS t(part)
)
SELECT
  e.wp_url,
  e.url_segment,
  concat(e.c_first_name, ' ', e.c_last_name) AS customer_full_name,
  sum(e.ws_net_paid) AS total_net_paid,
  CASE
    WHEN sum(e.ws_net_paid) > 20000 THEN 'HIGH'
    WHEN sum(e.ws_net_paid) > 5000 THEN 'MEDIUM'
    ELSE 'LOW'
  END AS sales_category,
  regexp_extract(e.wp_url, 'example\\.com/([^/]+)', 1) AS extracted_section
FROM exploded e
WHERE e.wp_url NOT IN (
    SELECT wp2.wp_url
    FROM web_page wp2
    JOIN web_returns wr ON wp2.wp_web_page_sk = wr.wr_web_page_sk
    WHERE wr.wr_net_loss > 5000
  )
GROUP BY
  e.wp_url,
  e.url_segment,
  e.c_first_name,
  e.c_last_name,
  regexp_extract(e.wp_url, 'example\\.com/([^/]+)', 1)
ORDER BY total_net_paid DESC
LIMIT 100
