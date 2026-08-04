WITH sales_agg AS (
    SELECT
        i.i_item_id,
        i.i_product_name,
        SUM(cs.cs_net_profit) AS catalog_profit,
        SUM(ss.ss_net_profit) AS store_profit,
        SUM(ws.ws_net_profit) AS web_profit,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_orders,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_orders,
        COUNT(DISTINCT ws.ws_order_number) AS web_orders
    FROM
        catalog_sales cs
        JOIN item i ON cs.cs_item_sk = i.i_item_sk
        JOIN customer_address ca_cs ON cs.cs_bill_addr_sk = ca_cs.ca_address_sk
        JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
        JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
        LEFT JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk
        LEFT JOIN customer_address ca_ss ON ss.ss_addr_sk = ca_ss.ca_address_sk
        LEFT JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
        LEFT JOIN customer_address ca_ws ON ws.ws_bill_addr_sk = ca_ws.ca_address_sk
        LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
        LEFT JOIN ship_mode sm_ws ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
    WHERE
        cc.cc_tax_percentage > 0.05
        AND ca_cs.ca_country = 'United States'
        AND ws.ws_net_paid_inc_ship > 1000
    GROUP BY
        i.i_item_id,
        i.i_product_name
)
SELECT
    i_item_id,
    i_product_name,
    catalog_profit,
    store_profit,
    web_profit,
    (catalog_profit + store_profit + web_profit) / NULLIF((catalog_orders + store_orders + web_orders), 0) AS avg_profit_per_order
FROM sales_agg
WHERE (catalog_profit + store_profit + web_profit) > 5000
ORDER BY avg_profit_per_order DESC
LIMIT 20
