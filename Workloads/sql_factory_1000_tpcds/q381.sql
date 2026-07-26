WITH item_returns AS (
    SELECT
        i.i_category,
        i.i_item_sk,
        i.i_product_name,
        SUM(sr.sr_return_amt) AS total_return_amt,
        SUM(sr.sr_return_quantity) AS total_return_qty,
        AVG(hd.hd_vehicle_count) AS avg_vehicle_count
    FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    GROUP BY i.i_category, i.i_item_sk, i.i_product_name
),
ranked_items AS (
    SELECT
        *,
        RANK() OVER (PARTITION BY i_category ORDER BY total_return_amt DESC) AS item_return_rank,
        total_return_amt / SUM(total_return_amt) OVER (PARTITION BY i_category) AS pct_of_category
    FROM item_returns
)
SELECT
    i_category,
    i_item_sk,
    i_product_name,
    total_return_amt,
    total_return_qty,
    avg_vehicle_count,
    pct_of_category,
    item_return_rank,
    CASE
        WHEN total_return_amt > 10000 THEN 'High'
        WHEN total_return_amt > 5000 THEN 'Medium'
        ELSE 'Low'
    END AS return_level
FROM ranked_items
WHERE item_return_rank <= 5
ORDER BY i_category, item_return_rank
