SELECT
    cc.cc_name,
    cc.cc_manager,
    SUM(cs.cs_ext_list_price) AS total_ext_list_price,
    SUM(cs.cs_net_paid_inc_ship) AS total_net_paid_inc_ship
FROM
    catalog_sales cs
JOIN
    call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
WHERE
    cc.cc_manager = 'Bob Belcher'
    AND cs.cs_ext_list_price > 15000
GROUP BY
    cc.cc_name,
    cc.cc_manager
ORDER BY
    total_ext_list_price DESC
LIMIT 100
