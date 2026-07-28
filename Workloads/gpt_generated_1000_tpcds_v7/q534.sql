WITH base AS (
    SELECT
        d.d_year,
        d.d_date,
        cr.cr_return_quantity,
        cc.cc_state,
        cp.cp_department,
        i.i_item_id,
        i.i_manufact_id,
        p.p_discount_active,
        r.r_reason_desc,
        sm.sm_type,
        w.w_state,
        c.c_customer_id,
        hd.hd_buy_potential,
        t.t_hour,
        s.s_store_name,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_net_profit,
        ws.ws_ext_sales_price,
        we.web_site_id,
        we.web_name
    FROM date_dim d
    INNER JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
    INNER JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    INNER JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    INNER JOIN item i ON cr.cr_item_sk = i.i_item_sk
    INNER JOIN promotion p ON p.p_item_sk = i.i_item_sk
    INNER JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    INNER JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    INNER JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    INNER JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    INNER JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    INNER JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
    INNER JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    INNER JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
    INNER JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
    INNER JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk
)
SELECT
    d_year,
    i_item_id,
    c_customer_id,
    ws_order_number,
    ws_quantity,
    ws_net_profit,
    CASE WHEN p_discount_active = 'Y' THEN ws_net_profit * 1.10 ELSE ws_net_profit END AS adjusted_profit,
    SUM(ws_net_profit) OVER (PARTITION BY web_site_id ORDER BY ws_net_profit DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_profit,
    RANK() OVER (PARTITION BY web_site_id ORDER BY ws_net_profit DESC) AS profit_rank,
    DENSE_RANK() OVER (PARTITION BY web_site_id ORDER BY ws_quantity DESC) AS quantity_rank
FROM base
WHERE d_year = 2001
  AND i_manufact_id IN (26, 214)
  AND cc_state = 'CA'
  AND w_state = 'TX'
  AND t_hour BETWEEN 8 AND 12
  AND p_discount_active = 'Y'
ORDER BY web_site_id, profit_rank
LIMIT 100
