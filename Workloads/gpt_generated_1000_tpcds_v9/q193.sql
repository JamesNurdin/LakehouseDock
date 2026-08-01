WITH grouped_returns AS (
  SELECT
    r_cr.r_reason_desc AS reason_desc,
    sm.sm_carrier AS carrier,
    i.i_category AS category,
    w.w_state AS warehouse_state,
    t.t_hour AS hour_of_day,
    SUM(cr.cr_return_amount) AS total_catalog_return_amount,
    SUM(wr.wr_return_amt) AS total_web_return_amount,
    COUNT(DISTINCT cr.cr_order_number) AS catalog_order_cnt,
    COUNT(DISTINCT wr.wr_order_number) AS web_order_cnt
  FROM catalog_returns cr
  JOIN time_dim t
    ON cr.cr_returned_time_sk = t.t_time_sk
  JOIN item i
    ON cr.cr_item_sk = i.i_item_sk
  JOIN ship_mode sm
    ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN warehouse w
    ON cr.cr_warehouse_sk = w.w_warehouse_sk
  JOIN reason r_cr
    ON cr.cr_reason_sk = r_cr.r_reason_sk
  LEFT JOIN customer_demographics cd_refunded
    ON cr.cr_refunded_cdemo_sk = cd_refunded.cd_demo_sk
  LEFT JOIN customer_address ca_refunded
    ON cr.cr_refunded_addr_sk = ca_refunded.ca_address_sk
  LEFT JOIN customer_demographics cd_returning
    ON cr.cr_returning_cdemo_sk = cd_returning.cd_demo_sk
  LEFT JOIN customer_address ca_returning
    ON cr.cr_returning_addr_sk = ca_returning.ca_address_sk
  JOIN web_returns wr
    ON wr.wr_item_sk = i.i_item_sk
   AND wr.wr_returned_time_sk = t.t_time_sk
  JOIN reason r_wr
    ON wr.wr_reason_sk = r_wr.r_reason_sk
  JOIN web_page wp
    ON wr.wr_web_page_sk = wp.wp_web_page_sk
  LEFT JOIN customer_demographics cd_wr_refunded
    ON wr.wr_refunded_cdemo_sk = cd_wr_refunded.cd_demo_sk
  LEFT JOIN customer_address ca_wr_refunded
    ON wr.wr_refunded_addr_sk = ca_wr_refunded.ca_address_sk
  LEFT JOIN customer_demographics cd_wr_returning
    ON wr.wr_returning_cdemo_sk = cd_wr_returning.cd_demo_sk
  LEFT JOIN customer_address ca_wr_returning
    ON wr.wr_returning_addr_sk = ca_wr_returning.ca_address_sk
  WHERE sm.sm_carrier = 'DHL'
    AND sm.sm_code = 'AIR'
    AND i.i_current_price > 20
    AND cr.cr_return_amount > 100
    AND wr.wr_return_amt > 100
    AND r_cr.r_reason_desc LIKE '%damage%'
    AND w.w_state = 'TX'
    AND t.t_hour BETWEEN 8 AND 20
  GROUP BY GROUPING SETS (
    (r_cr.r_reason_desc, sm.sm_carrier, i.i_category, w.w_state, t.t_hour),
    (r_cr.r_reason_desc, sm.sm_carrier, i.i_category, w.w_state),
    (r_cr.r_reason_desc, sm.sm_carrier, i.i_category),
    (r_cr.r_reason_desc, sm.sm_carrier),
    (r_cr.r_reason_desc),
    ()
  )
)
SELECT
  reason_desc,
  carrier,
  category,
  warehouse_state,
  hour_of_day,
  total_catalog_return_amount,
  total_web_return_amount,
  (total_catalog_return_amount + total_web_return_amount) AS total_return_amount,
  SUM(total_catalog_return_amount + total_web_return_amount) OVER (PARTITION BY carrier) AS sum_by_carrier,
  AVG(total_catalog_return_amount + total_web_return_amount) OVER (PARTITION BY hour_of_day) AS avg_by_hour,
  RANK() OVER (ORDER BY (total_catalog_return_amount + total_web_return_amount) DESC) AS amt_rank
FROM grouped_returns gr
WHERE NOT EXISTS (
  SELECT 1 FROM ship_mode sm_ex
  WHERE sm_ex.sm_carrier = gr.carrier
    AND sm_ex.sm_contract = 'Ek'
)
ORDER BY amt_rank
LIMIT 100
