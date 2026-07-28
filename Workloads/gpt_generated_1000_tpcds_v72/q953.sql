WITH wr_summary AS (
   SELECT
       wr.wr_returned_time_sk AS time_sk,
       wp.wp_type,
       SUM(wr.wr_return_amt) AS sum_wr_return_amt,
       SUM(wr.wr_net_loss) AS sum_wr_net_loss,
       COUNT(DISTINCT wr.wr_order_number) AS cnt_wr_orders
   FROM web_returns wr
   JOIN web_page wp
     ON wr.wr_web_page_sk = wp.wp_web_page_sk
   WHERE wp.wp_type = 'content'
     AND wr.wr_return_tax > 15.00
     AND wr.wr_fee BETWEEN 10.00 AND 60.00
   GROUP BY wr.wr_returned_time_sk, wp.wp_type
)
SELECT
    cd.cd_education_status,
    ca.ca_state,
    t.t_hour,
    t.t_meal_time,
    wrs.wp_type,
    SUM(cr.cr_return_amount) AS total_return_amount,
    AVG(cr.cr_return_tax) AS avg_return_tax,
    SUM(cr.cr_net_loss) AS total_net_loss,
    COUNT(DISTINCT cr.cr_order_number) AS distinct_orders,
    SUM(wrs.sum_wr_return_amt) AS total_web_return_amount,
    SUM(wrs.sum_wr_net_loss) AS total_web_net_loss,
    SUM(wrs.cnt_wr_orders) AS total_web_orders
FROM catalog_returns cr
JOIN time_dim t
  ON cr.cr_returned_time_sk = t.t_time_sk
JOIN customer_demographics cd
  ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
JOIN customer_address ca
  ON cr.cr_refunded_addr_sk = ca.ca_address_sk
JOIN wr_summary wrs
  ON t.t_time_sk = wrs.time_sk
WHERE cd.cd_education_status = 'College'
  AND cd.cd_purchase_estimate >= 5000
  AND ca.ca_state IN ('CA', 'NY', 'TX')
  AND t.t_minute IN (10, 12, 13)
  AND t.t_am_pm = 'PM'
  AND EXISTS (
        SELECT 1
        FROM web_page wp2
        WHERE wp2.wp_type = wrs.wp_type
          AND wp2.wp_char_count > 1000
      )
GROUP BY
    cd.cd_education_status,
    ca.ca_state,
    t.t_hour,
    t.t_meal_time,
    wrs.wp_type
ORDER BY total_return_amount DESC
LIMIT 100
