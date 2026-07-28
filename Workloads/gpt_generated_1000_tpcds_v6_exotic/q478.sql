WITH category_returns AS (
    SELECT
        i.i_category AS category,
        SUM(cr.cr_return_amount) AS total_return_amount,
        COUNT(*) AS return_cnt
    FROM catalog_returns cr
    JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
    GROUP BY i.i_category
)

SELECT DISTINCT
    cr1.category,
    cr1.total_return_amount,
    (SELECT MAX(total_return_amount) FROM category_returns) AS max_total_return_amount
FROM category_returns cr1
WHERE cr1.total_return_amount > 5000

UNION ALL

SELECT
    i.i_category,
    cr_agg.total_return_amount,
    NULL AS max_total_return_amount
FROM catalog_returns cr
JOIN item i
    ON cr.cr_item_sk = i.i_item_sk
JOIN customer_address ca
    ON cr.cr_returning_addr_sk = ca.ca_address_sk
JOIN (
    SELECT cr2.cr_item_sk, SUM(cr2.cr_return_amount) AS total_return_amount
    FROM catalog_returns cr2
    GROUP BY cr2.cr_item_sk
) cr_agg
    ON cr.cr_item_sk = cr_agg.cr_item_sk
WHERE ca.ca_city = 'Edgewood'
  AND EXISTS (
        SELECT 1
        FROM customer_address ca2
        WHERE ca2.ca_address_sk = cr.cr_returning_addr_sk
          AND ca2.ca_zip = '39431'
    )
GROUP BY i.i_category, cr_agg.total_return_amount
HAVING COUNT(*) > 1000
ORDER BY 1, 2 DESC
