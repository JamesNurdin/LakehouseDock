WITH
  sales_agg AS (
    SELECT
      s.s_store_name,
      i.i_brand,
      w.w_warehouse_name,
      i.i_item_sk,
      SUM(ss.ss_net_paid) AS total_sales,
      COUNT(DISTINCT ss.ss_customer_sk) AS uniq_customers,
      SUM(ss.ss_quantity) AS total_quantity
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE i.i_class_id IN (1, 3, 7)
      AND i.i_manager_id = 27
      AND cd.cd_purchase_estimate >= 3000
      AND cd.cd_dep_college_count <= 2
      AND w.w_state = 'CA'
      AND s.s_state = 'CA'
      AND ss.ss_sold_date_sk BETWEEN 2450000 AND 2452000
      AND inv.inv_quantity_on_hand > 0
    GROUP BY s.s_store_name, i.i_brand, w.w_warehouse_name, i.i_item_sk
  ),

  returns_agg AS (
    SELECT
      s.s_store_name,
      i.i_brand,
      w.w_warehouse_name,
      i.i_item_sk,
      SUM(cr.cr_net_loss) AS total_loss,
      COUNT(DISTINCT sr.sr_customer_sk) AS uniq_return_customers,
      SUM(sr.sr_return_quantity) AS total_return_qty
    FROM store_returns sr
    JOIN store_sales ss ON sr.sr_ticket_number = ss.ss_ticket_number
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE i.i_class_id IN (1, 3, 7)
      AND i.i_manager_id = 27
      AND cd.cd_purchase_estimate >= 3000
      AND cd.cd_dep_college_count <= 2
      AND w.w_state = 'CA'
      AND s.s_state = 'CA'
      AND sr.sr_returned_date_sk BETWEEN 2450000 AND 2452000
      AND inv.inv_quantity_on_hand > 0
    GROUP BY s.s_store_name, i.i_brand, w.w_warehouse_name, i.i_item_sk
  ),

  union_data AS (
    SELECT
      s_store_name,
      i_brand,
      w_warehouse_name,
      i_item_sk,
      total_sales AS metric,
      uniq_customers AS metric2,
      total_quantity AS metric3
    FROM sales_agg
    UNION DISTINCT
    SELECT
      s_store_name,
      i_brand,
      w_warehouse_name,
      i_item_sk,
      total_loss AS metric,
      uniq_return_customers AS metric2,
      total_return_qty AS metric3
    FROM returns_agg
  ),

  ranked AS (
    SELECT
      s_store_name,
      i_brand,
      w_warehouse_name,
      i_item_sk,
      metric,
      metric2,
      metric3,
      ROW_NUMBER() OVER (PARTITION BY s_store_name ORDER BY metric DESC) AS rn
    FROM union_data
  ),

  top_per_store AS (
    SELECT * FROM ranked WHERE rn <= 3
  ),

  intersect_items AS (
    SELECT i.i_item_sk FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE ss.ss_sold_date_sk BETWEEN 2450000 AND 2452000
    INTERSECT
    SELECT i.i_item_sk FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    WHERE sr.sr_returned_date_sk BETWEEN 2450000 AND 2452000
  )
SELECT
  tps.s_store_name,
  tps.i_brand,
  tps.w_warehouse_name,
  tps.metric,
  tps.metric2,
  tps.metric3
FROM top_per_store tps
JOIN intersect_items ii ON tps.i_item_sk = ii.i_item_sk
ORDER BY tps.metric DESC
LIMIT 100
