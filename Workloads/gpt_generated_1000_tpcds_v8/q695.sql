WITH
  cr_sample AS (
    SELECT *
    FROM catalog_returns
    TABLESAMPLE BERNOULLI (10)
    WHERE cr_return_amount > 0
  ),
  joined_base AS (
    SELECT
      cr.cr_returned_date_sk,
      cr.cr_return_amount,
      cr.cr_fee,
      td.t_hour AS td_hour,
      cp.cp_department,
      cc.cc_name,
      sr.sr_return_amt,
      ws.ws_ext_sales_price
    FROM cr_sample cr
    JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
    JOIN household_demographics hd_refunded ON cr.cr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
    JOIN customer_address ca_refunded ON cr.cr_refunded_addr_sk = ca_refunded.ca_address_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN store_returns sr ON sr.sr_return_time_sk = td.t_time_sk
    LEFT JOIN web_sales ws ON ws.ws_sold_time_sk = td.t_time_sk
    LEFT JOIN household_demographics hd_bill ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
    LEFT JOIN customer_address ca_bill ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
    LEFT JOIN household_demographics hd_ship ON ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
    LEFT JOIN customer_address ca_ship ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
  )
SELECT
  jd.td_hour,
  jd.cp_department,
  jd.cc_name,
  COUNT(DISTINCT jd.cr_returned_date_sk) AS distinct_return_days,
  SUM(jd.cr_return_amount) AS total_return_amount,
  SUM(jd.sr_return_amt) AS total_store_return_amt,
  SUM(jd.ws_ext_sales_price) AS total_web_sales,
  CASE WHEN SUM(jd.cr_return_amount) > 10000 THEN 'HIGH' ELSE 'LOW' END AS return_level,
  (
    SELECT COUNT(*)
    FROM (
      SELECT cr_order_number FROM catalog_returns
      INTERSECT
      SELECT sr_ticket_number FROM store_returns
    ) AS intersect_keys
  ) AS intersect_count,
  (
    SELECT COUNT(*)
    FROM (
      SELECT ws_order_number FROM web_sales
      EXCEPT
      SELECT cr_order_number FROM catalog_returns
    ) AS except_keys
  ) AS except_count,
  (
    SELECT COUNT(*)
    FROM (
      SELECT cr_returned_date_sk FROM catalog_returns
      UNION
      SELECT sr_returned_date_sk FROM store_returns
    ) AS union_keys
  ) AS union_key_count
FROM joined_base jd
GROUP BY jd.td_hour, jd.cp_department, jd.cc_name
ORDER BY total_return_amount DESC
LIMIT 100
