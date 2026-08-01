WITH distinct_orders AS (
  SELECT DISTINCT
    cs.cs_order_number,
    cs.cs_sold_date_sk,
    cs.cs_sold_time_sk,
    cs.cs_quantity,
    cs.cs_net_paid,
    cs.cs_net_profit,
    cs.cs_call_center_sk,
    cs.cs_ship_mode_sk,
    cs.cs_warehouse_sk,
    cs.cs_item_sk,
    cs.cs_bill_customer_sk,
    cs.cs_bill_cdemo_sk,
    cs.cs_bill_hdemo_sk,
    cr.cr_return_quantity,
    cr.cr_return_amount,
    cr.cr_net_loss,
    cr.cr_reason_sk,
    cc.cc_name,
    sm.sm_type,
    w.w_warehouse_name,
    r.r_reason_desc,
    c.c_customer_sk,
    c.c_first_name,
    c.c_last_name,
    c.c_birth_year,
    cd.cd_gender,
    cd.cd_education_status,
    hd.hd_vehicle_count,
    hd.hd_buy_potential
  FROM catalog_sales cs
  FULL OUTER JOIN catalog_returns cr
    ON cs.cs_order_number = cr.cr_order_number
  LEFT JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
  LEFT JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  LEFT JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
  LEFT JOIN reason r
    ON cr.cr_reason_sk = r.r_reason_sk
  LEFT JOIN customer c
    ON cs.cs_bill_customer_sk = c.c_customer_sk
  LEFT JOIN customer_demographics cd
    ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
  LEFT JOIN household_demographics hd
    ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
  WHERE
    cc.cc_country = 'United States'
    AND w.w_state = 'CA'
    AND hd.hd_vehicle_count > 0
    AND cd.cd_gender = 'M'
    AND c.c_birth_year BETWEEN 1970 AND 1990
)
SELECT
  do.cs_order_number,
  do.cc_name,
  do.sm_type,
  do.w_warehouse_name,
  do.r_reason_desc,
  do.c_first_name,
  do.c_last_name,
  do.c_birth_year,
  do.cd_gender,
  do.hd_vehicle_count,
  do.cs_net_paid,
  do.cs_net_profit,
  COALESCE(ss.ss_quantity, 0) AS store_quantity,
  COALESCE(ss.ss_net_paid, 0) AS store_net_paid,
  COALESCE(ws.ws_quantity, 0) AS web_quantity,
  COALESCE(ws.ws_net_paid, 0) AS web_net_paid,
  CASE WHEN do.cr_return_quantity IS NOT NULL THEN 'Returned' ELSE 'No Return' END AS return_flag,
  DENSE_RANK() OVER (ORDER BY do.cs_net_profit DESC) AS profit_rank,
  ROW_NUMBER() OVER (PARTITION BY do.cd_gender ORDER BY do.cs_net_paid DESC) AS gender_rownum
FROM distinct_orders do
LEFT JOIN store_sales ss
  ON ss.ss_customer_sk = do.c_customer_sk
LEFT JOIN web_sales ws
  ON ws.ws_bill_customer_sk = do.c_customer_sk
WHERE NOT EXISTS (
  SELECT 1
  FROM store_sales ss_ex
  WHERE ss_ex.ss_customer_sk = do.c_customer_sk
    AND ss_ex.ss_net_paid > 5000
)
ORDER BY profit_rank ASC, gender_rownum ASC
LIMIT 100
