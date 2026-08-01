WITH base_sales AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_sold_time_sk,
        ss.ss_item_sk,
        ss.ss_customer_sk,
        ss.ss_hdemo_sk,
        ss.ss_store_sk,
        ss.ss_ticket_number,
        ss.ss_quantity,
        ss.ss_sales_price,
        ss.ss_net_paid,
        ss.ss_net_profit,
        i.i_item_id,
        i.i_current_price,
        i.i_brand,
        i.i_category,
        i.i_color,
        t.t_hour,
        t.t_am_pm,
        c.c_first_name,
        c.c_last_name,
        c.c_preferred_cust_flag,
        hd.hd_vehicle_count,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        s.s_store_name,
        s.s_state,
        s.s_city,
        s.s_gmt_offset
    FROM store_sales ss
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
),

distinct_reasons AS (
    SELECT DISTINCT r_reason_id, r_reason_desc
    FROM reason
),

price_tiers AS (
    SELECT *
    FROM (VALUES 
        ('Low', 0, 100),
        ('Medium', 100, 200),
        ('High', 200, 1000)
    ) AS pt(price_category, low_bound, high_bound)
)
SELECT
    bs.s_state,
    pt.price_category,
    dr.r_reason_desc,
    COUNT(DISTINCT bs.ss_ticket_number) AS distinct_tickets,
    SUM(bs.ss_quantity) AS total_quantity_sold,
    SUM(bs.ss_sales_price * bs.ss_quantity) AS total_sales_amount,
    SUM(bs.ss_net_profit) AS total_net_profit,
    SUM(COALESCE(sr.sr_net_loss, 0)) AS total_store_return_loss,
    SUM(COALESCE(cr.cr_net_loss, 0)) AS total_catalog_return_loss,
    SUM(COALESCE(wr.wr_net_loss, 0)) AS total_web_return_loss,
    SUM(CASE WHEN r_sr.r_reason_desc = 'Damaged' THEN COALESCE(sr.sr_net_loss, 0) + COALESCE(cr.cr_net_loss, 0) + COALESCE(wr.wr_net_loss, 0) ELSE 0 END) AS damaged_loss,
    MIN(bs.i_current_price) AS min_price,
    MAX(bs.i_current_price) AS max_price
FROM base_sales bs
LEFT JOIN store_returns sr
    ON sr.sr_item_sk = bs.ss_item_sk
    AND sr.sr_ticket_number = bs.ss_ticket_number
    AND sr.sr_return_time_sk = bs.ss_sold_time_sk
LEFT JOIN reason r_sr
    ON sr.sr_reason_sk = r_sr.r_reason_sk
LEFT JOIN catalog_returns cr
    ON cr.cr_item_sk = bs.ss_item_sk
    AND cr.cr_returned_time_sk = bs.ss_sold_time_sk
LEFT JOIN reason r_cr
    ON cr.cr_reason_sk = r_cr.r_reason_sk
LEFT JOIN web_returns wr
    ON wr.wr_item_sk = bs.ss_item_sk
    AND wr.wr_returned_time_sk = bs.ss_sold_time_sk
LEFT JOIN reason r_wr
    ON wr.wr_reason_sk = r_wr.r_reason_sk
LEFT JOIN inventory inv
    ON inv.inv_item_sk = bs.ss_item_sk
LEFT JOIN warehouse w
    ON inv.inv_warehouse_sk = w.w_warehouse_sk
LEFT JOIN call_center cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
LEFT JOIN catalog_page cp
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
CROSS JOIN distinct_reasons dr
CROSS JOIN price_tiers pt
WHERE
    bs.i_current_price > 100.00
    AND bs.hd_vehicle_count >= 2
    AND inv.inv_quantity_on_hand > 500
    AND cc.cc_state = 'CA'
    AND bs.t_hour BETWEEN 9 AND 17
    AND bs.ib_lower_bound >= 50000
GROUP BY ROLLUP (bs.s_state, pt.price_category, dr.r_reason_desc)
ORDER BY bs.s_state ASC NULLS LAST, pt.price_category, dr.r_reason_desc
LIMIT 100
