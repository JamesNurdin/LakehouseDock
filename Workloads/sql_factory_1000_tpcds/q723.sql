WITH store_category_sales AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        i.i_category,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_ext_wholesale_cost) AS total_cost,
        SUM(ss.ss_ext_sales_price) - SUM(ss.ss_ext_wholesale_cost) AS total_profit
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    GROUP BY s.s_store_sk, s.s_store_name, i.i_category
)
SELECT
    s_store_name,
    i_category,
    total_transactions,
    total_sales,
    total_cost,
    total_profit,
    CASE
        WHEN total_sales = 0 THEN 0
        ELSE total_profit / total_sales
    END AS profit_margin,
    DENSE_RANK() OVER (PARTITION BY s_store_sk ORDER BY total_profit DESC) AS profit_rank,
    CASE
        WHEN total_profit / total_sales > 0.2 THEN 'High Margin'
        WHEN total_profit / total_sales > 0.1 THEN 'Medium Margin'
        ELSE 'Low Margin'
    END AS margin_category
FROM store_category_sales
ORDER BY s_store_name, profit_rank
LIMIT 20
