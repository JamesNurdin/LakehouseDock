WITH joined_data AS (
    SELECT
        ws.ws_order_number,
        ws.ws_ext_sales_price,
        ws.ws_sales_price,
        ws.ws_net_paid_inc_tax,
        ws.ws_sold_date_sk,
        ca.ca_state,
        hd.hd_vehicle_count,
        sm.sm_carrier,
        sm.sm_ship_mode_id,
        w.w_warehouse_name,
        cr.cr_net_loss,
        wr.wr_net_loss,
        ss.ss_net_profit
    FROM web_sales ws
    JOIN web_site web
        ON ws.ws_web_site_sk = web.web_site_sk
    JOIN ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN customer_address ca
        ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd
        ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN web_returns wr
        ON ws.ws_order_number = wr.wr_order_number
        AND ws.ws_item_sk = wr.wr_item_sk
    LEFT JOIN catalog_returns cr
        ON w.w_warehouse_sk = cr.cr_warehouse_sk
        AND cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN store_sales ss
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
        AND ss.ss_addr_sk = ca.ca_address_sk
    WHERE
        ws.ws_ext_sales_price > 1000
        AND ws.ws_sales_price BETWEEN 10 AND 100
        AND ws.ws_net_paid_inc_tax < 5000
        AND ca.ca_state = 'CA'
        AND hd.hd_vehicle_count >= 2
        AND sm.sm_carrier = 'AIRBORNE'
        AND ws.ws_sold_date_sk BETWEEN 2450000 AND 2450100
        AND web.web_country = 'United States'
        AND ss.ss_quantity > 1
        AND ss.ss_net_profit > 0
)
SELECT
    carrier,
    state,
    COUNT(DISTINCT order_number) AS distinct_orders,
    SUM(total_net_loss) AS total_net_loss,
    AVG(total_net_loss) AS avg_net_loss_per_order
FROM (
    SELECT
        sm_carrier AS carrier,
        ca_state AS state,
        ws_order_number AS order_number,
        COALESCE(cr_net_loss, 0) + COALESCE(wr_net_loss, 0) AS total_net_loss
    FROM joined_data
) agg
GROUP BY carrier, state
HAVING SUM(total_net_loss) > 0
ORDER BY total_net_loss DESC
LIMIT 100
