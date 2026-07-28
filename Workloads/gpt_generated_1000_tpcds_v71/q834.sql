WITH sales_base AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_sold_time_sk,
        ss.ss_item_sk,
        ss.ss_customer_sk,
        ss.ss_hdemo_sk,
        ss.ss_store_sk,
        ss.ss_promo_sk,
        ss.ss_ticket_number,
        ss.ss_quantity,
        ss.ss_sales_price,
        ss.ss_net_paid,
        ss.ss_net_profit,
        d.d_date,
        d.d_year,
        t.t_hour,
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        p.p_promo_name,
        p.p_discount_active,
        sr.sr_return_amt,
        r_sr.r_reason_id,
        cr.cr_return_amount,
        r_cr.r_reason_id AS cr_reason_id,
        inv.inv_quantity_on_hand,
        w.w_warehouse_name,
        cc.cc_name,
        wp.wp_url,
        wp.wp_autogen_flag,
        sm.sm_type
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_item_sk = ss.ss_item_sk
    LEFT JOIN reason r_sr ON sr.sr_reason_sk = r_sr.r_reason_sk
    LEFT JOIN call_center cc ON cc.cc_call_center_sk = ss.ss_store_sk -- using store_sk as proxy; any valid join key per rules
    LEFT JOIN catalog_returns cr
        ON cr.cr_returned_date_sk = d.d_date_sk
        AND cr.cr_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN inventory inv
        ON inv.inv_date_sk = d.d_date_sk
        AND inv.inv_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN reason r_cr ON cr.cr_reason_sk = r_cr.r_reason_sk
    LEFT JOIN web_page wp ON wp.wp_creation_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND t.t_hour BETWEEN 9 AND 17
      AND ib.ib_lower_bound >= 50000
      AND p.p_discount_active = 'Y'
      AND r_sr.r_reason_id = 'AAAAAAAAAAAAAA'
      AND wp.wp_autogen_flag = 'N'
)
SELECT
    d_date,
    t_hour,
    p_promo_name,
    SUM(ss_quantity) AS total_quantity,
    SUM(ss_sales_price) AS total_sales,
    AVG(ss_net_profit) AS avg_net_profit,
    COUNT(DISTINCT ss_customer_sk) AS unique_customers,
    SUM(COALESCE(sr_return_amt, 0)) AS total_store_return,
    SUM(COALESCE(cr_return_amount, 0)) AS total_catalog_return,
    MAX(inv_quantity_on_hand) AS max_inventory,
    ROW_NUMBER() OVER (PARTITION BY p_promo_name ORDER BY SUM(ss_sales_price) DESC) AS promo_sales_rank
FROM sales_base
GROUP BY d_date, t_hour, p_promo_name
HAVING SUM(ss_sales_price) > 10000
ORDER BY total_sales DESC
LIMIT 100
