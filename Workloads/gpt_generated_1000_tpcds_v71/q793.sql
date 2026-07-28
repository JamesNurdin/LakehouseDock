WITH catalog_data AS (
    SELECT
        i.i_item_id AS item_id,
        i.i_item_desc AS item_desc,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY i.i_category_id ORDER BY SUM(cs.cs_ext_sales_price) DESC) AS sales_rank,
        'catalog' AS source,
        i.i_category_id,
        (SELECT AVG(i2.i_current_price) FROM item i2 WHERE i2.i_category_id = i.i_category_id) AS avg_category_price
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    WHERE td.t_hour BETWEEN 9 AND 17
      AND EXISTS (
          SELECT 1 FROM promotion p WHERE p.p_item_sk = i.i_item_sk AND p.p_discount_active = 'Y'
      )
    GROUP BY i.i_item_id, i.i_item_desc, i.i_category_id
),
web_data AS (
    SELECT
        i.i_item_id AS item_id,
        i.i_item_desc AS item_desc,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY i.i_category_id ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank,
        'web' AS source,
        i.i_category_id,
        (SELECT AVG(i2.i_current_price) FROM item i2 WHERE i2.i_category_id = i.i_category_id) AS avg_category_price
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    WHERE td.t_hour BETWEEN 9 AND 17
      AND EXISTS (
          SELECT 1 FROM promotion p WHERE p.p_item_sk = i.i_item_sk AND p.p_discount_active = 'Y'
      )
    GROUP BY i.i_item_id, i.i_item_desc, i.i_category_id
)
SELECT
    item_id,
    item_desc,
    total_sales,
    sales_rank,
    source,
    avg_category_price
FROM catalog_data
UNION ALL
SELECT
    item_id,
    item_desc,
    total_sales,
    sales_rank,
    source,
    avg_category_price
FROM web_data
ORDER BY total_sales DESC
LIMIT 100
