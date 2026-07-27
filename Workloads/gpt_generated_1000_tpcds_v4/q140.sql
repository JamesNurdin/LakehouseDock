WITH ss_agg AS (
    SELECT
        ss.ss_customer_sk,
        SUM(ss.ss_net_paid) AS total_paid,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(*) AS sales_cnt
    FROM store_sales ss
    JOIN time_dim td_sales ON ss.ss_sold_time_sk = td_sales.t_time_sk
    WHERE td_sales.t_shift = 'first'
    GROUP BY ss.ss_customer_sk
)
SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    cd.cd_gender,
    ss_agg.total_paid,
    ss_agg.total_profit,
    COUNT(DISTINCT sr.sr_return_quantity) AS distinct_return_qty,
    SUM(cr.cr_return_amount) AS total_catalog_return,
    SUM(wr.wr_return_amt) AS total_web_return,
    ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY ss_agg.total_paid DESC) AS gender_rank
FROM ss_agg
JOIN customer c ON ss_agg.ss_customer_sk = c.c_customer_sk
JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN store_returns sr ON sr.sr_customer_sk = c.c_customer_sk
LEFT JOIN time_dim td_sr ON sr.sr_return_time_sk = td_sr.t_time_sk
LEFT JOIN catalog_returns cr ON cr.cr_refunded_customer_sk = c.c_customer_sk
LEFT JOIN time_dim td_cr ON cr.cr_returned_time_sk = td_cr.t_time_sk
LEFT JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
LEFT JOIN web_returns wr ON wr.wr_refunded_customer_sk = c.c_customer_sk
LEFT JOIN time_dim td_wr ON wr.wr_returned_time_sk = td_wr.t_time_sk
WHERE EXISTS (
    SELECT 1
    FROM catalog_returns cr_sub
    WHERE cr_sub.cr_refunded_customer_sk = c.c_customer_sk
      AND cr_sub.cr_return_amount > 50
)
GROUP BY
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    cd.cd_gender,
    ss_agg.total_paid,
    ss_agg.total_profit
ORDER BY ss_agg.total_paid DESC
LIMIT 100
