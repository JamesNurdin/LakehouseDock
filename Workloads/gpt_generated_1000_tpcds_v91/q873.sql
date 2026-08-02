WITH avg_return AS (
    SELECT AVG(cr_return_amount) AS overall_avg_return
    FROM catalog_returns
    WHERE cr_returned_date_sk BETWEEN 2450900 AND 2451500
)
SELECT
    cp.cp_department,
    i.i_manufact,
    w.w_warehouse_name,
    SUM(COALESCE(cr.cr_return_amount, 0)) AS total_return_amount,
    AVG(COALESCE(cr.cr_return_amount, 0)) AS avg_return_amount,
    COUNT(*) AS return_count,
    MAX(COALESCE(cr.cr_return_amount, 0)) AS max_return_amount,
    MIN(COALESCE(cr.cr_return_amount, 0)) AS min_return_amount,
    COUNT(DISTINCT cr.cr_refunded_customer_sk) AS distinct_refunded_customers,
    AVG(cd_refunded.cd_dep_college_count) AS avg_dep_college_count,
    (SELECT COUNT(DISTINCT cd2.cd_demo_sk)
       FROM customer_demographics cd2
       WHERE cd2.cd_marital_status = 'M') AS married_demo_count
FROM catalog_returns cr
FULL OUTER JOIN item i
    ON cr.cr_item_sk = i.i_item_sk
LEFT JOIN catalog_page cp
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
LEFT JOIN warehouse w
    ON cr.cr_warehouse_sk = w.w_warehouse_sk
LEFT JOIN customer_address ca_refunded
    ON cr.cr_refunded_addr_sk = ca_refunded.ca_address_sk
LEFT JOIN customer_demographics cd_refunded
    ON cr.cr_refunded_cdemo_sk = cd_refunded.cd_demo_sk
WHERE
    (cr.cr_return_amount > (SELECT overall_avg_return FROM avg_return) OR cr.cr_return_amount IS NULL)
    AND i.i_manufact = 'antin stn st'
    AND i.i_manufact IN (
        SELECT DISTINCT i2.i_manufact
        FROM item i2
        WHERE i2.i_current_price > 20
    )
    AND cd_refunded.cd_marital_status = 'M'
    AND cd_refunded.cd_dep_college_count >= 2
    AND cp.cp_description LIKE '%economic%'
    AND w.w_state = 'CA'
    AND NOT EXISTS (
        SELECT 1
        FROM catalog_returns cr2
        JOIN customer_demographics cd2
            ON cr2.cr_refunded_cdemo_sk = cd2.cd_demo_sk
        WHERE cd2.cd_marital_status = 'S'
          AND cr2.cr_item_sk = cr.cr_item_sk
          AND cr2.cr_returned_date_sk = cr.cr_returned_date_sk
          AND cr2.cr_return_amount > 0
    )
GROUP BY
    cp.cp_department,
    i.i_manufact,
    w.w_warehouse_name
HAVING
    SUM(COALESCE(cr.cr_return_amount, 0)) > 1000
ORDER BY
    total_return_amount DESC
LIMIT 100
