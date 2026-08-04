WITH agg AS (
    SELECT i.i_manufact,
           REGEXP_EXTRACT(i.i_product_name, '(\\w+)$') AS product_suffix,
           SUM(ws.ws_ext_sales_price) AS total_sales,
           COUNT(*) AS order_count
    FROM tpcds.web_sales ws TABLESAMPLE BERNOULLI (10)
    JOIN tpcds.item i ON ws.ws_item_sk = i.i_item_sk
    JOIN tpcds.warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN tpcds.ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN tpcds.web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN tpcds.promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE REGEXP_LIKE(i.i_manufact, '^es')
      AND wp.wp_url LIKE '%foo.com%'
      AND sm.sm_code = 'AIR'
    GROUP BY i.i_manufact,
             REGEXP_EXTRACT(i.i_product_name, '(\\w+)$')
)
SELECT i_manufact,
       product_suffix,
       total_sales,
       order_count,
       ROW_NUMBER() OVER (PARTITION BY i_manufact ORDER BY total_sales DESC) AS rn
FROM agg
ORDER BY total_sales DESC
LIMIT 100
