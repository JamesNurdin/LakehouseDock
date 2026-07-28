SELECT DISTINCT
    cc.cc_name,
    cr.cr_return_amount
FROM
    catalog_returns cr
JOIN
    call_center cc
ON
    cr.cr_call_center_sk = cc.cc_call_center_sk
WHERE
    cc.cc_division = 4
    AND cr.cr_return_ship_cost > 1000.00
