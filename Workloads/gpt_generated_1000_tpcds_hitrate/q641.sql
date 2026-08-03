WITH
  inv_item_cte AS (
    SELECT
      inv.inv_date_sk,
      inv.inv_item_sk,
      inv.inv_quantity_on_hand,
      it.i_item_sk,
      it.i_item_id,
      it.i_current_price,
      it.i_wholesale_cost,
      it.i_category,
      it.i_brand
    FROM inventory AS inv
    FULL OUTER JOIN item AS it
      ON inv.inv_item_sk = it.i_item_sk
    WHERE it.i_wholesale_cost > 10.00                -- predicate 1
      AND (inv.inv_quantity_on_hand IS NULL OR inv.inv_quantity_on_hand > 0)  -- predicate 2
  ),

  returns_date_cte AS (
    SELECT
      wr.wr_returned_date_sk,
      wr.wr_item_sk,
      wr.wr_return_quantity,
      wr.wr_return_amt,
      d.d_year,
      d.d_month_seq,
      d.d_date
    FROM web_returns AS wr
    RIGHT OUTER JOIN date_dim AS d
      ON wr.wr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001                         -- predicate 3
  ),

  combined_cte AS (
    SELECT
      i.inv_date_sk,
      i.inv_item_sk,
      i.inv_quantity_on_hand,
      i.i_item_sk,
      i.i_item_id,
      i.i_current_price,
      r.wr_return_quantity,
      r.wr_return_amt,
      r.d_year,
      r.d_month_seq
    FROM inv_item_cte AS i
    LEFT JOIN returns_date_cte AS r
      ON i.inv_date_sk = r.wr_returned_date_sk
     AND i.i_item_sk = r.wr_item_sk
  ),

  catalog_site_cte AS (
    SELECT
      cp.cp_catalog_page_id,
      cp.cp_department,
      cp.cp_catalog_number,
      ws.web_site_id,
      ws.web_name,
      d.d_year,
      d.d_month_seq
    FROM catalog_page AS cp
    JOIN date_dim AS d
      ON cp.cp_end_date_sk = d.d_date_sk
    JOIN web_site AS ws
      ON ws.web_open_date_sk = d.d_date_sk
    WHERE cp.cp_department = 'Sports'               -- predicate 4
      AND ws.web_state = 'CA'                        -- predicate 5
  ),

  unioned AS (
    SELECT
      c.i_item_sk               AS item_sk,
      c.inv_quantity_on_hand   AS qty_on_hand,
      c.wr_return_quantity     AS return_qty,
      c.d_year,
      c.d_month_seq
    FROM combined_cte AS c
    UNION
    SELECT
      NULL AS item_sk,
      NULL AS qty_on_hand,
      NULL AS return_qty,
      cs.d_year,
      cs.d_month_seq
    FROM catalog_site_cte AS cs
  )
SELECT
  u.d_year,
  u.d_month_seq,
  SUM(COALESCE(u.qty_on_hand, 0)) AS total_qty_on_hand,
  SUM(COALESCE(u.return_qty, 0))  AS total_return_qty,
  COUNT(*)                        AS row_count,
  (SELECT AVG(it2.i_current_price)
   FROM item AS it2
   WHERE it2.i_category = 'Electronics') AS avg_electronics_price
FROM unioned AS u
WHERE u.d_month_seq BETWEEN 1 AND 12               -- predicate 6
GROUP BY u.d_year, u.d_month_seq
HAVING SUM(COALESCE(u.qty_on_hand, 0)) > 0
ORDER BY u.d_year DESC, u.d_month_seq
