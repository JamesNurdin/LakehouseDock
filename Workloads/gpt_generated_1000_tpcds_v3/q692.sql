WITH item_returns AS (
    SELECT
        'Item' AS entity_type,
        i.i_item_id AS entity_id,
        i.i_product_name AS description,
        SUM(cr.cr_return_amt_inc_tax) AS total_return_amount,
        SUM(cr.cr_return_quantity) AS total_return_quantity
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE i.i_size = 'large'
      AND cr.cr_return_quantity > 10
      AND i.i_rec_start_date >= DATE '2021-01-01'
      AND cp.cp_department = 'Electronics'
      AND i.i_brand IN (
          SELECT DISTINCT i2.i_brand
          FROM catalog_returns cr2
          JOIN item i2 ON cr2.cr_item_sk = i2.i_item_sk
          GROUP BY i2.i_brand
          HAVING AVG(cr2.cr_return_amt_inc_tax) > 100
      )
    GROUP BY i.i_item_id, i.i_product_name
),
catalog_page_returns AS (
    SELECT
        'CatalogPage' AS entity_type,
        CAST(cp.cp_catalog_page_number AS VARCHAR) AS entity_id,
        cp.cp_description AS description,
        SUM(cr.cr_return_amt_inc_tax) AS total_return_amount,
        SUM(cr.cr_return_quantity) AS total_return_quantity
    FROM catalog_returns cr
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    WHERE cp.cp_catalog_page_number BETWEEN 1 AND 10
      AND i.i_class = 'fragrances'
      AND EXISTS (
          SELECT 1
          FROM catalog_returns cr3
          WHERE cr3.cr_catalog_page_sk = cp.cp_catalog_page_sk
            AND cr3.cr_return_quantity > 20
      )
    GROUP BY cp.cp_catalog_page_number, cp.cp_description
)
SELECT
    entity_type,
    entity_id,
    description,
    total_return_amount,
    total_return_quantity
FROM (
    SELECT entity_type, entity_id, description, total_return_amount, total_return_quantity
    FROM item_returns
    UNION ALL
    SELECT entity_type, entity_id, description, total_return_amount, total_return_quantity
    FROM catalog_page_returns
) AS combined
ORDER BY total_return_amount DESC
LIMIT 100
