WITH avg_catalog_return AS (
    SELECT AVG(cr_return_amount) AS avg_return
    FROM catalog_returns
),
catalog_returns_agg AS (
    SELECT
        'CatalogReturn' AS source_type,
        i.i_item_id AS i_item_id,
        i.i_product_name AS i_product_name,
        SUM(cr.cr_return_amount) AS total_amount,
        ROW_NUMBER() OVER (ORDER BY SUM(cr.cr_return_amount) DESC) AS rank
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_year = 2020
      AND cp.cp_department = 'Electronics'
      AND cr.cr_return_amount > (SELECT avg_return FROM avg_catalog_return)
      AND EXISTS (
          SELECT 1
          FROM inventory inv
          WHERE inv.inv_item_sk = i.i_item_sk
            AND inv.inv_date_sk = d.d_date_sk
      )
    GROUP BY i.i_item_id, i.i_product_name
),
promotion_agg AS (
    SELECT
        'Promotion' AS source_type,
        i.i_item_id AS i_item_id,
        i.i_product_name AS i_product_name,
        SUM(p.p_cost) AS total_amount,
        ROW_NUMBER() OVER (ORDER BY SUM(p.p_cost) DESC) AS rank
    FROM promotion p
    JOIN date_dim d_start ON p.p_start_date_sk = d_start.d_date_sk
    JOIN item i ON p.p_item_sk = i.i_item_sk
    WHERE d_start.d_year = 2020
      AND p.p_channel_tv = 'N'
    GROUP BY i.i_item_id, i.i_product_name
)
SELECT source_type, i_item_id, i_product_name, total_amount, rank
FROM catalog_returns_agg
UNION ALL
SELECT source_type, i_item_id, i_product_name, total_amount, rank
FROM promotion_agg
ORDER BY source_type, rank
LIMIT 100
