-- goal: Combine store and catalog sales, classify profit/loss, aggregate by year, category and profit flag with subtotals
WITH store_data AS (
    SELECT
        d.d_year AS year,
        i.i_category AS category,
        CASE WHEN ss.ss_net_profit > 0 THEN 'Profit' ELSE 'Loss' END AS profit_flag,
        ss.ss_net_paid AS net_paid,
        ss.ss_net_profit AS net_profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE d.d_year = 2001
      AND s.s_state = 'CA'
),
catalog_data AS (
    SELECT
        d.d_year AS year,
        i.i_category AS category,
        CASE WHEN cs.cs_net_profit > 0 THEN 'Profit' ELSE 'Loss' END AS profit_flag,
        cs.cs_net_paid AS net_paid,
        cs.cs_net_profit AS net_profit
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
      AND cs.cs_quantity > 0
)
SELECT
    year,
    category,
    profit_flag,
    SUM(net_paid) AS total_net_paid,
    SUM(net_profit) AS total_net_profit
FROM (
    SELECT * FROM store_data
    UNION ALL
    SELECT * FROM catalog_data
) combined
GROUP BY GROUPING SETS (
    (year, category, profit_flag),
    (year, category),
    (year),
    ()
)
ORDER BY year DESC, category, profit_flag
LIMIT 100
