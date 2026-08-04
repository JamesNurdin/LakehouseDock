WITH cs_base AS (
  SELECT
    cs.cs_sold_date_sk,
    cs.cs_sold_time_sk,
    cs.cs_quantity,
    cs.cs_ext_sales_price,
    cs.cs_order_number,
    cs.cs_item_sk,
    cs.cs_promo_sk,
    cs.cs_call_center_sk,
    cs.cs_catalog_page_sk,
    cs.cs_ship_mode_sk,
    cs.cs_warehouse_sk,
    cs.cs_bill_customer_sk,
    cs.cs_bill_hdemo_sk,
    cs.cs_ship_customer_sk,
    cs.cs_ship_hdemo_sk,
    -- derived array for UNNEST
    ARRAY[cs.cs_quantity, CAST(cs.cs_ext_sales_price AS double)] AS qty_price_arr
  FROM tpcds.catalog_sales cs
)
SELECT
  c.c_customer_id,
  i.i_category,
  sm.sm_carrier,
  SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
  COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
  AVG(ss.ss_sales_price) AS avg_store_sales_price,
  MIN(w.w_warehouse_sq_ft) AS min_warehouse_sqft,
  MAX(ib.ib_upper_bound) AS max_income_upper,
  metric_val,
  (SELECT SUM(ss2.ss_ext_sales_price)
   FROM tpcds.store_sales ss2
   WHERE ss2.ss_customer_sk = c.c_customer_sk) AS cust_store_sales_total
FROM cs_base cs
JOIN tpcds.call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN tpcds.catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN tpcds.ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN tpcds.warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN tpcds.item i ON cs.cs_item_sk = i.i_item_sk
JOIN tpcds.promotion p ON cs.cs_promo_sk = p.p_promo_sk
JOIN tpcds.customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN tpcds.household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN tpcds.income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN tpcds.time_dim td_cs ON cs.cs_sold_time_sk = td_cs.t_time_sk
-- store_sales related joins
JOIN tpcds.store_sales ss ON ss.ss_item_sk = i.i_item_sk
JOIN tpcds.time_dim td_ss ON ss.ss_sold_time_sk = td_ss.t_time_sk
-- store_returns related joins
JOIN tpcds.store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
  AND sr.sr_item_sk = i.i_item_sk
JOIN tpcds.time_dim td_sr ON sr.sr_return_time_sk = td_sr.t_time_sk
-- web_returns related joins
JOIN tpcds.web_returns wr ON wr.wr_item_sk = i.i_item_sk
  AND wr.wr_refunded_customer_sk = c.c_customer_sk
JOIN tpcds.time_dim td_wr ON wr.wr_returned_time_sk = td_wr.t_time_sk
-- expand the derived array
CROSS JOIN UNNEST(cs.qty_price_arr) AS t(metric_val)
WHERE cs.cs_sold_date_sk = 20000101
  AND hd.hd_dep_count = 2
  AND sm.sm_carrier = 'ZHOU'
  AND cs.cs_quantity > (
        SELECT MAX(cs2.cs_quantity)
        FROM tpcds.catalog_sales cs2
        WHERE cs2.cs_sold_date_sk = 20000101
      )
GROUP BY
  c.c_customer_id,
  i.i_category,
  sm.sm_carrier,
  metric_val,
  c.c_customer_sk
LIMIT 100
