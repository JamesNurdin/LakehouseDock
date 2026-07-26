WITH sales_customer AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_item_sk,
        SUM(ss.ss_quantity) AS total_qty,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        AVG(c.c_birth_year) AS avg_birth_year
    FROM store_sales ss
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    GROUP BY ss.ss_store_sk, ss.ss_item_sk
),
ranked_items AS (
    SELECT
        ss_store_sk,
        ss_item_sk,
        total_qty,
        total_sales,
        total_profit,
        avg_birth_year,
        CASE
            WHEN total_sales = 0 THEN 0
            ELSE total_profit / total_sales
        END AS profit_margin,
        CASE
            WHEN total_sales = 0 THEN 'No Sales'
            WHEN (total_profit / total_sales) > 0.2 THEN 'High'
            WHEN (total_profit / total_sales) > 0.1 THEN 'Medium'
            ELSE 'Low'
        END AS profit_category,
        ROW_NUMBER() OVER (PARTITION BY ss_store_sk ORDER BY total_qty DESC) AS item_rank
    FROM sales_customer
)
SELECT
    ss_store_sk AS store_sk,
    ss_item_sk AS item_sk,
    total_qty,
    total_sales,
    total_profit,
    profit_margin,
    profit_category,
    item_rank,
    avg_birth_year
FROM ranked_items
WHERE item_rank <= 5
ORDER BY store_sk, item_rank
