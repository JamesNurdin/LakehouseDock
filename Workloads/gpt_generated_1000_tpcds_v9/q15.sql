WITH max_sales AS (
    SELECT MAX(cs_ext_sales_price) AS max_price
    FROM catalog_sales
)
SELECT
    cp.cp_type AS catalog_type,
    CASE WHEN cs.cs_ext_sales_price = max_sales.max_price THEN 'Max' ELSE 'Other' END AS price_flag,
    COUNT(DISTINCT cs.cs_item_sk) AS distinct_item_count,
    SUM(DISTINCT cs.cs_ext_sales_price) AS distinct_sales_sum,
    AVG(cs.cs_net_profit) AS avg_net_profit
FROM catalog_sales cs
JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
CROSS JOIN max_sales
WHERE cp.cp_type = 'monthly'
  AND cs.cs_warehouse_sk IN (
        SELECT DISTINCT cs2.cs_warehouse_sk
        FROM catalog_sales cs2
        WHERE cs2.cs_quantity > 5
    )
GROUP BY
    cp.cp_type,
    CASE WHEN cs.cs_ext_sales_price = max_sales.max_price THEN 'Max' ELSE 'Other' END
UNION ALL
SELECT
    cp.cp_type AS catalog_type,
    CASE WHEN cs.cs_ext_sales_price = max_sales.max_price THEN 'Max' ELSE 'Other' END AS price_flag,
    COUNT(DISTINCT cs.cs_item_sk) AS distinct_item_count,
    SUM(DISTINCT cs.cs_ext_sales_price) AS distinct_sales_sum,
    AVG(cs.cs_net_profit) AS avg_net_profit
FROM catalog_sales cs
JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
CROSS JOIN max_sales
WHERE cp.cp_type = 'quarterly'
  AND EXISTS (
        SELECT 1
        FROM catalog_sales cs3
        WHERE cs3.cs_ship_addr_sk = cs.cs_ship_addr_sk
          AND cs3.cs_ext_discount_amt > 0
    )
GROUP BY
    cp.cp_type,
    CASE WHEN cs.cs_ext_sales_price = max_sales.max_price THEN 'Max' ELSE 'Other' END
ORDER BY catalog_type, distinct_item_count DESC
LIMIT 100
