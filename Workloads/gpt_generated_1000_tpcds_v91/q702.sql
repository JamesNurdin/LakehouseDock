WITH sales_a AS (
    SELECT
        i_category AS category,
        i_class    AS class,
        SUM(cs_quantity)      AS total_quantity,
        AVG(cs_sales_price)   AS avg_price,
        SUM(cs_net_profit)    AS total_profit
    FROM catalog_sales
    JOIN item ON catalog_sales.cs_item_sk = item.i_item_sk
    WHERE cs_ship_date_sk BETWEEN 2450850 AND 2450870
      AND i_manager_id = 11
    GROUP BY i_category, i_class
    HAVING SUM(cs_net_profit) > 1000
),
sales_b AS (
    SELECT
        i_category AS category,
        i_class    AS class,
        SUM(cs_quantity)      AS total_quantity,
        AVG(cs_sales_price)   AS avg_price,
        SUM(cs_net_profit)    AS total_profit
    FROM catalog_sales
    JOIN item ON catalog_sales.cs_item_sk = item.i_item_sk
    WHERE cs_ship_date_sk BETWEEN 2450871 AND 2450895
      AND i_manager_id = 34
    GROUP BY i_category, i_class
    HAVING SUM(cs_net_profit) > 1000
)
SELECT category, class, total_quantity, avg_price, total_profit
FROM sales_a
UNION
SELECT category, class, total_quantity, avg_price, total_profit
FROM sales_b
ORDER BY total_profit DESC
LIMIT 100
