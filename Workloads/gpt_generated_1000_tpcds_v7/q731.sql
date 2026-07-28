WITH returns_agg AS (
    SELECT
        wr_item_sk,
        SUM(wr_return_quantity) AS total_ret_qty,
        SUM(wr_return_amt) AS total_ret_amt,
        AVG(wr_return_amt) AS avg_ret_amt
    FROM web_returns
    WHERE wr_return_ship_cost > 20
    GROUP BY wr_item_sk
)
SELECT
    i.i_item_id,
    i.i_category,
    i.i_size,
    inv.inv_quantity_on_hand,
    r.total_ret_qty,
    r.total_ret_amt,
    r.avg_ret_amt,
    RANK() OVER (PARTITION BY i.i_category ORDER BY r.total_ret_amt DESC) AS category_ret_amt_rank,
    CASE
        WHEN r.total_ret_amt > (SELECT AVG(total_ret_amt) FROM returns_agg) THEN 'High'
        ELSE 'Low'
    END AS high_low_flag
FROM inventory inv
JOIN item i
    ON inv.inv_item_sk = i.i_item_sk
JOIN returns_agg r
    ON i.i_item_sk = r.wr_item_sk
WHERE inv.inv_quantity_on_hand > 200
  AND i.i_category_id IN (4, 5, 6)
  AND i.i_size <> 'N/A'
ORDER BY i.i_category, category_ret_amt_rank
LIMIT 100
