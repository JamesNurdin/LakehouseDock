WITH
  catalog_sales_filtered AS (
    SELECT *
    FROM catalog_sales
    WHERE cs_sold_date_sk BETWEEN 2450000 AND 2451000
      AND cs_ext_discount_amt > 500
      AND cs_net_profit > 0
      AND cs_ext_sales_price > 1000
  ),
  store_sales_filtered AS (
    SELECT *
    FROM store_sales
    WHERE ss_sold_date_sk BETWEEN 2450000 AND 2451000
      AND ss_ext_discount_amt > 300
      AND ss_net_profit > 0
      AND ss_ext_sales_price > 800
  ),
  joined_all AS (
    SELECT
      cs.cs_order_number,
      cs.cs_sold_date_sk,
      cs.cs_ext_sales_price,
      cs.cs_net_profit,
      ss.ss_ticket_number,
      ss.ss_sold_date_sk,
      ss.ss_net_paid,
      ca.ca_state,
      cc.cc_state AS cc_state,
      cp.cp_department,
      w.w_warehouse_name,
      p.p_promo_name,
      ib.ib_upper_bound,
      hd.hd_buy_potential
    FROM catalog_sales_filtered cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN store_sales_filtered ss
      ON ss.ss_sold_time_sk = td.t_time_sk
     AND ss.ss_hdemo_sk    = hd.hd_demo_sk
     AND ss.ss_addr_sk     = ca.ca_address_sk
     AND ss.ss_promo_sk    = p.p_promo_sk
  ),
  order_keys AS (
    SELECT cs_order_number AS order_key FROM catalog_sales_filtered
  ),
  ticket_keys AS (
    SELECT ss_ticket_number AS order_key FROM store_sales_filtered
  ),
  intersect_keys AS (
    SELECT order_key FROM order_keys
    INTERSECT
    SELECT order_key FROM ticket_keys
  ),
  except_keys AS (
    SELECT order_key FROM order_keys
    EXCEPT
    SELECT order_key FROM ticket_keys
  ),
  inventory_full AS (
    SELECT inv.inv_item_sk,
           inv.inv_quantity_on_hand,
           w.w_warehouse_name
    FROM inventory inv
    FULL OUTER JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
  )
SELECT
  ij.order_key,
  COUNT(*) AS cnt,
  SUM(j.cs_ext_sales_price) AS total_sales,
  AVG(j.cs_net_profit)      AS avg_profit,
  MIN(j.cs_ext_sales_price) AS min_sales,
  MAX(j.cs_ext_sales_price) AS max_sales
FROM joined_all j
JOIN intersect_keys ij ON j.cs_order_number = ij.order_key
WHERE j.ca_state = 'CA'
  AND j.cc_state = 'CA'
  AND j.cp_department = 'Electronics'
  AND j.ib_upper_bound >= 80000
GROUP BY ij.order_key
ORDER BY total_sales DESC
LIMIT 100
