SELECT
    cs.cs_warehouse_sk AS warehouse_sk,
    SUM(cs.cs_net_paid_inc_ship) AS total_sales,
    SUM(cr.cr_return_amount) AS total_return_amount,
    COUNT(DISTINCT cs.cs_order_number) AS order_count
FROM
    catalog_returns cr
JOIN
    catalog_sales cs
ON
    cr.cr_item_sk = cs.cs_item_sk
    AND cr.cr_order_number = cs.cs_order_number
WHERE
    cs.cs_net_paid_inc_ship > 5000
    AND cr.cr_return_quantity > 20
GROUP BY
    cs.cs_warehouse_sk
ORDER BY
    total_sales DESC
LIMIT 100
