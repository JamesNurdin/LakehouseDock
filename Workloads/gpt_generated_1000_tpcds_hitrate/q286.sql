WITH store_agg AS (
    SELECT
        s.s_store_name AS src_name,
        i.i_category AS category,
        SUM(ss.ss_net_paid) AS total_sales,
        CASE WHEN SUM(ss.ss_net_paid) > 50000 THEN 'High' ELSE 'Low' END AS sales_level,
        regexp_extract(i.i_product_name, '(\\w+)', 1) AS prod_word
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    WHERE s.s_store_name LIKE '%Store%'
      AND regexp_like(i.i_product_name, '^[A-Za-z]{3,}$')
      AND substr(i.i_category, 1, 1) = 'E'
      AND t.t_hour BETWEEN 9 AND 17
    GROUP BY s.s_store_name, i.i_category, i.i_product_name
),
web_agg AS (
    SELECT
        w.web_name AS src_name,
        i.i_category AS category,
        SUM(ws.ws_net_paid) AS total_sales,
        CASE WHEN SUM(ws.ws_net_paid) > 50000 THEN 'High' ELSE 'Low' END AS sales_level,
        regexp_extract(i.i_product_name, '(\\w+)', 1) AS prod_word
    FROM web_sales ws
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    WHERE w.web_name LIKE '%Online%'
      AND regexp_like(i.i_product_name, '^[A-Za-z]{3,}$')
      AND substr(i.i_category, 1, 1) = 'E'
      AND t.t_hour BETWEEN 9 AND 17
    GROUP BY w.web_name, i.i_category, i.i_product_name
)
SELECT src_name, category, total_sales, sales_level
FROM (
    SELECT src_name, category, total_sales, sales_level FROM store_agg
    UNION DISTINCT
    SELECT src_name, category, total_sales, sales_level FROM web_agg
) AS u
ORDER BY total_sales DESC
LIMIT 100
