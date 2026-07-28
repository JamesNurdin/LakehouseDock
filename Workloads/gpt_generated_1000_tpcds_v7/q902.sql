WITH item_returns AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        i.i_brand,
        i.i_category,
        i.i_units,
        SUM(wr.wr_return_amt) AS total_return_amt,
        SUM(wr.wr_return_quantity) AS total_return_qty
    FROM web_returns wr
    JOIN item i
        ON wr.wr_item_sk = i.i_item_sk
    WHERE i.i_units = 'Cup'
      AND i.i_current_price > 10
      AND i.i_brand_id IN (117, 260)
      AND wr.wr_return_quantity > 0
      AND wr.wr_return_amt > 0
    GROUP BY i.i_item_sk, i.i_item_id, i.i_brand, i.i_category, i.i_units
)
SELECT
    ir.i_item_id,
    ir.i_brand,
    ir.i_category,
    ir.i_units,
    ir.total_return_amt,
    ir.total_return_qty,
    ROW_NUMBER() OVER (PARTITION BY ir.i_brand ORDER BY ir.total_return_amt DESC) AS brand_item_rank,
    CASE WHEN ir.total_return_amt > 1000 THEN 'High' ELSE 'Low' END AS return_level
FROM item_returns ir
ORDER BY ir.i_brand, brand_item_rank
LIMIT 100
