WITH base AS (
    SELECT
        cc.cc_name,
        cp.cp_department,
        d.d_year,
        cs.cs_net_paid,
        sr.sr_net_loss,
        cr.cr_net_loss,
        wr.wr_net_loss
    FROM catalog_sales cs
        /* date and time dimensions for catalog sales */
        JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
        JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
        /* catalog page and call center */
        JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
        /* warehouse */
        JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
        /* customer and household demographics for billing */
        JOIN customer_demographics cd_bill ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
        JOIN household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
        /* customer and household demographics for shipping */
        JOIN customer_demographics cd_ship ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
        JOIN household_demographics hd_ship ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
        /* store sales – linked through the same date and time rows */
        JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
                             AND ss.ss_sold_time_sk = t.t_time_sk
        JOIN customer_demographics cd_ss ON ss.ss_cdemo_sk = cd_ss.cd_demo_sk
        JOIN household_demographics hd_ss ON ss.ss_hdemo_sk = hd_ss.hd_demo_sk
        /* store returns – linked to store sales */
        JOIN store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
                               AND sr.sr_return_time_sk = t.t_time_sk
                               AND sr.sr_item_sk = ss.ss_item_sk
                               AND sr.sr_ticket_number = ss.ss_ticket_number
        JOIN customer_demographics cd_sr ON sr.sr_cdemo_sk = cd_sr.cd_demo_sk
        JOIN household_demographics hd_sr ON sr.sr_hdemo_sk = hd_sr.hd_demo_sk
        /* catalog returns – linked to catalog sales */
        JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
                                 AND cr.cr_returned_time_sk = t.t_time_sk
                                 AND cr.cr_item_sk = cs.cs_item_sk
                                 AND cr.cr_order_number = cs.cs_order_number
        JOIN customer_demographics cd_cr_ref ON cr.cr_refunded_cdemo_sk = cd_cr_ref.cd_demo_sk
        JOIN household_demographics hd_cr_ref ON cr.cr_refunded_hdemo_sk = hd_cr_ref.hd_demo_sk
        JOIN customer_demographics cd_cr_ret ON cr.cr_returning_cdemo_sk = cd_cr_ret.cd_demo_sk
        JOIN household_demographics hd_cr_ret ON cr.cr_returning_hdemo_sk = hd_cr_ret.hd_demo_sk
        /* web returns – left‑joined because a day may have no web returns */
        LEFT JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
                                   AND wr.wr_returned_time_sk = t.t_time_sk
        LEFT JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
        JOIN customer_demographics cd_wr_ref ON wr.wr_refunded_cdemo_sk = cd_wr_ref.cd_demo_sk
        JOIN household_demographics hd_wr_ref ON wr.wr_refunded_hdemo_sk = hd_wr_ref.hd_demo_sk
        JOIN customer_demographics cd_wr_ret ON wr.wr_returning_cdemo_sk = cd_wr_ret.cd_demo_sk
        JOIN household_demographics hd_wr_ret ON wr.wr_returning_hdemo_sk = hd_wr_ret.hd_demo_sk
    WHERE d.d_year = 2001                                 -- filter 1: specific year
      AND cs.cs_quantity > 1                               -- filter 2: minimum quantity
      AND cs.cs_coupon_amt > 100.00                        -- filter 3: coupon amount threshold
      AND w.w_country = 'United States'                    -- filter 4: warehouse country
      AND cc.cc_state = 'CA'                               -- filter 5: call‑center state
      AND t.t_hour BETWEEN 8 AND 20                        -- filter 6: business hours
)
SELECT
    cc_name,
    cp_department,
    d_year,
    SUM(cs_net_paid)               AS total_catalog_sales,
    SUM(COALESCE(sr_net_loss, 0))  AS total_store_return_loss,
    SUM(COALESCE(cr_net_loss, 0))  AS total_catalog_return_loss,
    SUM(COALESCE(wr_net_loss, 0))  AS total_web_return_loss,
    RANK() OVER (PARTITION BY cc_name ORDER BY SUM(cs_net_paid) DESC) AS sales_rank
FROM base
GROUP BY
    cc_name,
    cp_department,
    d_year
ORDER BY sales_rank
LIMIT 100
