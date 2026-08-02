/*
Goal: Aggregate total sales, returns, and inventory for each store and product by year, only for items that appear in both sales and inventory, exclude sales that have a matching return, and rank stores by sales while showing cumulative sales per item. The query demonstrates deep joins across all selected TPC‑DS tables, reuses dimensions under different aliases, includes a FULL OUTER JOIN, an INTERSECT CTE, an anti‑join, a correlated subquery and window functions.
*/
WITH
  common_items AS (
    SELECT inv_item_sk AS item_sk FROM inventory
    INTERSECT
    SELECT cs_item_sk FROM catalog_sales
  ),
  base AS (
    SELECT
      s.s_store_name,
      i.i_product_name,
      d_sold.d_year,
      i.i_item_sk,
      d_sold.d_date,
      cs.cs_net_paid,
      sr.sr_return_amt,
      inv.inv_quantity_on_hand
    FROM catalog_sales cs
    FULL OUTER JOIN warehouse w
      ON cs.cs_warehouse_sk = w.w_warehouse_sk
    INNER JOIN catalog_page cp
      ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    INNER JOIN item i
      ON cs.cs_item_sk = i.i_item_sk
    INNER JOIN ship_mode sm
      ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    INNER JOIN customer_address ca_bill
      ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    INNER JOIN customer_address ca_ship
      ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
    INNER JOIN date_dim d_sold
      ON cs.cs_sold_date_sk = d_sold.d_date_sk
    INNER JOIN date_dim d_ship
      ON cs.cs_ship_date_sk = d_ship.d_date_sk
    LEFT JOIN store_returns sr
      ON sr.sr_item_sk = i.i_item_sk
     AND sr.sr_returned_date_sk = d_sold.d_date_sk
    LEFT JOIN store s
      ON sr.sr_store_sk = s.s_store_sk
    LEFT JOIN reason r
      ON sr.sr_reason_sk = r.r_reason_sk
    LEFT JOIN customer_address ca_return
      ON sr.sr_addr_sk = ca_return.ca_address_sk
    LEFT JOIN date_dim d_return
      ON sr.sr_returned_date_sk = d_return.d_date_sk
    LEFT JOIN inventory inv
      ON inv.inv_item_sk = i.i_item_sk
     AND inv.inv_date_sk = d_sold.d_date_sk
    LEFT JOIN date_dim d_inventory
      ON inv.inv_date_sk = d_inventory.d_date_sk
    LEFT JOIN date_dim d_closed
      ON s.s_closed_date_sk = d_closed.d_date_sk
    LEFT JOIN date_dim d_start
      ON cp.cp_start_date_sk = d_start.d_date_sk
    LEFT JOIN date_dim d_end
      ON cp.cp_end_date_sk = d_end.d_date_sk
    LEFT JOIN web_page wp
      ON wp.wp_creation_date_sk = d_sold.d_date_sk
    LEFT JOIN date_dim d_web_creation
      ON wp.wp_creation_date_sk = d_web_creation.d_date_sk
    LEFT JOIN date_dim d_web_access
      ON wp.wp_access_date_sk = d_web_access.d_date_sk
    INNER JOIN common_items ci
      ON i.i_item_sk = ci.item_sk
    WHERE NOT EXISTS (
        SELECT 1
        FROM store_returns sr2
        WHERE sr2.sr_item_sk = cs.cs_item_sk
          AND sr2.sr_returned_date_sk = cs.cs_sold_date_sk
      )
  ),
  agg AS (
    SELECT
      s_store_name,
      i_product_name,
      d_year,
      i_item_sk,
      d_date,
      SUM(cs_net_paid) AS total_sales,
      SUM(sr_return_amt) AS total_returns,
      SUM(inv_quantity_on_hand) AS total_inventory
    FROM base
    GROUP BY
      s_store_name,
      i_product_name,
      d_year,
      i_item_sk,
      d_date
  )
SELECT
  s_store_name,
  i_product_name,
  d_year,
  total_sales,
  total_returns,
  total_inventory,
  (
    SELECT SUM(inv3.inv_quantity_on_hand)
    FROM inventory inv3
    JOIN date_dim d3 ON inv3.inv_date_sk = d3.d_date_sk
    WHERE inv3.inv_item_sk = agg.i_item_sk
      AND d3.d_date = agg.d_date
  ) AS inventory_on_sale_date,
  RANK() OVER (PARTITION BY s_store_name ORDER BY total_sales DESC) AS sales_rank,
  SUM(total_sales) OVER (
    PARTITION BY i_item_sk
    ORDER BY d_date
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
  ) AS cumulative_sales_by_item
FROM agg
ORDER BY total_sales DESC
LIMIT 100
