WITH
  filtered_sales AS (
    SELECT
      cs.cs_sold_date_sk,
      cs.cs_sold_time_sk,
      cs.cs_ship_date_sk,
      cs.cs_bill_customer_sk,
      cs.cs_bill_cdemo_sk,
      cs.cs_bill_hdemo_sk,
      cs.cs_bill_addr_sk,
      cs.cs_ship_customer_sk,
      cs.cs_ship_cdemo_sk,
      cs.cs_ship_hdemo_sk,
      cs.cs_ship_addr_sk,
      cs.cs_call_center_sk,
      cs.cs_catalog_page_sk,
      cs.cs_ship_mode_sk,
      cs.cs_warehouse_sk,
      cs.cs_item_sk,
      cs.cs_promo_sk,
      cs.cs_order_number,
      cs.cs_quantity,
      cs.cs_wholesale_cost,
      cs.cs_list_price,
      cs.cs_sales_price,
      cs.cs_ext_discount_amt,
      cs.cs_ext_sales_price,
      cs.cs_ext_wholesale_cost,
      cs.cs_ext_list_price,
      cs.cs_ext_tax,
      cs.cs_coupon_amt,
      cs.cs_ext_ship_cost,
      cs.cs_net_paid,
      cs.cs_net_paid_inc_tax,
      cs.cs_net_paid_inc_ship,
      cs.cs_net_paid_inc_ship_tax,
      cs.cs_net_profit
    FROM
      tpcds.catalog_sales cs
    WHERE
      cs.cs_quantity > 1
      AND cs.cs_sales_price > 10
      AND cs.cs_wholesale_cost < 50
      AND cs.cs_ext_discount_amt > 0
      AND cs.cs_ship_date_sk BETWEEN 2450900 AND 2451200
      AND cs.cs_ship_mode_sk IN (
        SELECT sm_ship_mode_sk FROM tpcds.ship_mode WHERE sm_carrier = 'FEDEX'
      )
      AND cs.cs_warehouse_sk IN (
        SELECT w_warehouse_sk FROM tpcds.warehouse WHERE w_gmt_offset = -5.00
      )
  ),
  sm_w_full AS (
    SELECT
      sm.sm_ship_mode_sk,
      sm.sm_ship_mode_id,
      sm.sm_type AS sm_type,
      sm.sm_code,
      sm.sm_carrier,
      sm.sm_contract,
      w.w_warehouse_sk,
      w.w_warehouse_id,
      w.w_warehouse_name,
      w.w_warehouse_sq_ft,
      w.w_street_number,
      w.w_street_name,
      w.w_street_type,
      w.w_suite_number,
      w.w_city,
      w.w_county,
      w.w_state,
      w.w_zip,
      w.w_country,
      w.w_gmt_offset
    FROM
      tpcds.ship_mode sm
      FULL OUTER JOIN tpcds.warehouse w ON 1 = 0
  )
SELECT
  cp.cp_department,
  sm_w_full.sm_carrier,
  sm_w_full.w_county,
  SUM(fs.cs_ext_sales_price) AS total_sales,
  SUM(fs.cs_quantity) AS total_quantity,
  AVG(fs.cs_ext_discount_amt) AS avg_discount,
  MIN(fs.cs_sales_price) AS min_sales_price,
  MAX(fs.cs_sales_price) AS max_sales_price,
  COUNT(DISTINCT fs.cs_order_number) AS distinct_orders,
  ROW_NUMBER() OVER (PARTITION BY cp.cp_department ORDER BY SUM(fs.cs_ext_sales_price) DESC) AS dept_sales_rank,
  (SELECT MAX(sm_code) FROM tpcds.ship_mode) AS max_ship_code
FROM
  filtered_sales fs
  INNER JOIN tpcds.catalog_page cp ON fs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  LEFT JOIN sm_w_full ON fs.cs_ship_mode_sk = sm_w_full.sm_ship_mode_sk
      AND fs.cs_warehouse_sk = sm_w_full.w_warehouse_sk
GROUP BY
  cp.cp_department,
  sm_w_full.sm_carrier,
  sm_w_full.w_county
ORDER BY
  total_sales DESC
LIMIT 100
