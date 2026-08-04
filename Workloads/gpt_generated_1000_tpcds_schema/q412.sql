WITH sales_sample AS (
    SELECT
        ss_sold_date_sk,
        ss_sold_time_sk,
        ss_item_sk,
        ss_quantity,
        ss_ext_sales_price,
        ss_net_profit
    FROM store_sales
    TABLESAMPLE BERNOULLI (5)   -- sample 5 percent of rows
),

intersect_items AS (
    SELECT ss_item_sk FROM sales_sample WHERE ss_quantity >= 5
    INTERSECT
    SELECT ss_item_sk FROM sales_sample WHERE ss_ext_sales_price > 200
),

filtered_sales AS (
    SELECT
        ss_sold_date_sk,
        ss_sold_time_sk,
        ss_item_sk,
        ss_quantity,
        ss_ext_sales_price,
        ss_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ss_sold_time_sk ORDER BY ss_ext_sales_price DESC) AS rn,
        CASE
            WHEN ss_net_profit > 300 THEN 'HIGH'
            WHEN ss_net_profit BETWEEN 100 AND 300 THEN 'MEDIUM'
            ELSE 'LOW'
        END AS profit_category
    FROM sales_sample
    WHERE ss_quantity > 0
      AND ss_ext_sales_price BETWEEN 50 AND 1000
      AND ss_net_profit > 0
      AND ss_item_sk NOT IN (SELECT ss_item_sk FROM store_sales WHERE ss_quantity = 0)  -- anti‑semi‑join
      AND ss_item_sk IN (SELECT ss_item_sk FROM intersect_items)                -- intersect filter
)
SELECT
    f.ss_sold_date_sk,
    f.ss_sold_time_sk,
    f.ss_item_sk,
    f.ss_quantity,
    f.ss_ext_sales_price,
    f.ss_net_profit,
    f.rn,
    f.profit_category,
    t.t_hour,
    t.t_time_id
FROM filtered_sales f
JOIN time_dim t
    ON f.ss_sold_time_sk = t.t_time_sk
WHERE
    t.t_hour IN (8, 12, 19)                           -- predicate 1
    AND t.t_time_id LIKE 'AAAAAAA%'                  -- predicate 2
    AND t.t_minute >= 0                              -- predicate 3
    AND t.t_second <= 15                             -- predicate 4
    AND f.rn <= 5                                    -- predicate 5
    AND f.profit_category <> 'LOW'                   -- predicate 6
ORDER BY f.rn ASC, f.ss_sold_date_sk DESC
OFFSET 10 LIMIT 10
