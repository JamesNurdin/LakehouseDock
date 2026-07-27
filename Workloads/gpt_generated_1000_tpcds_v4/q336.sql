WITH filtered_calls AS (
    SELECT
        cc.cc_call_center_sk,
        cc.cc_city,
        cc.cc_manager,
        CONCAT(cc.cc_city, '-', cc.cc_manager) AS city_manager,
        regexp_extract(cc.cc_manager, '(\\w+) (\\w+)', 2) AS manager_last_name
    FROM tpcds.call_center AS cc
    WHERE cc.cc_country = 'United States'
      AND regexp_like(cc.cc_manager, '^R.*')               -- first name starts with R
      AND CONCAT(cc.cc_city, '-', cc.cc_manager) LIKE '%-R%'
)
SELECT
    fc.cc_city,
    fc.manager_last_name,
    COUNT(cr.cr_order_number) AS num_returns,
    SUM(cr.cr_return_amount) AS total_return_amount,
    AVG(cr.cr_fee) AS avg_fee,
    SUM(cr.cr_return_amount) / COUNT(cr.cr_order_number) AS avg_return_per_order
FROM filtered_calls AS fc
JOIN tpcds.catalog_returns AS cr
    ON cr.cr_call_center_sk = fc.cc_call_center_sk
WHERE cr.cr_return_amount > 0
  AND cr.cr_fee BETWEEN 20 AND 80
  AND cr.cr_reversed_charge IS NOT NULL
GROUP BY fc.cc_city, fc.manager_last_name
ORDER BY total_return_amount DESC
LIMIT 20
