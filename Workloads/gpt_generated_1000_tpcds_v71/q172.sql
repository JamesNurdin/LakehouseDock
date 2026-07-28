WITH joined_data AS (
    SELECT
        wh.w_warehouse_id,
        wh.w_state,
        cp.cp_department,
        ib.ib_upper_bound,
        i.i_item_id,
        i.i_current_price,
        sr.sr_net_loss,
        ws.ws_net_profit,
        c.c_customer_id,
        td.t_hour,
        r.r_reason_desc
    FROM store_returns sr
    JOIN time_dim td ON sr.sr_return_time_sk = td.t_time_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN inventory inv ON i.i_item_sk = inv.inv_item_sk
    JOIN warehouse wh ON inv.inv_warehouse_sk = wh.w_warehouse_sk
    JOIN catalog_returns cr ON wh.w_warehouse_sk = cr.cr_warehouse_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN web_sales ws ON i.i_item_sk = ws.ws_item_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site wsit ON ws.ws_web_site_sk = wsit.web_site_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE ib.ib_upper_bound <= 200000
      AND wh.w_state = 'CA'
      AND cp.cp_department = 'Electronics'
      AND td.t_hour BETWEEN 9 AND 17
      AND i.i_current_price > 20
),
aggregated AS (
    SELECT
        w_warehouse_id,
        w_state,
        cp_department,
        SUM(sr_net_loss) AS total_net_loss,
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT c_customer_id) AS distinct_customers,
        AVG(i_current_price) AS avg_item_price,
        i_current_price
    FROM joined_data
    WHERE i_current_price > (
        SELECT AVG(i_current_price)
        FROM item
    )
    GROUP BY w_warehouse_id, w_state, cp_department, i_current_price
)
SELECT
    w_warehouse_id,
    w_state,
    cp_department,
    total_net_loss,
    total_net_profit,
    distinct_customers,
    avg_item_price
FROM aggregated
WHERE total_net_loss > 1000
ORDER BY total_net_profit DESC
LIMIT 100
