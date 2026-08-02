WITH sales_items AS (
   SELECT DISTINCT
          concat('item_', CAST(cs.cs_item_sk AS VARCHAR)) AS item_key,
          cs.cs_item_sk
   FROM catalog_sales cs
   JOIN catalog_page cp
     ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN date_dim d
     ON cs.cs_sold_date_sk = d.d_date_sk
   WHERE regexp_like(cp.cp_description, '[0-9]{3}')
     AND cp.cp_department LIKE 'Sports%'
     AND d.d_year = 2001
),
inventory_items AS (
   SELECT DISTINCT
          concat('item_', CAST(i.inv_item_sk AS VARCHAR)) AS item_key,
          i.inv_item_sk
   FROM inventory i
   JOIN warehouse w
     ON i.inv_warehouse_sk = w.w_warehouse_sk
   JOIN date_dim d
     ON i.inv_date_sk = d.d_date_sk
   WHERE regexp_like(w.w_state, '^(OH|GA|TN)$')
     AND i.inv_quantity_on_hand > 0
     AND d.d_year = 2001
),
returns_items AS (
   SELECT DISTINCT
          concat('item_', CAST(sr.sr_item_sk AS VARCHAR)) AS item_key,
          sr.sr_item_sk
   FROM store_returns sr
   JOIN reason r
     ON sr.sr_reason_sk = r.r_reason_sk
   JOIN date_dim d
     ON sr.sr_returned_date_sk = d.d_date_sk
   WHERE regexp_like(r.r_reason_desc, '(damage|defect)')
     AND d.d_year = 2001
),
intersected_items AS (
   SELECT item_key FROM sales_items
   INTERSECT
   SELECT item_key FROM inventory_items
),
filtered_items AS (
   SELECT item_key FROM intersected_items
   EXCEPT
   SELECT item_key FROM returns_items
)
SELECT
   fi.item_key,
   concat('Item ', substr(fi.item_key, 6)) AS item_label,
   sum(cs.cs_ext_sales_price) AS total_sales
FROM filtered_items fi
JOIN catalog_sales cs
  ON CAST(substr(fi.item_key, 6) AS INTEGER) = cs.cs_item_sk
JOIN date_dim d
  ON cs.cs_sold_date_sk = d.d_date_sk
WHERE d.d_year = 2001
  AND EXISTS (
        SELECT 1
        FROM catalog_sales cs2
        JOIN catalog_page cp2
          ON cs2.cs_catalog_page_sk = cp2.cp_catalog_page_sk
        WHERE cs2.cs_item_sk = cs.cs_item_sk
          AND cp2.cp_type LIKE 'A%'
          AND regexp_like(cp2.cp_type, '^A|B')
          AND cs2.cs_coupon_amt > 0
      )
GROUP BY fi.item_key, concat('Item ', substr(fi.item_key, 6))
ORDER BY total_sales DESC
LIMIT 100
