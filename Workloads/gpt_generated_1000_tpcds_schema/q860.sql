WITH
  ss_sample AS (
    SELECT *
    FROM store_sales
    TABLESAMPLE BERNOULLI (10)
  ),
  inventory_items AS (
    SELECT inv_item_sk FROM inventory
  ),
  sales_items AS (
    SELECT ss_item_sk FROM ss_sample
  ),
  items_not_sold AS (
    SELECT inv_item_sk
    FROM inventory_items
    EXCEPT
    SELECT ss_item_sk
    FROM sales_items
  ),
  not_sold_counts AS (
    SELECT COUNT(*) AS items_not_sold_cnt FROM items_not_sold
  ),
  sales_join AS (
    SELECT
      ss.ss_sold_date_sk,
      ss.ss_item_sk,
      ss.ss_quantity,
      ss.ss_net_paid,
      d_sales.d_year,
      i.i_category,
      i.i_brand,
      inv.inv_quantity_on_hand,
      cc.cc_name,
      cp.cp_catalog_number,
      cp.cp_type
    FROM ss_sample ss
    JOIN date_dim d_sales
      ON ss.ss_sold_date_sk = d_sales.d_date_sk
    JOIN item i
      ON ss.ss_item_sk = i.i_item_sk
    JOIN inventory inv
      ON inv.inv_item_sk = i.i_item_sk
    JOIN date_dim d_inv
      ON inv.inv_date_sk = d_inv.d_date_sk
    LEFT JOIN catalog_returns cr
      ON cr.cr_item_sk = i.i_item_sk
    LEFT JOIN call_center cc
      ON cr.cr_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN catalog_page cp
      ON cp.cp_catalog_page_sk = cr.cr_catalog_page_sk
    LEFT JOIN date_dim d_cp_start
      ON cp.cp_start_date_sk = d_cp_start.d_date_sk
    LEFT JOIN date_dim d_cp_end
      ON cp.cp_end_date_sk = d_cp_end.d_date_sk
    WHERE d_sales.d_year BETWEEN 2000 AND 2002
  ),
  agg_sales AS (
    SELECT
      cc_name,
      d_year,
      i_category,
      SUM(ss_quantity) AS total_quantity_sold,
      SUM(ss_net_paid) AS total_sales,
      SUM(inv_quantity_on_hand) AS total_inventory_on_hand,
      COUNT(DISTINCT ss_item_sk) AS distinct_items_sold
    FROM sales_join
    GROUP BY cc_name, d_year, i_category
  ),
  returns_join AS (
    SELECT
      cr.cr_item_sk,
      d_return.d_year,
      i_ret.i_category,
      SUM(cr.cr_return_quantity) AS total_return_qty,
      SUM(cr.cr_return_amount) AS total_return_amount
    FROM catalog_returns cr
    JOIN date_dim d_return
      ON cr.cr_returned_date_sk = d_return.d_date_sk
    JOIN item i_ret
      ON cr.cr_item_sk = i_ret.i_item_sk
    GROUP BY cr.cr_item_sk, d_return.d_year, i_ret.i_category
  ),
  agg_returns AS (
    SELECT
      d_year,
      i_category,
      SUM(total_return_qty) AS total_return_qty_year,
      SUM(total_return_amount) AS total_return_amount_year
    FROM returns_join
    GROUP BY d_year, i_category
  ),
  full_combined AS (
    SELECT
      s.cc_name,
      s.d_year,
      s.i_category,
      s.total_quantity_sold,
      s.total_sales,
      s.total_inventory_on_hand,
      r.total_return_qty_year,
      r.total_return_amount_year
    FROM agg_sales s
    FULL OUTER JOIN agg_returns r
      ON s.d_year = r.d_year AND s.i_category = r.i_category
  ),
  ranked AS (
    SELECT
      *,
      ROW_NUMBER() OVER (PARTITION BY cc_name ORDER BY total_sales DESC NULLS LAST) AS rnk
    FROM full_combined
    WHERE (total_sales IS NOT NULL AND total_sales > 10000)
       OR (total_return_amount_year IS NOT NULL AND total_return_amount_year > 5000)
  ),
  final AS (
    SELECT
      cc_name,
      d_year,
      i_category,
      total_quantity_sold,
      total_sales,
      total_inventory_on_hand,
      total_return_qty_year,
      total_return_amount_year,
      ns.items_not_sold_cnt
    FROM ranked r
    CROSS JOIN not_sold_counts ns
    WHERE rnk <= 3
  )
SELECT
  cc_name,
  d_year,
  i_category,
  total_quantity_sold,
  total_sales,
  total_inventory_on_hand,
  total_return_qty_year,
  total_return_amount_year,
  items_not_sold_cnt
FROM final
ORDER BY cc_name, d_year, i_category
LIMIT 100
