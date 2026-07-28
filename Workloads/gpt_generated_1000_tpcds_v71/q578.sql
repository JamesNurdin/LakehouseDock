WITH base AS (
  SELECT
    cs.cs_sold_date_sk,
    cs.cs_sold_time_sk,
    cs.cs_order_number,
    cs.cs_net_paid,
    cs.cs_net_profit,
    cs.cs_quantity,
    cs.cs_item_sk,
    d.d_year,
    t.t_hour,
    cc.cc_name,
    cc.cc_state,
    cp.cp_department,
    sm.sm_type,
    cd.cd_education_status,
    ca.ca_state,
    r.r_reason_desc,
    r.r_reason_sk,
    cr.cr_return_amount,
    sr.sr_net_loss,
    ss.ss_net_profit,
    wr.wr_return_amt
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
  JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
  JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
  JOIN catalog_returns cr ON cr.cr_item_sk = cs.cs_item_sk
                           AND cr.cr_order_number = cs.cs_order_number
                           AND cr.cr_returned_date_sk = d.d_date_sk
  JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
  JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
                       AND ss.ss_sold_time_sk = t.t_time_sk
                       AND ss.ss_item_sk = cs.cs_item_sk
  JOIN store_returns sr ON sr.sr_item_sk = ss.ss_item_sk
                         AND sr.sr_ticket_number = ss.ss_ticket_number
                         AND sr.sr_returned_date_sk = d.d_date_sk
                         AND sr.sr_reason_sk = r.r_reason_sk
  JOIN web_page wp ON wp.wp_creation_date_sk = d.d_date_sk
  JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
                       AND wr.wr_web_page_sk = wp.wp_web_page_sk
)
SELECT
  d_year,
  cc_name,
  cp_department,
  sm_type,
  r_reason_desc,
  SUM(cs_net_paid) AS total_sales,
  SUM(cr_return_amount) AS total_returns,
  COUNT(DISTINCT cs_order_number) AS distinct_orders,
  AVG(ss_net_profit) AS avg_store_profit,
  CASE WHEN sm_type = 'AIR' THEN SUM(cs_net_paid) ELSE 0 END AS air_sales,
  (SELECT COUNT(*) FROM customer_demographics cd2 WHERE cd2.cd_purchase_estimate > 5000) AS high_estimate_demo_cnt
FROM base
WHERE d_year = 2001
  AND t_hour BETWEEN 9 AND 17
  AND cc_state = 'CA'
  AND cd_education_status = 'College'
  AND NOT EXISTS (
        SELECT 1 FROM web_returns wr2
        WHERE wr2.wr_reason_sk = r_reason_sk
          AND wr2.wr_return_amt > 1000
      )
GROUP BY d_year, cc_name, cp_department, sm_type, r_reason_desc
ORDER BY total_sales DESC
LIMIT 100
