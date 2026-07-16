WITH combined_returns AS (
    SELECT cp.cp_department AS dept,
           r.r_reason_desc AS reason_desc,
           'Catalog' AS source,
           cr.cr_net_loss AS net_loss,
           cr.cr_return_quantity AS return_qty,
           c.c_customer_sk AS cust_sk
    FROM catalog_returns cr
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    WHERE cp.cp_start_date_sk BETWEEN 2450900 AND 2451100
      AND t.t_shift = 'Evening'
      AND c.c_preferred_cust_flag = 'Y'
    UNION ALL
    SELECT 'WEB' AS dept,
           r.r_reason_desc AS reason_desc,
           'Web' AS source,
           wr.wr_net_loss AS net_loss,
           wr.wr_return_quantity AS return_qty,
           c.c_customer_sk AS cust_sk
    FROM web_returns wr
    JOIN time_dim t ON wr.wr_returned_time_sk = t.t_time_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
    WHERE t.t_shift = 'Evening'
      AND c.c_preferred_cust_flag = 'Y'
)
SELECT dept,
       reason_desc,
       source,
       SUM(net_loss) AS total_net_loss,
       SUM(return_qty) AS total_return_qty,
       COUNT(DISTINCT cust_sk) AS distinct_customers
FROM combined_returns
GROUP BY dept, reason_desc, source
ORDER BY total_net_loss DESC
LIMIT 100
