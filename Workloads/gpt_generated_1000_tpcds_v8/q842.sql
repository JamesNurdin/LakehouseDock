WITH
  sampled_returns AS (
    SELECT *
    FROM catalog_returns
    TABLESAMPLE BERNOULLI (10)
    WHERE cr_return_amount > 1000
  ),
  joined_base AS (
    SELECT
      cr.cr_returned_date_sk,
      cr.cr_call_center_sk AS cc_call_center_sk,
      cr.cr_catalog_page_sk,
      cr.cr_warehouse_sk,
      cr.cr_return_amount,
      cr.cr_return_quantity,
      d.d_year,
      d.d_month_seq,
      cc.cc_state,
      cc.cc_name,
      cp.cp_type,
      cp.cp_department,
      w.w_state,
      w.w_warehouse_name,
      inv.inv_quantity_on_hand
    FROM sampled_returns cr
    INNER JOIN date_dim d
      ON cr.cr_returned_date_sk = d.d_date_sk
    INNER JOIN call_center cc
      ON cr.cr_call_center_sk = cc.cc_call_center_sk
    INNER JOIN catalog_page cp
      ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    INNER JOIN warehouse w
      ON cr.cr_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN inventory inv
      ON inv.inv_warehouse_sk = w.w_warehouse_sk
      AND inv.inv_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND cc.cc_state = 'CA'
      AND w.w_state = 'CA'
      AND cp.cp_type = 'promo'
      AND (inv.inv_quantity_on_hand IS NULL OR inv.inv_quantity_on_hand > 500)
  ),
  agg_per_center AS (
    SELECT
      cc_call_center_sk,
      COUNT(*) AS num_returns,
      SUM(cr_return_amount) AS total_return_amount,
      AVG(cr_return_quantity) AS avg_return_qty,
      MAX(inv_quantity_on_hand) AS max_inventory_qty
    FROM joined_base
    GROUP BY cc_call_center_sk
  ),
  high_returns AS (
    SELECT cc_call_center_sk
    FROM agg_per_center
    WHERE total_return_amount > 50000
  ),
  high_inventory AS (
    SELECT cc_call_center_sk
    FROM agg_per_center
    WHERE max_inventory_qty > 1000
  ),
  center_intersect AS (
    SELECT cc_call_center_sk FROM high_returns
    INTERSECT
    SELECT cc_call_center_sk FROM high_inventory
  ),
  center_exclude AS (
    SELECT cc_call_center_sk FROM high_returns
    EXCEPT
    SELECT cc_call_center_sk FROM high_inventory
  ),
  final AS (
    SELECT
      a.cc_call_center_sk,
      a.num_returns,
      a.total_return_amount,
      a.avg_return_qty,
      a.max_inventory_qty,
      CASE WHEN i.cc_call_center_sk IS NOT NULL THEN 'Both' ELSE 'OnlyReturns' END AS category
    FROM agg_per_center a
    LEFT JOIN center_intersect i
      ON a.cc_call_center_sk = i.cc_call_center_sk
    WHERE a.cc_call_center_sk IN (SELECT cc_call_center_sk FROM center_intersect)
       OR a.cc_call_center_sk IN (SELECT cc_call_center_sk FROM center_exclude)
  )
SELECT
  cc_call_center_sk,
  num_returns,
  total_return_amount,
  avg_return_qty,
  max_inventory_qty,
  category
FROM final
ORDER BY total_return_amount DESC
OFFSET 0 ROWS FETCH NEXT 20 ROWS ONLY
