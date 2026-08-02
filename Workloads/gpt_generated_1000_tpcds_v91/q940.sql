WITH base AS (
    SELECT
        w.w_state AS state,
        sm.sm_type AS ship_type,
        wp.wp_type AS page_type,
        r.r_reason_desc AS reason_desc,
        td.t_shift AS shift,
        SUM(ws.ws_net_paid) AS total_web_net_paid,
        SUM(wr.wr_return_amt) AS total_return_amt,
        SUM(ss.ss_net_paid) AS total_store_net_paid,
        SUM(inv.inv_quantity_on_hand) AS total_inventory_qty,
        COUNT(DISTINCT ws.ws_order_number) AS order_cnt
    FROM web_sales ws
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site site ON ws.ws_web_site_sk = site.web_site_sk
    JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN inventory inv ON w.w_warehouse_sk = inv.inv_warehouse_sk
    JOIN web_returns wr ON ws.ws_order_number = wr.wr_order_number
                      AND ws.ws_item_sk = wr.wr_item_sk
    JOIN time_dim td_ret ON wr.wr_returned_time_sk = td_ret.t_time_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN web_page wp_ret ON wr.wr_web_page_sk = wp_ret.wp_web_page_sk
    JOIN store_sales ss ON ss.ss_sold_time_sk = td.t_time_sk
    WHERE td.t_shift = 'first' AND td.t_am_pm = 'AM'
    GROUP BY w.w_state, sm.sm_type, wp.wp_type, r.r_reason_desc, td.t_shift
    UNION
    SELECT
        w.w_state AS state,
        sm.sm_type AS ship_type,
        wp.wp_type AS page_type,
        r.r_reason_desc AS reason_desc,
        td.t_shift AS shift,
        SUM(ws.ws_net_paid) AS total_web_net_paid,
        SUM(wr.wr_return_amt) AS total_return_amt,
        SUM(ss.ss_net_paid) AS total_store_net_paid,
        SUM(inv.inv_quantity_on_hand) AS total_inventory_qty,
        COUNT(DISTINCT ws.ws_order_number) AS order_cnt
    FROM web_sales ws
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site site ON ws.ws_web_site_sk = site.web_site_sk
    JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN inventory inv ON w.w_warehouse_sk = inv.inv_warehouse_sk
    JOIN web_returns wr ON ws.ws_order_number = wr.wr_order_number
                      AND ws.ws_item_sk = wr.wr_item_sk
    JOIN time_dim td_ret ON wr.wr_returned_time_sk = td_ret.t_time_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN web_page wp_ret ON wr.wr_web_page_sk = wp_ret.wp_web_page_sk
    JOIN store_sales ss ON ss.ss_sold_time_sk = td.t_time_sk
    WHERE td.t_shift = 'second' AND td.t_am_pm = 'PM'
    GROUP BY w.w_state, sm.sm_type, wp.wp_type, r.r_reason_desc, td.t_shift
)
SELECT
    state,
    ship_type,
    page_type,
    reason_desc,
    shift,
    total_web_net_paid,
    total_return_amt,
    total_store_net_paid,
    total_inventory_qty,
    order_cnt,
    RANK() OVER (PARTITION BY state ORDER BY total_web_net_paid DESC) AS sales_rank,
    SUM(total_web_net_paid) OVER (PARTITION BY state) AS state_cumulative_web_net_paid
FROM base
ORDER BY state, sales_rank
LIMIT 100
