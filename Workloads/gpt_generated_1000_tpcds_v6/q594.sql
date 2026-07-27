WITH warehouse_agg AS (
    SELECT
        w.w_warehouse_sk,
        w.w_warehouse_name,
        t.t_hour,
        sm.sm_carrier,
        sm.sm_type,
        wp.wp_link_count,
        SUM(ss.ss_net_profit) AS store_sales_profit,
        SUM(ws.ws_net_profit) AS web_sales_profit,
        SUM(cr.cr_net_loss) AS catalog_return_loss,
        SUM(sr.sr_net_loss) AS store_return_loss,
        SUM(i.inv_quantity_on_hand) AS total_inventory,
        CASE
            WHEN sm.sm_type = 'OVERNIGHT' THEN 'High'
            ELSE 'Normal'
        END AS ship_type_category
    FROM
        time_dim t
        JOIN store_sales ss ON ss.ss_sold_time_sk = t.t_time_sk
        JOIN store_returns sr ON sr.sr_return_time_sk = t.t_time_sk
            AND sr.sr_item_sk = ss.ss_item_sk
            AND sr.sr_ticket_number = ss.ss_ticket_number
        JOIN catalog_returns cr ON cr.cr_returned_time_sk = t.t_time_sk
        JOIN ship_mode sm ON sm.sm_ship_mode_sk = cr.cr_ship_mode_sk
        JOIN warehouse w ON w.w_warehouse_sk = cr.cr_warehouse_sk
        JOIN web_sales ws ON ws.ws_sold_time_sk = t.t_time_sk
            AND ws.ws_warehouse_sk = w.w_warehouse_sk
            AND ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN web_page wp ON wp.wp_web_page_sk = ws.ws_web_page_sk
        JOIN inventory i ON i.inv_warehouse_sk = w.w_warehouse_sk
    WHERE
        sm.sm_carrier = 'FEDEX'
        AND cr.cr_return_ship_cost > 1000
        AND wp.wp_link_count >= 10
        AND t.t_hour BETWEEN 9 AND 17
    GROUP BY
        w.w_warehouse_sk,
        w.w_warehouse_name,
        t.t_hour,
        sm.sm_carrier,
        sm.sm_type,
        wp.wp_link_count,
        CASE
            WHEN sm.sm_type = 'OVERNIGHT' THEN 'High'
            ELSE 'Normal'
        END
)
SELECT
    w_warehouse_name,
    t_hour,
    ship_type_category,
    store_sales_profit,
    web_sales_profit,
    catalog_return_loss,
    store_return_loss,
    total_inventory,
    (store_sales_profit + web_sales_profit - catalog_return_loss - store_return_loss) AS total_profit,
    (SELECT AVG(ws2.ws_net_profit) FROM web_sales ws2) AS avg_ws_profit,
    RANK() OVER (ORDER BY (store_sales_profit + web_sales_profit - catalog_return_loss - store_return_loss) DESC) AS profit_rank
FROM
    warehouse_agg
WHERE
    (store_sales_profit + web_sales_profit - catalog_return_loss - store_return_loss) > 50000
ORDER BY
    profit_rank,
    w_warehouse_name
LIMIT 100
