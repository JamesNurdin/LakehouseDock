WITH channel_profits AS (
    SELECT
        s.s_store_id AS store_id,
        sm.sm_type AS ship_mode_type,
        SUM(ss.ss_net_profit) AS store_sales_profit,
        SUM(cs.cs_net_profit) AS catalog_sales_profit,
        SUM(ws.ws_net_profit) AS web_sales_profit,
        SUM(cr.cr_net_loss) AS catalog_return_loss,
        SUM(wr.wr_net_loss) AS web_return_loss
    FROM time_dim t
    JOIN store_sales ss
        ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN customer_address ca_ss
        ON ss.ss_addr_sk = ca_ss.ca_address_sk
    JOIN catalog_sales cs
        ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer_address ca_cs_bill
        ON cs.cs_bill_addr_sk = ca_cs_bill.ca_address_sk
    JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = cs.cs_item_sk
    JOIN ship_mode sm_cr
        ON cr.cr_ship_mode_sk = sm_cr.sm_ship_mode_sk
    JOIN web_sales ws
        ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN ship_mode sm_ws
        ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
    JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
        AND wr.wr_item_sk = ws.ws_item_sk
    WHERE
        t.t_sub_shift = 'morning'
        AND t.t_hour BETWEEN 8 AND 12
        AND sm.sm_type = 'AIR'
        AND s.s_state = 'CA'
        AND ca_ss.ca_country = 'United States'
        AND EXISTS (
            SELECT 1
            FROM web_page wp
            WHERE wp.wp_web_page_sk = ws.ws_web_page_sk
              AND wp.wp_type = 'product'
        )
        AND NOT EXISTS (
            SELECT 1
            FROM catalog_returns cr2
            WHERE cr2.cr_order_number = cs.cs_order_number
        )
    GROUP BY s.s_store_id, sm.sm_type
)
SELECT
    store_id,
    ship_mode_type,
    store_sales_profit,
    catalog_sales_profit,
    web_sales_profit,
    total_profit,
    avg_total_profit_overall
FROM (
    SELECT
        store_id,
        ship_mode_type,
        store_sales_profit,
        catalog_sales_profit,
        web_sales_profit,
        (store_sales_profit + catalog_sales_profit + web_sales_profit
         - COALESCE(catalog_return_loss, 0) - COALESCE(web_return_loss, 0)) AS total_profit,
        AVG(store_sales_profit + catalog_sales_profit + web_sales_profit
            - COALESCE(catalog_return_loss, 0) - COALESCE(web_return_loss, 0))
            OVER () AS avg_total_profit_overall
    FROM channel_profits
) t
WHERE total_profit > avg_total_profit_overall
ORDER BY total_profit DESC
LIMIT 20
