WITH store_sales_sample AS (
       SELECT *
       FROM store_sales TABLESAMPLE BERNOULLI (10)
   ),
   web_sales_sample AS (
       SELECT *
       FROM web_sales TABLESAMPLE BERNOULLI (10)
   )
SELECT *
FROM (
       SELECT
           'Store' AS channel,
           s.s_store_name AS entity_name,
           SUM(ss.ss_net_paid) AS total_revenue,
           CASE WHEN SUM(ss.ss_quantity) > 10 THEN 'High' ELSE 'Low' END AS quantity_flag
       FROM store_sales_sample ss
       JOIN store s ON ss.ss_store_sk = s.s_store_sk
       JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
       JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
       WHERE d.d_year = 2001
         AND s.s_store_name LIKE '%Garden%'
         AND regexp_like(p.p_promo_name, '(?i)discount')
       GROUP BY s.s_store_name
       UNION DISTINCT
       SELECT
           'Web' AS channel,
           ws_site.web_name AS entity_name,
           SUM(ws.ws_net_paid) AS total_revenue,
           CASE WHEN SUM(ws.ws_quantity) > 10 THEN 'High' ELSE 'Low' END AS quantity_flag
       FROM web_sales_sample ws
       JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
       JOIN date_dim d2 ON ws.ws_sold_date_sk = d2.d_date_sk
       JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
       WHERE d2.d_year = 2001
         AND ws_site.web_name LIKE '%Online%'
         AND regexp_extract(wp.wp_url, 'https?://([^/]+)/', 1) = 'www.example.com'
       GROUP BY ws_site.web_name
   ) AS combined
ORDER BY total_revenue DESC, entity_name
OFFSET 0 LIMIT 100
