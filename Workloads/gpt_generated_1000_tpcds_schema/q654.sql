WITH
    agg_returns AS (
        SELECT
            cr_catalog_page_sk,
            cr_warehouse_sk,
            SUM(cr_return_amount) AS total_return_amount,
            SUM(cr_return_quantity) AS total_return_quantity,
            COUNT(*) AS cnt_returns,
            MAX(cr_return_amount) AS max_return_amount
        FROM catalog_returns
        WHERE cr_returned_date_sk BETWEEN 2450900 AND 2451200
          AND cr_return_quantity > 1
          AND cr_return_amount > 0
          AND cr_fee < 50
        GROUP BY cr_catalog_page_sk, cr_warehouse_sk
    ),
    intersect_pages AS (
        SELECT cp_catalog_page_sk FROM catalog_page
        WHERE cp_department = 'Electronics'
          AND cp_catalog_page_number BETWEEN 5 AND 10
        INTERSECT
        SELECT cr_catalog_page_sk FROM catalog_returns
        WHERE cr_return_amount > 100
    )
SELECT
    w.w_warehouse_name,
    w.w_city,
    CASE WHEN w.w_city = 'San Jose' THEN 'SJ' ELSE 'Other' END AS city_group,
    cp.cp_department,
    COUNT(DISTINCT cp.cp_catalog_page_sk) AS num_pages,
    SUM(ar.total_return_amount) AS sum_return_amount,
    AVG(ar.total_return_quantity) AS avg_return_quantity,
    MAX(ar.max_return_amount) AS max_return_amount,
    (SELECT AVG(cr_return_amount) FROM catalog_returns) AS overall_avg_return_amount,
    CASE WHEN SUM(ar.total_return_amount) > (SELECT AVG(cr_return_amount) FROM catalog_returns) * 10 THEN 'HIGH' ELSE 'NORMAL' END AS amount_category
FROM catalog_page cp
FULL OUTER JOIN agg_returns ar
    ON cp.cp_catalog_page_sk = ar.cr_catalog_page_sk
LEFT JOIN warehouse w
    ON ar.cr_warehouse_sk = w.w_warehouse_sk
WHERE cp.cp_catalog_page_sk IN (SELECT cp_catalog_page_sk FROM intersect_pages)
  AND w.w_state = 'CA'
  AND w.w_zip LIKE '78%'
  AND cp.cp_type = 'NORMAL'
GROUP BY
    w.w_warehouse_name,
    w.w_city,
    CASE WHEN w.w_city = 'San Jose' THEN 'SJ' ELSE 'Other' END,
    cp.cp_department
ORDER BY sum_return_amount DESC
LIMIT 100
