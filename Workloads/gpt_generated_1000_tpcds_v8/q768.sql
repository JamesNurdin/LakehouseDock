WITH
  -- 1. Items sold via web_sales (distinct list)
  sold_items AS (
    SELECT DISTINCT ws.ws_item_sk
    FROM web_sales ws
  ),
  -- 2. Items that have a return record
  returned_items AS (
    SELECT DISTINCT cr.cr_item_sk
    FROM catalog_returns cr
  ),
  -- 3. Items sold but never returned (EXCEPT example)
  items_not_returned AS (
    SELECT ws_item_sk
    FROM sold_items
    EXCEPT
    SELECT cr_item_sk
    FROM returned_items
  ),
  -- 4. Aggregate sales, keeping all web sites (RIGHT OUTER JOIN example)
  sales_agg AS (
    SELECT
      ws_site.web_site_id      AS key1,
      ws_site.web_name         AS key2,
      SUM(ws.ws_ext_sales_price) AS metric,
      ROW_NUMBER() OVER (
        PARTITION BY ws_site.web_site_id
        ORDER BY SUM(ws.ws_ext_sales_price) DESC
      ) AS rank_val
    FROM web_sales ws
    RIGHT OUTER JOIN web_site ws_site
      ON ws.ws_web_site_sk = ws_site.web_site_sk
    JOIN item i_sales
      ON ws.ws_item_sk = i_sales.i_item_sk
    JOIN warehouse w_sales
      ON ws.ws_warehouse_sk = w_sales.w_warehouse_sk
    JOIN time_dim t_sales
      ON ws.ws_sold_time_sk = t_sales.t_time_sk
    LEFT JOIN inventory inv_sales
      ON inv_sales.inv_item_sk = i_sales.i_item_sk
     AND inv_sales.inv_warehouse_sk = w_sales.w_warehouse_sk
    -- keep only items that were never returned (semi‑join via EXISTS)
    WHERE EXISTS (
      SELECT 1
      FROM items_not_returned nr
      WHERE nr.ws_item_sk = ws.ws_item_sk
    )
    -- anti‑join: exclude very large refunds (NOT EXISTS example)
    AND NOT EXISTS (
      SELECT 1
      FROM catalog_returns cr
      WHERE cr.cr_item_sk = i_sales.i_item_sk
        AND cr.cr_return_amount > 1000
    )
    GROUP BY ws_site.web_site_id, ws_site.web_name
    HAVING SUM(ws.ws_ext_sales_price) > 0
  ),
  -- 5. Aggregate returns per catalog page
  returns_agg AS (
    SELECT
      CAST(cp.cp_catalog_number AS varchar) AS key1,
      cp.cp_department                AS key2,
      SUM(cr.cr_return_amount)        AS metric,
      ROW_NUMBER() OVER (
        PARTITION BY cp.cp_department
        ORDER BY SUM(cr.cr_return_amount) DESC
      ) AS rank_val
    FROM catalog_returns cr
    JOIN catalog_page cp
      ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN item i_ret
      ON cr.cr_item_sk = i_ret.i_item_sk
    JOIN warehouse w_ret
      ON cr.cr_warehouse_sk = w_ret.w_warehouse_sk
    JOIN time_dim t_ret
      ON cr.cr_returned_time_sk = t_ret.t_time_sk
    GROUP BY cp.cp_catalog_number, cp.cp_department
  ),
  -- 6. Combine the two aggregates (UNION DISTINCT example)
  combined AS (
    SELECT 'sales'   AS src_type, key1, key2, metric, rank_val FROM sales_agg
    UNION DISTINCT
    SELECT 'returns' AS src_type, key1, key2, metric, rank_val FROM returns_agg
  ),
  -- 7. Keys to exclude (ANTI‑JOIN example using NOT IN)
  excluded_keys AS (
    SELECT CAST(inv.inv_item_sk AS varchar) AS key1
    FROM inventory inv
    WHERE inv.inv_quantity_on_hand = 0
  ),
  -- 8. Final result after filtering excluded keys
  final_set AS (
    SELECT *
    FROM combined
    WHERE key1 NOT IN (SELECT key1 FROM excluded_keys)
  )
SELECT
  src_type,
  key1,
  key2,
  metric,
  rank_val
FROM final_set
ORDER BY src_type, metric DESC
OFFSET 0 ROWS FETCH NEXT 20 ROWS ONLY
