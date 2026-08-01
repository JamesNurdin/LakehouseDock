WITH aggregated AS (
    SELECT
        w.w_warehouse_name,
        sm.sm_type,
        hd.hd_vehicle_count,
        td.t_hour,
        SUM(cs.cs_net_profit)               AS total_catalog_profit,
        SUM(ws.ws_net_paid)                 AS total_web_paid,
        SUM(sr.sr_net_loss)                 AS total_store_loss
    FROM
        catalog_sales cs
        JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
        JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
        JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
        JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
        JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
        JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
        LEFT JOIN catalog_returns cr ON cr.cr_item_sk = cs.cs_item_sk
            AND cr.cr_order_number = cs.cs_order_number
            AND cr.cr_call_center_sk = cc.cc_call_center_sk
        JOIN store_sales ss ON ss.ss_sold_time_sk = td.t_time_sk
            AND ss.ss_customer_sk = c.c_customer_sk
        JOIN store_returns sr ON sr.sr_item_sk = ss.ss_item_sk
            AND sr.sr_ticket_number = ss.ss_ticket_number
        JOIN web_sales ws ON ws.ws_sold_time_sk = td.t_time_sk
            AND ws.ws_bill_customer_sk = c.c_customer_sk
        JOIN web_site wsi ON ws.ws_web_site_sk = wsi.web_site_sk
        -- additional dimension joins for store returns
        JOIN time_dim td_sr ON sr.sr_return_time_sk = td_sr.t_time_sk
        JOIN customer_address ca_sr ON sr.sr_addr_sk = ca_sr.ca_address_sk
        JOIN household_demographics hd_sr ON sr.sr_hdemo_sk = hd_sr.hd_demo_sk
        JOIN customer c_sr ON sr.sr_customer_sk = c_sr.c_customer_sk
        -- ship mode and warehouse for web sales (different aliases)
        JOIN ship_mode sm_ws ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
        JOIN warehouse w_ws ON ws.ws_warehouse_sk = w_ws.w_warehouse_sk
    WHERE
        cc.cc_state = 'CA'
        AND sm.sm_code = 'AIR'
        AND ca.ca_city = 'San Jose'
        AND hd.hd_vehicle_count > 0
        AND ws.ws_net_paid > 1000
        AND EXISTS (
            SELECT 1
            FROM reason r
            WHERE r.r_reason_sk = sr.sr_reason_sk
                AND r.r_reason_desc LIKE '%damage%'
        )
    GROUP BY
        w.w_warehouse_name,
        sm.sm_type,
        hd.hd_vehicle_count,
        td.t_hour
    HAVING
        SUM(cs.cs_net_profit) > 5000
)
SELECT
    a.w_warehouse_name,
    a.sm_type,
    a.hd_vehicle_count,
    a.t_hour,
    a.total_catalog_profit,
    a.total_web_paid,
    a.total_store_loss,
    ROW_NUMBER() OVER (PARTITION BY a.w_warehouse_name ORDER BY a.total_catalog_profit DESC) AS rn
FROM aggregated a
ORDER BY a.total_catalog_profit DESC
LIMIT 100
