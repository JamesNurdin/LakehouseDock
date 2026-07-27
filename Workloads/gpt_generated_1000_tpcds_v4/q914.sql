WITH base AS (
  SELECT
    cs.cs_ext_sales_price,
    cs.cs_ext_discount_amt,
    cr.cr_return_amount,
    cr.cr_net_loss,
    wr.wr_return_amt,
    wr.wr_net_loss,
    sm.sm_ship_mode_id,
    sm.sm_code,
    w.w_warehouse_id,
    w.w_state,
    cd.cd_gender,
    r_cr.r_reason_desc AS cr_reason_desc,
    r_wr.r_reason_desc AS wr_reason_desc,
    t.t_hour
  FROM catalog_sales cs
  JOIN time_dim t
    ON cs.cs_sold_time_sk = t.t_time_sk
  JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
  JOIN customer_demographics cd
    ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
  LEFT JOIN catalog_returns cr
    ON cr.cr_item_sk = cs.cs_item_sk
   AND cr.cr_order_number = cs.cs_order_number
  LEFT JOIN reason r_cr
    ON cr.cr_reason_sk = r_cr.r_reason_sk
  LEFT JOIN web_returns wr
    ON wr.wr_returned_time_sk = t.t_time_sk
  LEFT JOIN reason r_wr
    ON wr.wr_reason_sk = r_wr.r_reason_sk
  LEFT JOIN customer_demographics cd_wr
    ON wr.wr_refunded_cdemo_sk = cd_wr.cd_demo_sk
)
SELECT
  w_warehouse_id,
  sm_ship_mode_id,
  cr_reason_desc,
  wr_reason_desc,
  cd_gender,
  SUM(cs_ext_sales_price) AS total_sales,
  SUM(cr_return_amount) AS total_catalog_return,
  SUM(wr_return_amt) AS total_web_return,
  SUM(COALESCE(cr_net_loss, 0) + COALESCE(wr_net_loss, 0)) AS total_net_loss,
  RANK() OVER (
    PARTITION BY sm_ship_mode_id
    ORDER BY SUM(COALESCE(cr_net_loss, 0) + COALESCE(wr_net_loss, 0)) DESC
  ) AS loss_rank
FROM base
WHERE
  t_hour BETWEEN 9 AND 17
  AND sm_code = 'AIR'
  AND w_state = 'CA'
  AND cs_ext_discount_amt > 1000
  AND (
    cr_reason_desc LIKE '%Did not get it on time%'
    OR wr_reason_desc LIKE '%Did not get it on time%'
  )
GROUP BY
  w_warehouse_id,
  sm_ship_mode_id,
  cr_reason_desc,
  wr_reason_desc,
  cd_gender
ORDER BY
  loss_rank,
  w_warehouse_id
