/* goal: Compare item category profitability across catalog and web sales channels, excluding items that have any store returns, and show ranking, profit status, and average category profit */
WITH catalog_data AS (
    SELECT
        i.i_item_id,
        i.i_category,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(*) AS sales_cnt,
        CASE WHEN SUM(cs.cs_net_profit) >= 0 THEN 'Profitable' ELSE 'Loss' END AS profit_status,
        (
            SELECT AVG(cs2.cs_net_profit)
            FROM catalog_sales cs2
            JOIN item i2 ON cs2.cs_item_sk = i2.i_item_sk
            WHERE i2.i_category = i.i_category
        ) AS avg_category_profit,
        ROW_NUMBER() OVER (PARTITION BY i.i_category ORDER BY SUM(cs.cs_net_profit) DESC) AS profit_rank
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE NOT EXISTS (
            SELECT 1 FROM store_returns sr WHERE sr.sr_item_sk = i.i_item_sk
        )
        AND i.i_category IN ('Men', 'Jewelry', 'Women')
        AND cs.cs_bill_customer_sk IN (
            SELECT c.c_customer_sk FROM customer c WHERE c.c_preferred_cust_flag = 'Y'
        )
    GROUP BY i.i_item_id, i.i_category
),
web_data AS (
    SELECT
        i.i_item_id,
        i.i_category,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(*) AS sales_cnt,
        CASE WHEN SUM(ws.ws_net_profit) >= 0 THEN 'Profitable' ELSE 'Loss' END AS profit_status,
        (
            SELECT AVG(ws2.ws_net_profit)
            FROM web_sales ws2
            JOIN item i2 ON ws2.ws_item_sk = i2.i_item_sk
            WHERE i2.i_category = i.i_category
        ) AS avg_category_profit,
        ROW_NUMBER() OVER (PARTITION BY i.i_category ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE NOT EXISTS (
            SELECT 1 FROM store_returns sr WHERE sr.sr_item_sk = i.i_item_sk
        )
        AND i.i_category IN ('Men', 'Jewelry', 'Women')
        AND ws.ws_bill_customer_sk IN (
            SELECT c.c_customer_sk FROM customer c WHERE c.c_preferred_cust_flag = 'Y'
        )
    GROUP BY i.i_item_id, i.i_category
)
SELECT
    i_item_id,
    i_category,
    total_profit,
    sales_cnt,
    profit_status,
    avg_category_profit,
    profit_rank
FROM catalog_data
UNION ALL
SELECT
    i_item_id,
    i_category,
    total_profit,
    sales_cnt,
    profit_status,
    avg_category_profit,
    profit_rank
FROM web_data
ORDER BY total_profit DESC
LIMIT 100
