WITH sampled_inventory AS (
    SELECT inv_item_sk, inv_warehouse_sk, inv_quantity_on_hand
    FROM inventory TABLESAMPLE BERNOULLI (10)
),
union_data AS (
    SELECT cs.cs_item_sk AS item_sk,
           SUM(cs.cs_net_profit) AS profit,
           COUNT(*) AS tx_count
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY cs.cs_item_sk
    UNION
    SELECT cr.cr_item_sk AS item_sk,
           -SUM(cr.cr_net_loss) AS profit,
           COUNT(*) AS tx_count
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY cr.cr_item_sk
),
agg_union AS (
    SELECT item_sk,
           SUM(profit) AS total_profit,
           SUM(tx_count) AS total_tx
    FROM union_data
    GROUP BY item_sk
),
filtered AS (
    SELECT a.item_sk,
           a.total_profit,
           a.total_tx,
           CASE
               WHEN a.total_profit > 5000 THEN 'High'
               WHEN a.total_profit > 0 THEN 'Medium'
               ELSE 'Low'
           END AS profit_category
    FROM agg_union a
    WHERE EXISTS (
        SELECT 1
        FROM sampled_inventory si
        WHERE si.inv_item_sk = a.item_sk
    )
),
low_profit_items AS (
    SELECT item_sk FROM filtered WHERE total_profit < 0
),
final_items AS (
    SELECT item_sk FROM filtered
    EXCEPT
    SELECT item_sk FROM low_profit_items
)
SELECT DISTINCT
       f.item_sk,
       i.i_item_id,
       f.total_profit,
       f.total_tx,
       f.profit_category,
       (SELECT MAX(i2.i_current_price) FROM item i2 WHERE i2.i_item_sk = f.item_sk) AS max_price,
       SUM(f.total_profit) OVER (
           PARTITION BY f.profit_category
           ORDER BY f.total_profit DESC
           ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
       ) AS running_profit
FROM filtered f
JOIN final_items fi ON f.item_sk = fi.item_sk
JOIN item i ON f.item_sk = i.i_item_sk
ORDER BY f.total_profit DESC
LIMIT 100
