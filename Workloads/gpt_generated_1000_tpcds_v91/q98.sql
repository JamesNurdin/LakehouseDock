WITH
  catalog_sales_agg AS (
    SELECT
      cs.cs_item_sk,
      cs.cs_warehouse_sk,
      cs.cs_ship_mode_sk,
      cs.cs_catalog_page_sk,
      SUM(cs.cs_ext_sales_price) AS cs_total_sales,
      SUM(cs.cs_net_profit) AS cs_total_profit,
      SUM(cs.cs_quantity) AS cs_total_quantity
    FROM catalog_sales cs
    WHERE cs.cs_sold_date_sk BETWEEN 2450830 AND 2450840
    GROUP BY cs.cs_item_sk, cs.cs_warehouse_sk, cs.cs_ship_mode_sk, cs.cs_catalog_page_sk
  ),
  catalog_returns_agg AS (
    SELECT
      cr.cr_item_sk,
      cr.cr_warehouse_sk,
      cr.cr_ship_mode_sk,
      cr.cr_reason_sk,
      cr.cr_catalog_page_sk,
      SUM(cr.cr_return_amount) AS cr_total_return_amount,
      SUM(cr.cr_net_loss) AS cr_total_net_loss,
      SUM(cr.cr_return_quantity) AS cr_total_return_qty
    FROM catalog_returns cr
    WHERE cr.cr_returned_date_sk BETWEEN 2450830 AND 2450840
    GROUP BY cr.cr_item_sk, cr.cr_warehouse_sk, cr.cr_ship_mode_sk, cr.cr_reason_sk, cr.cr_catalog_page_sk
  ),
  store_sales_agg AS (
    SELECT
      ss.ss_store_sk,
      ss.ss_item_sk,
      SUM(ss.ss_ext_sales_price) AS ss_total_sales,
      SUM(ss.ss_net_profit) AS ss_total_profit,
      SUM(ss.ss_quantity) AS ss_total_quantity
    FROM store_sales ss
    WHERE ss.ss_sold_date_sk BETWEEN 2450830 AND 2450840
    GROUP BY ss.ss_store_sk, ss.ss_item_sk
  ),
  customer_agg AS (
    SELECT
      cs.cs_item_sk,
      COUNT(DISTINCT c.c_customer_sk) AS num_customers,
      COUNT(DISTINCT cd.cd_demo_sk) AS num_cust_demographics
    FROM catalog_sales cs
    LEFT JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    LEFT JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    WHERE cs.cs_sold_date_sk BETWEEN 2450830 AND 2450840
    GROUP BY cs.cs_item_sk
  )
SELECT
  s.s_store_id,
  s.s_state,
  i.i_item_id,
  i.i_category,
  sm.sm_type,
  cp.cp_catalog_number,
  CASE WHEN ss_agg.ss_total_profit > 10000 THEN 'HIGH' ELSE 'LOW' END AS profit_flag,
  ss_agg.ss_total_sales,
  ss_agg.ss_total_profit,
  cs_agg.cs_total_sales,
  cs_agg.cs_total_profit,
  cr_agg.cr_total_return_amount,
  cr_agg.cr_total_net_loss,
  w.w_warehouse_name,
  w.w_warehouse_sq_ft,
  inv.inv_quantity_on_hand,
  ca.num_customers,
  ca.num_cust_demographics,
  r.r_reason_desc AS return_reason,
  ROW_NUMBER() OVER (PARTITION BY s.s_store_id ORDER BY ss_agg.ss_total_profit DESC) AS item_rank_in_store
FROM store_sales_agg ss_agg
INNER JOIN store s ON ss_agg.ss_store_sk = s.s_store_sk
INNER JOIN item i ON ss_agg.ss_item_sk = i.i_item_sk
INNER JOIN inventory inv ON i.i_item_sk = inv.inv_item_sk
INNER JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
INNER JOIN catalog_sales_agg cs_agg ON cs_agg.cs_item_sk = i.i_item_sk AND cs_agg.cs_warehouse_sk = w.w_warehouse_sk
INNER JOIN ship_mode sm ON cs_agg.cs_ship_mode_sk = sm.sm_ship_mode_sk
INNER JOIN catalog_page cp ON cs_agg.cs_catalog_page_sk = cp.cp_catalog_page_sk
INNER JOIN catalog_returns_agg cr_agg ON cr_agg.cr_item_sk = i.i_item_sk AND cr_agg.cr_warehouse_sk = w.w_warehouse_sk
INNER JOIN reason r ON cr_agg.cr_reason_sk = r.r_reason_sk
INNER JOIN customer_agg ca ON ca.cs_item_sk = i.i_item_sk
WHERE
  s.s_state = 'CA'
  AND i.i_category = 'Electronics'
  AND sm.sm_type = 'EXPRESS'
  AND w.w_warehouse_sq_ft > 50000
  AND inv.inv_quantity_on_hand > 0
ORDER BY s.s_store_id, item_rank_in_store
LIMIT 100
