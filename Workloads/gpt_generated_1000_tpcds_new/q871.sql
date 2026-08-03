WITH
    date_ret AS (
        SELECT * FROM date_dim
    ),
    joined AS (
        SELECT
            cc.cc_name,
            d_ret.d_year,
            cr.cr_order_number,
            cr.cr_return_amount,
            cr.cr_return_quantity,
            sm.sm_type,
            w.w_warehouse_name,
            r.r_reason_desc,
            ca_ref.ca_state      AS refunded_state,
            ca_ret.ca_state      AS returning_state,
            hd_ref.hd_income_band_sk AS refunded_income_band,
            hd_ret.hd_income_band_sk AS returning_income_band,
            inv.inv_quantity_on_hand,
            s.s_store_name,
            wp.wp_web_page_id,
            ws.web_name
        FROM catalog_returns cr
        JOIN date_ret d_ret ON cr.cr_returned_date_sk = d_ret.d_date_sk
        JOIN time_dim t_ret ON cr.cr_returned_time_sk = t_ret.t_time_sk
        JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
        JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
        JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
        JOIN customer_address ca_ref ON cr.cr_refunded_addr_sk = ca_ref.ca_address_sk
        JOIN customer_address ca_ret ON cr.cr_returning_addr_sk = ca_ret.ca_address_sk
        JOIN household_demographics hd_ref ON cr.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk
        JOIN household_demographics hd_ret ON cr.cr_returning_hdemo_sk = hd_ret.hd_demo_sk
        JOIN inventory inv ON inv.inv_warehouse_sk = w.w_warehouse_sk AND inv.inv_date_sk = d_ret.d_date_sk
        JOIN store s ON s.s_closed_date_sk = d_ret.d_date_sk
        LEFT JOIN web_returns wr ON cr.cr_order_number = wr.wr_order_number AND wr.wr_returned_date_sk = d_ret.d_date_sk
        LEFT JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
        LEFT JOIN date_dim d_wp ON wp.wp_creation_date_sk = d_wp.d_date_sk
        LEFT JOIN web_site ws ON ws.web_open_date_sk = d_wp.d_date_sk
        WHERE cr.cr_return_amount > (SELECT MAX(cr2.cr_return_amount) FROM catalog_returns cr2)
    ),
    agg1 AS (
        SELECT
            cc_name,
            d_year,
            SUM(cr_return_amount) AS sum_return_amount,
            SUM(cr_return_quantity) AS sum_return_qty,
            COUNT(*) AS cnt_orders
        FROM joined
        GROUP BY ROLLUP (cc_name, d_year)
    ),
    agg2 AS (
        SELECT
            cc_name,
            d_year,
            SUM(cr_return_amount) * 0.9 AS sum_return_amount,
            SUM(cr_return_quantity) AS sum_return_qty,
            COUNT(*) AS cnt_orders
        FROM joined
        GROUP BY ROLLUP (cc_name, d_year)
    )
SELECT
    cc_name,
    d_year,
    sum_return_amount,
    sum_return_qty,
    cnt_orders,
    LAG(sum_return_amount) OVER (PARTITION BY cc_name ORDER BY d_year) AS prev_year_amount
FROM (
    SELECT * FROM agg1
    INTERSECT
    SELECT * FROM agg2
) intersected
ORDER BY cc_name NULLS LAST, d_year
LIMIT 100
