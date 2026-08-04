/*
Goal: Identify top items (by sales or returns) that also appear in inventory, showing aggregated metrics and the average inventory quantity per item. The query joins all ten selected tables, re‑uses the ITEM and CUSTOMER_DEMOGRAPHICS dimensions under multiple aliases, combines sales and return aggregates with UNION, intersects the result with the set of items present in inventory, and includes a correlated scalar subquery to compute average on‑hand quantity.
*/
WITH
  /* Sales side aggregation */
  sales_agg AS (
    SELECT
      i.i_item_id,
      i.i_item_sk,
      SUM(cs.cs_ext_sales_price)         AS total_sales,
      SUM(cs.cs_net_profit)               AS total_profit,
      (
        SELECT AVG(inv.inv_quantity_on_hand)
        FROM inventory inv
        WHERE inv.inv_item_sk = i.i_item_sk
      )                                    AS avg_inventory_qty
    FROM catalog_sales cs
    JOIN catalog_page cp      ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN item i               ON cs.cs_item_sk        = i.i_item_sk
    JOIN promotion p          ON cs.cs_promo_sk       = p.p_promo_sk
    JOIN ship_mode sm         ON cs.cs_ship_mode_sk   = sm.sm_ship_mode_sk
    JOIN customer_demographics cd_bill ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN customer_demographics cd_ship ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
    GROUP BY i.i_item_id, i.i_item_sk
  ),

  /* Returns side aggregation */
  returns_agg AS (
    SELECT
      i_ret.i_item_id,
      i_ret.i_item_sk,
      SUM(sr.sr_return_amt)        AS total_return_amt,
      SUM(sr.sr_return_quantity)   AS total_return_qty
    FROM store_returns sr
    JOIN item i_ret               ON sr.sr_item_sk    = i_ret.i_item_sk
    JOIN store s                  ON sr.sr_store_sk   = s.s_store_sk
    JOIN reason r                 ON sr.sr_reason_sk  = r.r_reason_sk
    JOIN customer_demographics cd_ret ON sr.sr_cdemo_sk = cd_ret.cd_demo_sk
    GROUP BY i_ret.i_item_id, i_ret.i_item_sk
  ),

  /* Distinct items that have inventory records */
  inventory_items AS (
    SELECT DISTINCT i_inv.i_item_id
    FROM inventory inv
    JOIN item i_inv ON inv.inv_item_sk = i_inv.i_item_sk
  ),

  /* Union of sales and returns metrics (distinct UNION) */
  union_all AS (
    SELECT
      i_item_id,
      total_sales      AS metric1,
      total_profit     AS metric2,
      avg_inventory_qty
    FROM sales_agg
    UNION
    SELECT
      i_item_id,
      total_return_amt AS metric1,
      total_return_qty AS metric2,
      CAST(NULL AS double) AS avg_inventory_qty
    FROM returns_agg
  ),

  /* Intersect the unioned set with items that actually have inventory */
  intersected AS (
    SELECT *
    FROM union_all
    INTERSECT
    SELECT i_item_id, CAST(NULL AS double), CAST(NULL AS double), CAST(NULL AS double)
    FROM inventory_items
  )
SELECT
  i_item_id,
  SUM(metric1) AS sum_metric1,
  SUM(metric2) AS sum_metric2,
  AVG(avg_inventory_qty) AS avg_inventory_qty_overall
FROM intersected
GROUP BY i_item_id
ORDER BY sum_metric1 DESC
LIMIT 100
