WITH joined_data AS (
    SELECT
        i.i_item_id,
        i.i_product_name,
        i.i_current_price,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        s.s_state,
        ss.ss_ticket_number,
        ss.ss_net_paid,
        cs.cs_net_profit,
        cr.cr_refunded_cash,
        wr.wr_refunded_cash,
        inv.inv_quantity_on_hand
    FROM store_sales ss
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN inventory inv
        ON i.i_item_sk = inv.inv_item_sk
    JOIN catalog_sales cs
        ON cs.cs_item_sk = i.i_item_sk
        AND cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = i.i_item_sk
        AND cr.cr_call_center_sk = cc.cc_call_center_sk
        AND cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
        AND cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_returns wr
        ON wr.wr_item_sk = i.i_item_sk
        AND wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    WHERE
        cc.cc_rec_start_date >= DATE '2001-01-01'
        AND cc.cc_rec_start_date <= DATE '2001-12-31'
        AND i.i_current_price > 50
        AND s.s_state = 'CA'
        AND ib.ib_upper_bound <= 100000
        AND inv.inv_quantity_on_hand > 100
)
SELECT
    i_item_id,
    s_state,
    ib_lower_bound,
    ib_upper_bound,
    COUNT(DISTINCT ss_ticket_number)               AS cnt_sales,
    SUM(ss_net_paid)                               AS total_net_paid,
    AVG(cs_net_profit)                             AS avg_net_profit,
    SUM(cr_refunded_cash)                          AS total_refunded_cash,
    SUM(wr_refunded_cash)                          AS total_web_refunded_cash,
    MIN(inv_quantity_on_hand)                      AS min_quantity_on_hand,
    MAX(inv_quantity_on_hand)                      AS max_quantity_on_hand
FROM joined_data
GROUP BY ROLLUP (i_item_id, s_state, ib_lower_bound, ib_upper_bound)
LIMIT 100
