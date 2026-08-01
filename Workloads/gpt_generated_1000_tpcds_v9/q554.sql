WITH joined_data AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_returned_time_sk,
        cr.cr_return_amount,
        cr.cr_return_quantity,
        cr.cr_fee,
        cr.cr_net_loss,
        d.d_year,
        d.d_month_seq,
        t.t_hour,
        sm.sm_carrier,
        w.w_warehouse_name,
        r.r_reason_desc,
        ca_ref.ca_state          AS refunded_state,
        ca_ret.ca_state          AS returning_state,
        ib.ib_upper_bound,
        ib.ib_lower_bound,
        p.p_promo_name,
        p.p_discount_active,
        s.s_store_name,
        s.s_state,
        inv.inv_quantity_on_hand,
        wr.wr_return_amt,
        wr.wr_return_quantity,
        wr.wr_net_loss,
        wp.wp_image_count,
        wp.wp_autogen_flag
    FROM catalog_returns cr
        JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
        JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
        JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
        JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
        JOIN customer_address ca_ref ON cr.cr_refunded_addr_sk = ca_ref.ca_address_sk
        JOIN household_demographics hd_ref ON cr.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk
        JOIN income_band ib ON hd_ref.hd_income_band_sk = ib.ib_income_band_sk
        JOIN promotion p ON p.p_start_date_sk = d.d_date_sk
        JOIN store s ON s.s_closed_date_sk = d.d_date_sk
        LEFT JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk AND inv.inv_warehouse_sk = w.w_warehouse_sk
        JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk AND wr.wr_returned_time_sk = t.t_time_sk
        JOIN customer_address ca_ret ON wr.wr_refunded_addr_sk = ca_ret.ca_address_sk
        JOIN household_demographics hd_ret ON wr.wr_refunded_hdemo_sk = hd_ret.hd_demo_sk
        JOIN reason r2 ON wr.wr_reason_sk = r2.r_reason_sk
        JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE d.d_year = 2001
      AND sm.sm_carrier = 'UPS'
      AND ib.ib_upper_bound >= 50000
      AND wp.wp_image_count >= 3
      AND s.s_state = 'CA'
      AND p.p_discount_active = 'Y'
),
agg_data AS (
    SELECT
        jd.s_store_name,
        jd.s_state,
        jd.d_year,
        jd.d_month_seq,
        COUNT(*)                                     AS total_return_events,
        SUM(jd.cr_return_amount)                    AS total_catalog_return_amount,
        SUM(jd.wr_return_amt)                       AS total_web_return_amount,
        AVG(jd.cr_return_quantity)                  AS avg_catalog_return_qty,
        AVG(jd.wr_return_quantity)                  AS avg_web_return_qty,
        SUM(jd.cr_net_loss) + SUM(jd.wr_net_loss)   AS total_net_loss,
        MAX(jd.ib_upper_bound)                      AS max_income_upper,
        (SELECT AVG(ib2.ib_upper_bound) FROM income_band ib2) AS avg_income_upper_global
    FROM joined_data jd
    GROUP BY jd.s_store_name, jd.s_state, jd.d_year, jd.d_month_seq
)
SELECT
    a.s_store_name,
    a.s_state,
    a.d_year,
    a.d_month_seq,
    a.total_return_events,
    a.total_catalog_return_amount,
    a.total_web_return_amount,
    a.avg_catalog_return_qty,
    a.avg_web_return_qty,
    a.total_net_loss,
    a.max_income_upper,
    a.avg_income_upper_global,
    RANK() OVER (PARTITION BY a.d_year ORDER BY (a.total_catalog_return_amount + a.total_web_return_amount) DESC) AS return_amount_rank
FROM agg_data a
ORDER BY a.total_catalog_return_amount DESC
LIMIT 100
