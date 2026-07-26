WITH sales_detail AS (
    SELECT
        cs.cs_sold_date_sk,
        ca.ca_state,
        i.i_category,
        cs.cs_net_profit
    FROM catalog_sales cs
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
),
rolling AS (
    SELECT
        cs_sold_date_sk,
        ca_state,
        i_category,
        SUM(cs_net_profit) OVER (PARTITION BY ca_state, i_category ORDER BY cs_sold_date_sk ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS rolling_3_profit,
        AVG(cs_net_profit) OVER (PARTITION BY ca_state, i_category ORDER BY cs_sold_date_sk ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS rolling_3_avg_profit
    FROM sales_detail
)
SELECT
    cs_sold_date_sk,
    ca_state,
    i_category,
    rolling_3_profit,
    rolling_3_avg_profit,
    CASE
        WHEN rolling_3_profit > 50000 THEN 'High'
        WHEN rolling_3_profit BETWEEN 20000 AND 50000 THEN 'Medium'
        ELSE 'Low'
    END AS profit_level
FROM rolling
ORDER BY ca_state, i_category, cs_sold_date_sk
LIMIT 100
