WITH raw_data AS (
    SELECT
        cr.cr_order_number,
        cr.cr_return_amount,
        ws.ws_net_paid,
        ws.ws_net_profit,
        t.t_time,
        t.t_hour,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        ca.ca_state,
        ca.ca_city,
        s.s_store_name,
        s.s_state,
        sm.sm_code,
        sm.sm_type,
        hd.hd_vehicle_count,
        hd.hd_income_band_sk,
        ws.ws_quantity
    FROM catalog_returns cr
    JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN store_returns sr ON sr.sr_return_time_sk = t.t_time_sk
    JOIN web_sales ws ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN web_site web ON ws.ws_web_site_sk = web.web_site_sk
    WHERE
        t.t_hour BETWEEN 8 AND 12
        AND sm.sm_code = 'AIR'
        AND hd.hd_vehicle_count >= 1
        AND hd.hd_income_band_sk IN (7, 8, 12)
        AND s.s_state = 'CA'
        AND ws.ws_quantity > 5
        AND ws.ws_net_paid > 100
), agg_data AS (
    SELECT
        c_customer_id,
        c_first_name,
        c_last_name,
        ca_state,
        ca_city,
        s_store_name,
        sm_code,
        t_time,
        SUM(cr_return_amount) AS total_return_amount,
        SUM(ws_net_paid) AS total_net_paid,
        SUM(ws_net_profit) AS total_net_profit
    FROM raw_data
    GROUP BY
        c_customer_id,
        c_first_name,
        c_last_name,
        ca_state,
        ca_city,
        s_store_name,
        sm_code,
        t_time
)
SELECT
    c_customer_id,
    c_first_name,
    c_last_name,
    ca_state,
    ca_city,
    s_store_name,
    sm_code,
    t_time,
    total_return_amount,
    total_net_paid,
    CASE WHEN total_net_profit > 0 THEN 'Profit' ELSE 'Loss' END AS profit_category,
    RANK() OVER (PARTITION BY ca_state ORDER BY total_net_paid DESC) AS state_sales_rank
FROM agg_data
ORDER BY state_sales_rank, total_net_paid DESC
LIMIT 100
