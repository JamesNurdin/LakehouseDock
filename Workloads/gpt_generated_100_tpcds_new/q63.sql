WITH sales AS (
  SELECT
    d.d_year,
    d.d_month_seq,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    COUNT(DISTINCT ss.ss_customer_sk) AS distinct_customers,
    (SELECT MAX(i.inv_quantity_on_hand)
       FROM inventory i
      WHERE i.inv_date_sk = d.d_date_sk) AS max_inventory_qty
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
  WHERE cd.cd_gender = 'M'
    AND d.d_current_month = 'Y'
  GROUP BY d.d_year, d.d_month_seq, d.d_date_sk
),
web AS (
  SELECT
    d2.d_year,
    d2.d_month_seq,
    COUNT(DISTINCT wp.wp_url) FILTER (WHERE regexp_like(wp.wp_url, '^https?://.*product.*$')) AS distinct_product_urls,
    COUNT(DISTINCT wp.wp_url) FILTER (WHERE wp.wp_type LIKE 'article%') AS distinct_article_urls,
    COUNT(DISTINCT ws.web_manager) FILTER (WHERE ws.web_manager IS NOT NULL) AS distinct_site_managers
  FROM web_page wp
  JOIN date_dim d2 ON wp.wp_creation_date_sk = d2.d_date_sk
  LEFT JOIN web_site ws ON ws.web_open_date_sk = d2.d_date_sk
  WHERE wp.wp_char_count > 2000
    AND wp.wp_url LIKE '%.com/%'
  GROUP BY d2.d_year, d2.d_month_seq
)
SELECT
  s.d_year,
  s.d_month_seq,
  s.total_sales,
  s.distinct_customers,
  s.max_inventory_qty,
  w.distinct_product_urls,
  w.distinct_article_urls,
  w.distinct_site_managers
FROM sales s
LEFT JOIN web w
  ON s.d_year = w.d_year
 AND s.d_month_seq = w.d_month_seq
ORDER BY s.total_sales DESC
LIMIT 100
