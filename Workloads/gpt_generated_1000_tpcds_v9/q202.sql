SELECT
    cp.cp_catalog_page_id,
    cp.cp_catalog_page_number,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    SUM(cs.cs_quantity) AS total_quantity,
    SUM(cs.cs_net_profit) AS total_profit
FROM
    catalog_sales cs
JOIN
    catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
WHERE
    cs.cs_ext_wholesale_cost > 2000
    AND cp.cp_catalog_page_number IN (6, 12, 19)
GROUP BY
    cp.cp_catalog_page_id,
    cp.cp_catalog_page_number
ORDER BY
    total_sales DESC
LIMIT 100
