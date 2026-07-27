WITH catalog_agg AS (
    SELECT
        w.w_warehouse_name AS warehouse_name,
        'catalog_sales' AS source,
        SUM(cs.cs_net_paid) AS total_amount,
        CASE WHEN SUM(cs.cs_net_paid) > 100000 THEN 'High' ELSE 'Low' END AS sales_level
    FROM catalog_sales cs
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE p.p_channel_tv = 'Y'
    GROUP BY w.w_warehouse_name
),
returns_agg AS (
    SELECT
        w.w_warehouse_name AS warehouse_name,
        'web_returns' AS source,
        SUM(wr.wr_return_amt) AS total_amount,
        CASE WHEN SUM(wr.wr_return_amt) > 50000 THEN 'High' ELSE 'Low' END AS sales_level
    FROM web_returns wr
    JOIN web_sales ws ON wr.wr_order_number = ws.ws_order_number
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE wp.wp_type = 'ad'
    GROUP BY w.w_warehouse_name
)
SELECT *
FROM catalog_agg
UNION ALL
SELECT *
FROM returns_agg
ORDER BY warehouse_name, source
