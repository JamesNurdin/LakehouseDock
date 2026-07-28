WITH sales_summary AS (
    SELECT DISTINCT
        ss.ss_item_sk,
        ss.ss_sold_date_sk,
        td.t_hour,
        SUM(ss.ss_net_paid)            AS total_net_paid,
        SUM(ss.ss_ext_sales_price)     AS total_ext_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets
    FROM store_sales ss
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    GROUP BY ss.ss_item_sk, ss.ss_sold_date_sk, td.t_hour
)
SELECT
    i.i_item_id,
    i.i_product_name,
    cp.cp_department,
    sm.sm_type,
    hd_sales.hd_buy_potential,
    CASE
        WHEN cr.cr_net_loss > 0 THEN 'Loss'
        ELSE 'Profit'
    END AS return_loss_flag,
    SUM(ss_sum.total_net_paid)          AS agg_net_paid,
    SUM(cr.cr_return_amount)            AS agg_return_amount,
    COUNT(DISTINCT sr.sr_return_quantity) AS distinct_return_qty,
    ss_sum.t_hour                        AS sold_hour
FROM sales_summary ss_sum
JOIN item i                 ON ss_sum.ss_item_sk = i.i_item_sk
JOIN store_sales ss          ON ss.ss_item_sk = i.i_item_sk
                              AND ss.ss_sold_date_sk = ss_sum.ss_sold_date_sk
JOIN household_demographics hd_sales
                              ON ss.ss_hdemo_sk = hd_sales.hd_demo_sk
JOIN store_returns sr        ON sr.sr_ticket_number = ss.ss_ticket_number
                              AND sr.sr_item_sk = i.i_item_sk
JOIN time_dim td_sr          ON sr.sr_return_time_sk = td_sr.t_time_sk
JOIN catalog_returns cr      ON cr.cr_item_sk = i.i_item_sk
JOIN time_dim td_cr          ON cr.cr_returned_time_sk = td_cr.t_time_sk
JOIN catalog_page cp         ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm            ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN household_demographics hd_cr_refund
                              ON cr.cr_refunded_hdemo_sk = hd_cr_refund.hd_demo_sk
WHERE EXISTS (
    SELECT 1
    FROM web_returns wr
    JOIN time_dim td_wr ON wr.wr_returned_time_sk = td_wr.t_time_sk
    WHERE wr.wr_item_sk = i.i_item_sk
      AND wr.wr_net_loss > 0
      AND td_wr.t_hour = ss_sum.t_hour
)
GROUP BY
    i.i_item_id,
    i.i_product_name,
    cp.cp_department,
    sm.sm_type,
    hd_sales.hd_buy_potential,
    CASE
        WHEN cr.cr_net_loss > 0 THEN 'Loss'
        ELSE 'Profit'
    END,
    ss_sum.t_hour
ORDER BY agg_net_paid DESC
LIMIT 100
