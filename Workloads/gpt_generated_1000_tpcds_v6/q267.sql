WITH item_year_sales AS (
    SELECT
        ss.ss_item_sk,
        d1.d_year,
        SUM(ss.ss_net_paid) AS total_net_paid,
        SUM(ss.ss_quantity) AS total_quantity
    FROM store_sales ss
    JOIN date_dim d1 ON ss.ss_sold_date_sk = d1.d_date_sk
    GROUP BY ss.ss_item_sk, d1.d_year
)
SELECT
    i.i_item_id,
    d_sales.d_year,
    p_ss.p_promo_name,
    COUNT(DISTINCT ss.ss_ticket_number) AS num_sales,
    SUM(ss.ss_net_paid) AS sum_net_paid,
    SUM(cr.cr_net_loss) AS sum_cr_net_loss,
    SUM(wr.wr_net_loss) AS sum_wr_net_loss
FROM item_year_sales iys
JOIN store_sales ss ON ss.ss_item_sk = iys.ss_item_sk
JOIN date_dim d_sales ON ss.ss_sold_date_sk = d_sales.d_date_sk
JOIN time_dim t_sales ON ss.ss_sold_time_sk = t_sales.t_time_sk
JOIN item i ON ss.ss_item_sk = i.i_item_sk
JOIN store s_sales ON ss.ss_store_sk = s_sales.s_store_sk
JOIN promotion p_ss ON ss.ss_promo_sk = p_ss.p_promo_sk
JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
JOIN date_dim d_ret ON sr.sr_returned_date_sk = d_ret.d_date_sk
JOIN time_dim t_ret ON sr.sr_return_time_sk = t_ret.t_time_sk
JOIN store s_ret ON sr.sr_store_sk = s_ret.s_store_sk
JOIN catalog_sales cs ON cs.cs_sold_date_sk = d_sales.d_date_sk
JOIN ship_mode sm_cs ON cs.cs_ship_mode_sk = sm_cs.sm_ship_mode_sk
JOIN promotion p_cs ON cs.cs_promo_sk = p_cs.p_promo_sk
JOIN household_demographics hd_cs_bill ON cs.cs_bill_hdemo_sk = hd_cs_bill.hd_demo_sk
JOIN household_demographics hd_cs_ship ON cs.cs_ship_hdemo_sk = hd_cs_ship.hd_demo_sk
JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
JOIN date_dim d_cr_ret ON cr.cr_returned_date_sk = d_cr_ret.d_date_sk
JOIN time_dim t_cr_ret ON cr.cr_returned_time_sk = t_cr_ret.t_time_sk
JOIN ship_mode sm_cr ON cr.cr_ship_mode_sk = sm_cr.sm_ship_mode_sk
JOIN household_demographics hd_cr_refunded ON cr.cr_refunded_hdemo_sk = hd_cr_refunded.hd_demo_sk
JOIN household_demographics hd_cr_returning ON cr.cr_returning_hdemo_sk = hd_cr_returning.hd_demo_sk
JOIN web_returns wr ON wr.wr_returned_date_sk = d_sales.d_date_sk
JOIN time_dim t_wr ON wr.wr_returned_time_sk = t_wr.t_time_sk
JOIN household_demographics hd_wr_refunded ON wr.wr_refunded_hdemo_sk = hd_wr_refunded.hd_demo_sk
JOIN household_demographics hd_wr_returning ON wr.wr_returning_hdemo_sk = hd_wr_returning.hd_demo_sk
WHERE EXISTS (
    SELECT 1 FROM promotion p2
    WHERE p2.p_channel_event = 'N' AND p2.p_promo_sk = p_ss.p_promo_sk
)
GROUP BY GROUPING SETS (
    (i.i_item_id, d_sales.d_year, p_ss.p_promo_name),
    (i.i_item_id, d_sales.d_year),
    (i.i_item_id),
    ()
)
ORDER BY i.i_item_id, d_sales.d_year, p_ss.p_promo_name
LIMIT 100
