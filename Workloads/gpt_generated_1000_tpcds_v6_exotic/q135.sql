WITH filtered_returns AS (
    SELECT
        cr_returned_date_sk,
        cr_return_quantity,
        cr_return_amount,
        cr_return_ship_cost,
        cr_returning_addr_sk,
        cr_catalog_page_sk,
        cr_item_sk
    FROM catalog_returns
    WHERE cr_return_quantity > 1
      AND cr_return_amount > 50
      AND cr_return_ship_cost BETWEEN 100 AND 2000
      AND cr_returning_addr_sk IN (2084286, 1012485)
      AND cr_catalog_page_sk = 256
      AND cr_returned_date_sk BETWEEN 2450000 AND 2455000
)
SELECT
    i.i_category,
    i.i_brand,
    i.i_manager_id,
    SUM(fr.cr_return_quantity) AS total_return_qty,
    AVG(fr.cr_return_amount) AS avg_return_amount,
    COUNT(*) AS return_rows,
    MIN(fr.cr_return_amount) AS min_return_amount,
    MAX(fr.cr_return_amount) AS max_return_amount,
    CASE
        WHEN AVG(fr.cr_return_amount) > (SELECT AVG(cr_return_amount) FROM catalog_returns) THEN 'Above Avg'
        ELSE 'Below Avg'
    END AS return_amount_category
FROM filtered_returns fr
JOIN item i
    ON fr.cr_item_sk = i.i_item_sk
WHERE i.i_rec_end_date > DATE '1999-12-31'
  AND i.i_manager_id IN (98, 41)
  AND i.i_formulation LIKE '%goldenrod%'
GROUP BY
    i.i_category,
    i.i_brand,
    i.i_manager_id
ORDER BY total_return_qty DESC
LIMIT 100
