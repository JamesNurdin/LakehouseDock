WITH filtered_pages AS (
   SELECT
      wp.wp_web_page_sk,
      wp.wp_url,
      wp.wp_type,
      wp.wp_creation_date_sk,
      regexp_extract(wp.wp_url, 'product/([0-9]+)', 1) AS product_id
   FROM web_page wp
   WHERE regexp_like(wp.wp_url, '^https?://[^/]+/product/[0-9]+')
     AND wp.wp_type LIKE 'A%'
)
SELECT
   d.d_date,
   d.d_day_name,
   fp.wp_type,
   COUNT(DISTINCT fp.wp_web_page_sk) AS distinct_pages,
   SUM(ss.ss_net_profit) AS total_net_profit,
   AVG(ss.ss_sales_price) AS avg_sales_price,
   CONCAT(d.d_day_name, ':', fp.wp_type) AS day_type_label,
   MIN(fp.product_id) AS sample_product_id,
   SUBSTRING(fp.wp_url, 1, 30) AS url_prefix
FROM filtered_pages fp
JOIN date_dim d
   ON fp.wp_creation_date_sk = d.d_date_sk
JOIN store_sales ss
   ON ss.ss_sold_date_sk = d.d_date_sk
WHERE d.d_year = 2002
GROUP BY d.d_date,
         d.d_day_name,
         fp.wp_type,
         CONCAT(d.d_day_name, ':', fp.wp_type),
         SUBSTRING(fp.wp_url, 1, 30)
ORDER BY total_net_profit DESC
LIMIT 100
