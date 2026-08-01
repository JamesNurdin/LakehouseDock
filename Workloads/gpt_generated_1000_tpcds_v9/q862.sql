WITH cte_sales AS (
    SELECT
        cs.cs_order_number,
        cs.cs_item_sk,
        cs.cs_quantity,
        cs.cs_net_paid,
        cs.cs_net_profit,
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        cs.cs_ship_date_sk,
        cs.cs_warehouse_sk,
        cs.cs_bill_customer_sk,
        cs.cs_bill_cdemo_sk,
        cs.cs_bill_hdemo_sk,
        cs.cs_ship_customer_sk,
        cs.cs_ship_cdemo_sk,
        cs.cs_ship_hdemo_sk
    FROM catalog_sales cs
    WHERE cs.cs_quantity > 0
      AND cs.cs_net_paid > 0
)
SELECT
    s.s_store_name,
    d_sr.d_year AS return_year,
    r.r_reason_desc,
    COUNT(DISTINCT c.c_customer_sk) AS num_customers,
    SUM(sr.sr_return_amt) AS total_store_return_amount,
    SUM(cr.cr_return_amount) AS total_catalog_return_amount,
    SUM(wr.wr_return_amt) AS total_web_return_amount,
    SUM(cs.cs_net_paid) AS total_sales_net_paid,
    AVG(cs.cs_net_profit) AS avg_sales_net_profit,
    MIN(cs.cs_quantity) AS min_quantity,
    MAX(cs.cs_quantity) AS max_quantity
FROM cte_sales cs
JOIN catalog_returns cr
    ON cr.cr_order_number = cs.cs_order_number
   AND cr.cr_item_sk = cs.cs_item_sk
JOIN store_returns sr
    ON sr.sr_customer_sk = cs.cs_bill_customer_sk
   AND sr.sr_cdemo_sk = cs.cs_bill_cdemo_sk
   AND sr.sr_hdemo_sk = cs.cs_bill_hdemo_sk
JOIN web_returns wr
    ON wr.wr_refunded_customer_sk = cs.cs_bill_customer_sk
   AND wr.wr_refunded_cdemo_sk = cs.cs_bill_cdemo_sk
   AND wr.wr_refunded_hdemo_sk = cs.cs_bill_hdemo_sk
JOIN customer c
    ON c.c_customer_sk = cs.cs_bill_customer_sk
JOIN customer_demographics cd
    ON cd.cd_demo_sk = cs.cs_bill_cdemo_sk
JOIN household_demographics hd
    ON hd.hd_demo_sk = cs.cs_bill_hdemo_sk
JOIN warehouse w
    ON w.w_warehouse_sk = cs.cs_warehouse_sk
JOIN store s
    ON s.s_store_sk = sr.sr_store_sk
JOIN reason r
    ON r.r_reason_sk = sr.sr_reason_sk
JOIN date_dim d_sr
    ON d_sr.d_date_sk = sr.sr_returned_date_sk
JOIN time_dim t_sr
    ON t_sr.t_time_sk = sr.sr_return_time_sk
JOIN date_dim d_cr
    ON d_cr.d_date_sk = cr.cr_returned_date_sk
JOIN time_dim t_cr
    ON t_cr.t_time_sk = cr.cr_returned_time_sk
JOIN date_dim d_wr
    ON d_wr.d_date_sk = wr.wr_returned_date_sk
JOIN time_dim t_wr
    ON t_wr.t_time_sk = wr.wr_returned_time_sk
JOIN web_page wp
    ON wp.wp_web_page_sk = wr.wr_web_page_sk
JOIN date_dim d_wp_creation
    ON d_wp_creation.d_date_sk = wp.wp_creation_date_sk
JOIN date_dim d_wp_access
    ON d_wp_access.d_date_sk = wp.wp_access_date_sk
JOIN date_dim d_store_closed
    ON d_store_closed.d_date_sk = s.s_closed_date_sk
WHERE
    d_sr.d_year = 2001
    AND s.s_state = 'CA'
    AND c.c_preferred_cust_flag = 'Y'
    AND r.r_reason_desc = 'Damaged'
    AND t_sr.t_hour BETWEEN 9 AND 12
    AND w.w_state = 'TX'
    AND sr.sr_return_amt > 500
    AND EXISTS (
        SELECT 1
        FROM catalog_returns cr2
        WHERE cr2.cr_returned_date_sk = d_cr.d_date_sk
          AND cr2.cr_net_loss > 1000
    )
GROUP BY
    s.s_store_name,
    d_sr.d_year,
    r.r_reason_desc
HAVING
    SUM(sr.sr_return_amt) > 1000
ORDER BY
    total_store_return_amount DESC
LIMIT 50
