SELECT
    cc.cc_call_center_id,
    cc.cc_name,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_return_quantity) AS total_quantity
FROM
    tpcds.catalog_returns AS cr
JOIN
    tpcds.call_center AS cc
      ON cr.cr_call_center_sk = cc.cc_call_center_sk
WHERE
    cc.cc_division = 1
    AND cr.cr_return_ship_cost > 300
GROUP BY
    cc.cc_call_center_id,
    cc.cc_name
ORDER BY
    total_return_amount DESC
LIMIT 100
