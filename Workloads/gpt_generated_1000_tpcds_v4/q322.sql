WITH
  cr AS (
    SELECT
      cr.cr_item_sk,
      cr.cr_return_amount,
      cr.cr_return_quantity,
      cr.cr_returned_date_sk,
      cr.cr_returned_time_sk,
      cr.cr_refunded_customer_sk,
      cr.cr_returning_customer_sk,
      cr.cr_refunded_cdemo_sk,
      cr.cr_returning_cdemo_sk,
      cr.cr_catalog_page_sk,
      cr.cr_ship_mode_sk,
      cr.cr_reason_sk,
      cr.cr_order_number
    FROM catalog_returns cr
    WHERE EXISTS (
      SELECT 1
      FROM store_returns sr
      WHERE sr.sr_item_sk = cr.cr_item_sk
        AND sr.sr_returned_date_sk = cr.cr_returned_date_sk
    )
  ),
  sr AS (
    SELECT
      sr.sr_item_sk,
      sr.sr_return_amt,
      sr.sr_return_quantity,
      sr.sr_returned_date_sk,
      sr.sr_reason_sk,
      sr.sr_customer_sk,
      sr.sr_cdemo_sk,
      sr.sr_store_sk,
      sr.sr_ticket_number
    FROM store_returns sr
  ),
  ws AS (
    SELECT
      ws.ws_item_sk,
      ws.ws_ext_sales_price,
      ws.ws_quantity,
      ws.ws_sold_date_sk,
      ws.ws_ship_mode_sk,
      ws.ws_promo_sk,
      ws.ws_bill_customer_sk,
      ws.ws_ship_customer_sk,
      ws.ws_bill_cdemo_sk,
      ws.ws_ship_cdemo_sk,
      ws.ws_order_number
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk BETWEEN 2449154 AND 2451903
  )
SELECT
  i.i_brand               AS brand,
  i.i_category            AS category,
  p.p_promo_name          AS promo_name,
  sm_cr.sm_type           AS catalog_ship_type,
  r_cr.r_reason_desc      AS catalog_return_reason,
  cp.cp_department        AS catalog_department,
  COUNT(DISTINCT cr.cr_order_number)        AS num_catalog_returns,
  SUM(cr.cr_return_amount)                  AS total_catalog_return_amount,
  COUNT(DISTINCT sr.sr_ticket_number)       AS num_store_returns,
  SUM(sr.sr_return_amt)                     AS total_store_return_amount,
  SUM(ws.ws_ext_sales_price)                AS total_web_sales,
  COUNT(DISTINCT ws.ws_order_number)        AS num_web_orders
FROM cr
JOIN item i
  ON cr.cr_item_sk = i.i_item_sk
JOIN customer cr_ref_cust
  ON cr.cr_refunded_customer_sk = cr_ref_cust.c_customer_sk
JOIN customer cr_ret_cust
  ON cr.cr_returning_customer_sk = cr_ret_cust.c_customer_sk
JOIN customer_demographics cr_ref_cdemo
  ON cr.cr_refunded_cdemo_sk = cr_ref_cdemo.cd_demo_sk
JOIN customer_demographics cr_ret_cdemo
  ON cr.cr_returning_cdemo_sk = cr_ret_cdemo.cd_demo_sk
JOIN catalog_page cp
  ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm_cr
  ON cr.cr_ship_mode_sk = sm_cr.sm_ship_mode_sk
JOIN reason r_cr
  ON cr.cr_reason_sk = r_cr.r_reason_sk
JOIN store_returns sr
  ON cr.cr_item_sk = sr.sr_item_sk
JOIN reason r_sr
  ON sr.sr_reason_sk = r_sr.r_reason_sk
JOIN web_sales ws
  ON cr.cr_item_sk = ws.ws_item_sk
JOIN promotion p
  ON ws.ws_promo_sk = p.p_promo_sk
  AND p.p_item_sk = i.i_item_sk
JOIN ship_mode sm_ws
  ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
GROUP BY
  i.i_brand,
  i.i_category,
  p.p_promo_name,
  sm_cr.sm_type,
  r_cr.r_reason_desc,
  cp.cp_department
ORDER BY total_web_sales DESC
LIMIT 100
