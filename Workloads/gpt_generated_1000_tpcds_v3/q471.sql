WITH order_metrics AS (
    SELECT
        cs.cs_order_number,
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        cs.cs_item_sk,
        cs.cs_quantity,
        cs.cs_net_paid,
        cs.cs_net_profit,
        cs.cs_call_center_sk,
        cs.cs_ship_mode_sk,
        cs.cs_warehouse_sk,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        (cs.cs_net_profit - COALESCE(cr.cr_return_amount, 0)) AS net_profit_adj
    FROM catalog_sales cs
    LEFT JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = cs.cs_item_sk
),

distinct_orders AS (
    SELECT DISTINCT
        om.cs_order_number,
        om.cs_item_sk,
        om.cs_quantity,
        om.cs_net_paid,
        om.net_profit_adj,
        om.cs_call_center_sk,
        om.cs_ship_mode_sk,
        om.cs_warehouse_sk,
        om.cs_sold_date_sk,
        om.cs_sold_time_sk
    FROM order_metrics om
    WHERE om.cs_quantity > 5
)

SELECT
    d.d_year,
    d.d_month_seq,
    d.d_date,
    cc.cc_name,
    sm.sm_type,
    w.w_warehouse_name,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    om.cs_order_number,
    om.cs_item_sk,
    om.cs_quantity,
    om.cs_net_paid,
    om.net_profit_adj,
    CASE WHEN om.net_profit_adj > 0 THEN 'POSITIVE' ELSE 'NON_POSITIVE' END AS profit_category,
    ROW_NUMBER() OVER (PARTITION BY cc.cc_name ORDER BY om.net_profit_adj DESC) AS profit_rank,
    ss.ss_quantity AS store_quantity,
    ss.ss_net_paid AS store_net_paid,
    ss.ss_net_profit AS store_net_profit,
    sr.sr_return_quantity,
    sr.sr_return_amt,
    r.r_reason_desc,
    inv.inv_quantity_on_hand,
    ws.ws_quantity AS web_quantity,
    ws.ws_net_paid AS web_net_paid,
    ws.ws_net_profit AS web_net_profit,
    wp.wp_type,
    we.web_name
FROM distinct_orders om
JOIN date_dim d
    ON om.cs_sold_date_sk = d.d_date_sk
JOIN time_dim t
    ON om.cs_sold_time_sk = t.t_time_sk
JOIN call_center cc
    ON om.cs_call_center_sk = cc.cc_call_center_sk
    AND cc.cc_open_date_sk = d.d_date_sk
JOIN ship_mode sm
    ON om.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w
    ON om.cs_warehouse_sk = w.w_warehouse_sk
JOIN store_sales ss
    ON ss.ss_sold_date_sk = d.d_date_sk
    AND ss.ss_sold_time_sk = t.t_time_sk
JOIN household_demographics hd
    ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN store_returns sr
    ON sr.sr_returned_date_sk = d.d_date_sk
    AND sr.sr_return_time_sk = t.t_time_sk
    AND sr.sr_ticket_number = ss.ss_ticket_number
JOIN reason r
    ON sr.sr_reason_sk = r.r_reason_sk
JOIN inventory inv
    ON inv.inv_date_sk = d.d_date_sk
    AND inv.inv_warehouse_sk = w.w_warehouse_sk
JOIN web_sales ws
    ON ws.ws_sold_date_sk = d.d_date_sk
    AND ws.ws_sold_time_sk = t.t_time_sk
JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
    AND wp.wp_creation_date_sk = d.d_date_sk
JOIN web_site we
    ON ws.ws_web_site_sk = we.web_site_sk
    AND we.web_open_date_sk = d.d_date_sk
WHERE
    d.d_year = 2001
    AND sm.sm_type = 'AIR'
    AND cc.cc_gmt_offset BETWEEN -5 AND 5
    AND ib.ib_lower_bound >= 50000
    AND ws.ws_quantity > 0
    AND EXISTS (
        SELECT 1
        FROM catalog_returns cr2
        WHERE cr2.cr_order_number = om.cs_order_number
          AND cr2.cr_return_amount > 0
    )
ORDER BY profit_rank, d.d_year, d.d_month_seq
LIMIT 100
