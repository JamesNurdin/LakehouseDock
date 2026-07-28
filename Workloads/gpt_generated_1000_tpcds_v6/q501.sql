WITH warehouse_sales AS (
    SELECT
        w.w_warehouse_sk,
        w.w_warehouse_name AS w_name,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit
    FROM catalog_sales cs
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE cs.cs_quantity > 1
      AND cs.cs_list_price BETWEEN 10 AND 300
    GROUP BY w.w_warehouse_sk, w.w_warehouse_name
)
SELECT
    w_name,
    total_sales,
    total_profit,
    CASE WHEN total_profit >= 1000 THEN 'High' ELSE 'Low' END AS profit_category
FROM warehouse_sales
WHERE total_sales > 5000
UNION ALL
SELECT
    w_name,
    total_sales,
    total_profit,
    CASE WHEN total_profit >= 1000 THEN 'High' ELSE 'Low' END AS profit_category
FROM warehouse_sales
WHERE total_sales <= 5000
ORDER BY total_profit DESC
LIMIT 100
