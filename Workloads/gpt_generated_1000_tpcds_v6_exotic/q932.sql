WITH 
  catalog_data AS (
    SELECT
      cr.cr_return_amount            AS return_amount,
      cr.cr_return_quantity          AS return_quantity,
      c.c_customer_id                AS customer_id,
      ca_refund.ca_state             AS state,
      cd_refund.cd_gender            AS gender,
      hd.hd_buy_potential            AS buy_potential,
      w.w_warehouse_name             AS warehouse_name,
      r.r_reason_desc                AS reason_desc,
      CASE WHEN cr.cr_return_amount > 1000 THEN 'High' ELSE 'Low' END AS return_category
    FROM catalog_returns cr
    JOIN catalog_sales cs               ON cr.cr_order_number = cs.cs_order_number
    JOIN customer c                     ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_address ca_refund     ON cr.cr_refunded_addr_sk = ca_refund.ca_address_sk
    JOIN customer_address ca_return     ON cr.cr_returning_addr_sk = ca_return.ca_address_sk
    JOIN customer_demographics cd_refund ON cr.cr_refunded_cdemo_sk = cd_refund.cd_demo_sk
    JOIN customer_demographics cd_return ON cr.cr_returning_cdemo_sk = cd_return.cd_demo_sk
    JOIN household_demographics hd       ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN warehouse w                    ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN reason r                       ON cr.cr_reason_sk = r.r_reason_sk
  ),
  store_data AS (
    SELECT
      sr.sr_return_amt               AS return_amount,
      sr.sr_return_quantity          AS return_quantity,
      c.c_customer_id                AS customer_id,
      ca.ca_state                    AS state,
      cd.cd_gender                   AS gender,
      hd.hd_buy_potential            AS buy_potential,
      CAST(NULL AS varchar)          AS warehouse_name,
      r.r_reason_desc                AS reason_desc,
      CASE WHEN sr.sr_return_amt > 500 THEN 'High' ELSE 'Low' END AS return_category
    FROM store_returns sr
    JOIN customer c               ON sr.sr_customer_sk = c.c_customer_sk
    JOIN customer_address ca      ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN reason r                  ON sr.sr_reason_sk = r.r_reason_sk
  )
SELECT
  return_category,
  state,
  gender,
  buy_potential,
  warehouse_name,
  reason_desc,
  SUM(return_amount) AS total_return_amount,
  SUM(return_quantity) AS total_return_quantity
FROM (
  SELECT * FROM catalog_data
  UNION ALL
  SELECT * FROM store_data
) AS combined
GROUP BY
  return_category,
  state,
  gender,
  buy_potential,
  warehouse_name,
  reason_desc
ORDER BY total_return_amount DESC
LIMIT 100
