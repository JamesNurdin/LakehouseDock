WITH base AS (
    SELECT
        d.d_year,
        w.w_state,
        p.p_promo_name,
        r.r_reason_desc,
        sr.sr_net_loss,
        ws.ws_net_profit,
        ws.ws_order_number,
        inv.inv_quantity_on_hand,
        p.p_cost,
        -- columns needed for joins and filters (not selected in final output)
        sr.sr_return_quantity,
        wp.wp_max_ad_count,
        cr.cr_return_amount,
        cc.cc_name,
        ib.ib_lower_bound,
        wr.wr_return_amt,
        t.t_hour,
        cd.cd_gender,
        hd.hd_income_band_sk
    FROM tpcds.date_dim d
    JOIN tpcds.store_returns sr
        ON sr.sr_returned_date_sk = d.d_date_sk
    FULL OUTER JOIN tpcds.reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    JOIN tpcds.time_dim t
        ON sr.sr_return_time_sk = t.t_time_sk
    JOIN tpcds.customer_demographics cd
        ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN tpcds.household_demographics hd
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.catalog_returns cr
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN tpcds.call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN tpcds.warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN tpcds.inventory inv
        ON inv.inv_warehouse_sk = w.w_warehouse_sk
       AND inv.inv_date_sk = d.d_date_sk
    JOIN tpcds.income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN tpcds.web_sales ws
        ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN tpcds.promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    JOIN tpcds.web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN tpcds.web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
    LEFT JOIN LATERAL (
        SELECT inv.inv_quantity_on_hand * 1.0 AS inventory_value
    ) inv_calc ON TRUE
    CROSS JOIN (
        SELECT 1 AS dummy UNION ALL SELECT 2 UNION ALL SELECT 3
    ) t_small
    WHERE d.d_year = 2001
      AND sr.sr_return_quantity > 5
      AND w.w_state IN ('MO', 'TN')
      AND p.p_discount_active = 'Y'
      AND inv.inv_quantity_on_hand >= 100
      AND wp.wp_max_ad_count = 0
      AND r.r_reason_desc LIKE '%damaged%'
)
SELECT
    d_year,
    w_state,
    p_promo_name,
    r_reason_desc,
    SUM(sr_net_loss) AS total_net_loss,
    AVG(ws_net_profit) AS avg_net_profit,
    COUNT(DISTINCT ws_order_number) AS orders_cnt,
    MIN(inv_quantity_on_hand) AS min_inventory_qty,
    MAX(p_cost) AS max_promo_cost
FROM base
GROUP BY d_year, w_state, p_promo_name, r_reason_desc
ORDER BY total_net_loss DESC
LIMIT 100
