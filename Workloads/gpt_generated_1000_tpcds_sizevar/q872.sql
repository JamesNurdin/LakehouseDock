WITH
  sales_base AS (
    SELECT cs.cs_order_number,
           cs.cs_quantity,
           cs.cs_net_paid,
           cs.cs_call_center_sk,
           cs.cs_catalog_page_sk,
           cs.cs_warehouse_sk,
           cs.cs_bill_cdemo_sk,
           cs.cs_ship_cdemo_sk,
           cs.cs_bill_hdemo_sk,
           cs.cs_ship_hdemo_sk,
           cs.cs_item_sk
    FROM catalog_sales cs
  ),
  returns_base AS (
    SELECT cr.cr_order_number,
           cr.cr_return_amount,
           cr.cr_reason_sk,
           cr.cr_call_center_sk,
           cr.cr_warehouse_sk,
           cr.cr_catalog_page_sk,
           cr.cr_refunded_cdemo_sk,
           cr.cr_refunded_hdemo_sk
    FROM catalog_returns cr
  ),
  orders_without_returns AS (
    SELECT cs_order_number
    FROM sales_base
    EXCEPT
    SELECT cr_order_number
    FROM returns_base
  ),
  high_quantity_orders AS (
    SELECT cs_order_number
    FROM sales_base
    WHERE cs_quantity > 10
  ),
  high_return_amount_orders AS (
    SELECT cr_order_number
    FROM returns_base
    WHERE cr_return_amount > 1000
  ),
  intersect_orders AS (
    SELECT cs_order_number
    FROM high_quantity_orders
    INTERSECT
    SELECT cr_order_number
    FROM high_return_amount_orders
  ),
  agg_sales AS (
    SELECT
      cs.cs_order_number,
      cc.cc_name,
      cp.cp_type,
      w.w_warehouse_name,
      cd_bill.cd_gender AS bill_gender,
      cd_ship.cd_gender AS ship_gender,
      hd_bill.hd_income_band_sk AS bill_income_band,
      hd_ship.hd_income_band_sk AS ship_income_band,
      SUM(cs.cs_net_paid) AS total_net_paid,
      COUNT(DISTINCT cs.cs_item_sk) AS distinct_items,
      SUM(cs.cs_quantity) AS total_quantity,
      (SELECT SUM(cr2.cr_return_amount)
         FROM catalog_returns cr2
        WHERE cr2.cr_order_number = cs.cs_order_number) AS total_return_amount
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN (SELECT * FROM warehouse TABLESAMPLE BERNOULLI (10)) w
      ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN customer_demographics cd_bill ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN customer_demographics cd_ship ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
    JOIN household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN household_demographics hd_ship ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
    LEFT JOIN catalog_returns cr ON cs.cs_order_number = cr.cr_order_number
    LEFT JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    LEFT JOIN call_center cc_ret ON cr.cr_call_center_sk = cc_ret.cc_call_center_sk
    LEFT JOIN catalog_page cp_ret ON cr.cr_catalog_page_sk = cp_ret.cp_catalog_page_sk
    LEFT JOIN warehouse w_ret ON cr.cr_warehouse_sk = w_ret.w_warehouse_sk
    WHERE cs.cs_order_number IN (SELECT cs_order_number FROM intersect_orders)
      AND cs.cs_order_number IN (SELECT cs_order_number FROM orders_without_returns)
    GROUP BY
      cs.cs_order_number,
      cc.cc_name,
      cp.cp_type,
      w.w_warehouse_name,
      cd_bill.cd_gender,
      cd_ship.cd_gender,
      hd_bill.hd_income_band_sk,
      hd_ship.hd_income_band_sk
  )
SELECT
  cs_order_number,
  cc_name,
  cp_type,
  w_warehouse_name,
  bill_gender,
  ship_gender,
  bill_income_band,
  ship_income_band,
  total_net_paid,
  distinct_items,
  total_return_amount,
  CASE WHEN total_quantity > 50 THEN 'Large' ELSE 'Regular' END AS order_size_category
FROM agg_sales
ORDER BY total_net_paid DESC
OFFSET 20 LIMIT 100
