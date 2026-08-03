WITH
  inv_agg AS (
    SELECT
      inv_item_sk,
      SUM(inv_quantity_on_hand) AS total_qty,
      COUNT(DISTINCT inv_date_sk) AS active_days
    FROM inventory
    WHERE inv_quantity_on_hand > 100
    GROUP BY inv_item_sk
  ),
  items_filtered AS (
    SELECT
      i_item_sk,
      i_category_id,
      i_formulation,
      i_current_price
    FROM item
    WHERE i_category_id IN (1, 3, 6)
  )
SELECT
  final.cc_name,
  final.web_name,
  final.year,
  final.category_id,
  final.total_qty,
  final.stock_level,
  final.distinct_items
FROM (
  SELECT
    cc1.cc_name AS cc_name,
    ws1.web_name AS web_name,
    d_inv.d_year AS year,
    itf.i_category_id AS category_id,
    SUM(ia.total_qty) AS total_qty,
    CASE
      WHEN SUM(ia.total_qty) > 1000 THEN 'High Stock'
      WHEN SUM(ia.total_qty) BETWEEN 501 AND 1000 THEN 'Medium Stock'
      ELSE 'Low Stock'
    END AS stock_level,
    COUNT(DISTINCT itf.i_item_sk) AS distinct_items
  FROM inv_agg ia
  JOIN inventory inv ON ia.inv_item_sk = inv.inv_item_sk
  JOIN date_dim d_inv ON inv.inv_date_sk = d_inv.d_date_sk
  JOIN items_filtered itf ON inv.inv_item_sk = itf.i_item_sk
  -- Call Center – first role (open date linked to inventory date)
  JOIN call_center cc1 ON cc1.cc_open_date_sk = d_inv.d_date_sk
  JOIN date_dim d_cc1_close ON cc1.cc_closed_date_sk = d_cc1_close.d_date_sk
  -- Call Center – second role (closed date linked to previous close)
  JOIN call_center cc2 ON cc2.cc_closed_date_sk = d_cc1_close.d_date_sk
  JOIN date_dim d_cc2_open ON cc2.cc_open_date_sk = d_cc2_open.d_date_sk
  -- Web Site – first role (open date linked to call‑center open)
  JOIN web_site ws1 ON ws1.web_open_date_sk = d_cc2_open.d_date_sk
  JOIN date_dim d_ws1_close ON ws1.web_close_date_sk = d_ws1_close.d_date_sk
  -- Web Site – second role (close date linked to previous close)
  JOIN web_site ws2 ON ws2.web_close_date_sk = d_ws1_close.d_date_sk
  JOIN date_dim d_ws2_open ON ws2.web_open_date_sk = d_ws2_open.d_date_sk
  WHERE d_inv.d_year = 2001
  GROUP BY cc1.cc_name, ws1.web_name, d_inv.d_year, itf.i_category_id
  HAVING SUM(ia.total_qty) > 0

  INTERSECT

  SELECT
    cc1.cc_name AS cc_name,
    ws1.web_name AS web_name,
    d_inv.d_year AS year,
    itf.i_category_id AS category_id,
    SUM(ia.total_qty) AS total_qty,
    CASE
      WHEN SUM(ia.total_qty) > 1000 THEN 'High Stock'
      WHEN SUM(ia.total_qty) BETWEEN 501 AND 1000 THEN 'Medium Stock'
      ELSE 'Low Stock'
    END AS stock_level,
    COUNT(DISTINCT itf.i_item_sk) AS distinct_items
  FROM inv_agg ia
  JOIN inventory inv ON ia.inv_item_sk = inv.inv_item_sk
  JOIN date_dim d_inv ON inv.inv_date_sk = d_inv.d_date_sk
  JOIN items_filtered itf ON inv.inv_item_sk = itf.i_item_sk
  JOIN call_center cc1 ON cc1.cc_open_date_sk = d_inv.d_date_sk
  JOIN date_dim d_cc1_close ON cc1.cc_closed_date_sk = d_cc1_close.d_date_sk
  JOIN web_site ws1 ON ws1.web_open_date_sk = d_cc1_close.d_date_sk
  JOIN date_dim d_ws1_close ON ws1.web_close_date_sk = d_ws1_close.d_date_sk
  WHERE d_inv.d_year = 2001
  GROUP BY cc1.cc_name, ws1.web_name, d_inv.d_year, itf.i_category_id
  HAVING COUNT(DISTINCT itf.i_item_sk) > 1
) AS final
ORDER BY final.total_qty DESC
