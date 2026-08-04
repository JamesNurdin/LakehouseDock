WITH store_items AS (
    SELECT DISTINCT i.i_item_id
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    WHERE t.t_hour BETWEEN 9 AND 17
      AND i.i_current_price > 100
),
catalog_items AS (
    SELECT DISTINCT i.i_item_id
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    WHERE cp.cp_department = 'DEPARTMENT'
      AND t.t_hour BETWEEN 9 AND 17
      AND i.i_current_price > 100
)
SELECT *
FROM store_items
INTERSECT
SELECT *
FROM catalog_items
LIMIT 100
