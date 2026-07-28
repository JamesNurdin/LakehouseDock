WITH sales_agg AS (
    SELECT
        ss_item_sk,
        ss_store_sk,
        ss_sold_date_sk,
        ss_hdemo_sk,
        SUM(ss_net_paid) AS total_net_paid,
        SUM(ss_quantity) AS total_quantity
    FROM store_sales
    GROUP BY
        ss_item_sk,
        ss_store_sk,
        ss_sold_date_sk,
        ss_hdemo_sk
)
SELECT
    d_sales.d_year AS sale_year,
    i_sales.i_category,
    s.s_store_name,
    hd_sales.hd_buy_potential,
    ib_sales.ib_lower_bound,
    ib_sales.ib_upper_bound,
    sa.total_net_paid,
    sa.total_quantity,
    cr.cr_return_amount,
    cr.cr_return_quantity,
    r.r_reason_desc            AS catalog_return_reason,
    wp.wp_url,
    wr.wr_return_amt,
    r2.r_reason_desc           AS web_return_reason,
    ws.web_name
FROM sales_agg sa
JOIN item i_sales
    ON sa.ss_item_sk = i_sales.i_item_sk
JOIN store s
    ON sa.ss_store_sk = s.s_store_sk
JOIN date_dim d_sales
    ON sa.ss_sold_date_sk = d_sales.d_date_sk
JOIN household_demographics hd_sales
    ON sa.ss_hdemo_sk = hd_sales.hd_demo_sk
JOIN income_band ib_sales
    ON hd_sales.hd_income_band_sk = ib_sales.ib_income_band_sk
LEFT JOIN catalog_returns cr
    ON cr.cr_item_sk = i_sales.i_item_sk
LEFT JOIN date_dim d_cr_return
    ON cr.cr_returned_date_sk = d_cr_return.d_date_sk
LEFT JOIN time_dim t_cr_return
    ON cr.cr_returned_time_sk = t_cr_return.t_time_sk
LEFT JOIN reason r
    ON cr.cr_reason_sk = r.r_reason_sk
LEFT JOIN call_center cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
LEFT JOIN catalog_page cp
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
LEFT JOIN ship_mode sm
    ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
LEFT JOIN customer c_refunded
    ON cr.cr_refunded_customer_sk = c_refunded.c_customer_sk
LEFT JOIN household_demographics hd_refunded
    ON cr.cr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
LEFT JOIN customer c_returning
    ON cr.cr_returning_customer_sk = c_returning.c_customer_sk
LEFT JOIN household_demographics hd_returning
    ON cr.cr_returning_hdemo_sk = hd_returning.hd_demo_sk
LEFT JOIN web_returns wr
    ON wr.wr_item_sk = i_sales.i_item_sk
LEFT JOIN date_dim d_wr_return
    ON wr.wr_returned_date_sk = d_wr_return.d_date_sk
LEFT JOIN time_dim t_wr_return
    ON wr.wr_returned_time_sk = t_wr_return.t_time_sk
LEFT JOIN reason r2
    ON wr.wr_reason_sk = r2.r_reason_sk
LEFT JOIN web_page wp
    ON wr.wr_web_page_sk = wp.wp_web_page_sk
LEFT JOIN web_site ws
    ON ws.web_open_date_sk = d_sales.d_date_sk
WHERE d_sales.d_year = 2001
  AND i_sales.i_current_price > 100
ORDER BY sa.total_net_paid DESC
LIMIT 100
