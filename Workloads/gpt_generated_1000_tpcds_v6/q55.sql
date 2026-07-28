WITH returns_detail AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_catalog_page_sk,
        cr.cr_item_sk,
        cr.cr_warehouse_sk,
        i.i_item_id,
        i.i_category,
        i.i_formulation,
        i.i_size,
        cp.cp_catalog_page_id,
        cp.cp_description,
        w.w_warehouse_id,
        w.w_country
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE w.w_country = 'United States'
)

SELECT
    rd.cp_catalog_page_id AS catalog_page_id,
    rd.i_category AS item_category,
    SUM(rd.cr_return_amount) AS total_return_amount,
    COUNT(*) AS return_cnt,
    (SELECT AVG(cr2.cr_return_amount)
     FROM catalog_returns cr2
     WHERE cr2.cr_item_sk = rd.cr_item_sk) AS avg_item_return_amount
FROM returns_detail rd
WHERE rd.i_formulation LIKE '%thistle%'
  AND EXISTS (
        SELECT 1
        FROM catalog_returns cr3
        WHERE cr3.cr_catalog_page_sk = rd.cr_catalog_page_sk
          AND cr3.cr_return_quantity > 5
      )
GROUP BY rd.cp_catalog_page_id, rd.i_category, rd.cr_item_sk
HAVING SUM(rd.cr_return_amount) > 1000

UNION ALL

SELECT
    rd.cp_catalog_page_id,
    rd.i_category,
    SUM(rd.cr_return_amount),
    COUNT(*),
    (SELECT AVG(cr2.cr_return_amount)
     FROM catalog_returns cr2
     WHERE cr2.cr_item_sk = rd.cr_item_sk)
FROM returns_detail rd
WHERE rd.i_formulation LIKE '%papaya%'
  AND EXISTS (
        SELECT 1
        FROM catalog_returns cr3
        WHERE cr3.cr_catalog_page_sk = rd.cr_catalog_page_sk
          AND cr3.cr_return_quantity > 5
      )
GROUP BY rd.cp_catalog_page_id, rd.i_category, rd.cr_item_sk
HAVING SUM(rd.cr_return_amount) > 1000

ORDER BY total_return_amount DESC
