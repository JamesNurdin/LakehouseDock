WITH items_with_digits AS (
    SELECT i_item_sk,
           i_item_id,
           i_category,
           i_formulation,
           i_product_name
    FROM item
    WHERE regexp_like(i_formulation, '\\d{3}')
),
store_sales_agg AS (
    SELECT s.s_store_name,
           i.i_category,
           SUM(ss.ss_net_profit) AS store_net_profit,
           COUNT(DISTINCT ss.ss_customer_sk) AS store_customer_cnt,
           SUM(ss.ss_quantity) AS store_quantity
    FROM items_with_digits i
    JOIN store_sales ss
        ON ss.ss_item_sk = i.i_item_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN time_dim td
        ON ss.ss_sold_time_sk = td.t_time_sk
    WHERE td.t_hour BETWEEN 9 AND 17
    GROUP BY s.s_store_name, i.i_category
),
web_sales_agg AS (
    SELECT wsit.web_name AS web_site_name,
           i.i_category,
           SUM(ws.ws_net_profit) AS web_net_profit,
           COUNT(DISTINCT ws.ws_bill_customer_sk) AS web_customer_cnt,
           SUM(ws.ws_quantity) AS web_quantity
    FROM items_with_digits i
    JOIN web_sales ws
        ON ws.ws_item_sk = i.i_item_sk
    JOIN web_site wsit
        ON ws.ws_web_site_sk = wsit.web_site_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE wp.wp_url LIKE '%example.com%'
    GROUP BY wsit.web_name, i.i_category
)
SELECT ssa.s_store_name,
       wsa.web_site_name,
       ssa.i_category,
       ssa.store_net_profit,
       wsa.web_net_profit,
       (ssa.store_net_profit + wsa.web_net_profit) AS total_net_profit,
       ssa.store_customer_cnt,
       wsa.web_customer_cnt,
       CONCAT('Category: ', ssa.i_category) AS category_label
FROM store_sales_agg ssa
JOIN web_sales_agg wsa
    ON ssa.i_category = wsa.i_category
ORDER BY total_net_profit DESC
LIMIT 100
