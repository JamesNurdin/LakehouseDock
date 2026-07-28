WITH date_2000 AS (
    SELECT d_date_sk, d_year
    FROM date_dim
    WHERE d_year = 2000
)
SELECT sale_year,
       source_type,
       entity_name,
       total_sales,
       sales_category
FROM (
    SELECT d.d_year AS sale_year,
           'Store' AS source_type,
           s.s_store_name AS entity_name,
           SUM(ss.ss_net_paid) AS total_sales,
           CASE
               WHEN SUM(ss.ss_net_paid) > 100000 THEN 'High'
               WHEN SUM(ss.ss_net_paid) > 50000 THEN 'Medium'
               ELSE 'Low'
           END AS sales_category
    FROM store_sales ss
    INNER JOIN date_2000 d ON ss.ss_sold_date_sk = d.d_date_sk
    INNER JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE EXISTS (
        SELECT 1
        FROM promotion p
        WHERE p.p_promo_sk = ss.ss_promo_sk
          AND p.p_discount_active = 'Y'
    )
    GROUP BY d.d_year, s.s_store_name

    UNION ALL

    SELECT d.d_year AS sale_year,
           'Web' AS source_type,
           w.web_name AS entity_name,
           SUM(ws.ws_net_paid) AS total_sales,
           CASE
               WHEN SUM(ws.ws_net_paid) > 100000 THEN 'High'
               WHEN SUM(ws.ws_net_paid) > 50000 THEN 'Medium'
               ELSE 'Low'
           END AS sales_category
    FROM web_sales ws
    INNER JOIN date_2000 d ON ws.ws_sold_date_sk = d.d_date_sk
    INNER JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE EXISTS (
        SELECT 1
        FROM promotion p
        WHERE p.p_promo_sk = ws.ws_promo_sk
          AND p.p_discount_active = 'Y'
    )
    GROUP BY d.d_year, w.web_name
) AS combined
ORDER BY total_sales DESC
LIMIT 100
