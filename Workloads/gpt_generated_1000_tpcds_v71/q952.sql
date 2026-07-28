WITH first_set AS (
    SELECT
        cp.cp_catalog_page_id AS catalog_page_id,
        cp.cp_catalog_number AS catalog_number,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_net_loss,
        CASE WHEN SUM(cr.cr_net_loss) > 1000 THEN 'High' ELSE 'Low' END AS loss_category,
        (SELECT AVG(cr2.cr_return_amount)
         FROM catalog_returns cr2
         WHERE cr2.cr_catalog_page_sk = cp.cp_catalog_page_sk) AS avg_return_amount
    FROM catalog_page cp
    JOIN catalog_returns cr
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE cp.cp_start_date_sk BETWEEN 2450875 AND 2451085
      AND cp.cp_catalog_number IN (9, 16)
      AND cr.cr_return_amount > 20
      AND EXISTS (
          SELECT 1
          FROM catalog_returns cr3
          WHERE cr3.cr_catalog_page_sk = cp.cp_catalog_page_sk
            AND cr3.cr_return_quantity > 1
      )
    GROUP BY cp.cp_catalog_page_id, cp.cp_catalog_number, cp.cp_catalog_page_sk
),
second_set AS (
    SELECT
        cp.cp_catalog_page_id AS catalog_page_id,
        cp.cp_catalog_number AS catalog_number,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_net_loss,
        CASE WHEN SUM(cr.cr_net_loss) > 500 THEN 'Medium' ELSE 'Low' END AS loss_category,
        (SELECT AVG(cr2.cr_return_amount)
         FROM catalog_returns cr2
         WHERE cr2.cr_catalog_page_sk = cp.cp_catalog_page_sk) AS avg_return_amount
    FROM catalog_page cp
    JOIN catalog_returns cr
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE cp.cp_end_date_sk BETWEEN 2451144 AND 2451452
      AND cp.cp_department = 'Electronics'
      AND cr.cr_return_amount BETWEEN 10 AND 30
      AND cr.cr_store_credit > 20
    GROUP BY cp.cp_catalog_page_id, cp.cp_catalog_number, cp.cp_catalog_page_sk
)
SELECT
    catalog_page_id,
    catalog_number,
    total_return_amount,
    total_net_loss,
    loss_category,
    avg_return_amount
FROM first_set
UNION ALL
SELECT
    catalog_page_id,
    catalog_number,
    total_return_amount,
    total_net_loss,
    loss_category,
    avg_return_amount
FROM second_set
ORDER BY total_return_amount DESC
LIMIT 100
