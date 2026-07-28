WITH item_returns AS (
        SELECT
            i.i_item_sk,
            i.i_brand,
            i.i_category,
            SUM(sr.sr_return_amt_inc_tax) AS total_return_amt,
            AVG(sr.sr_return_amt_inc_tax) AS avg_return_amt
        FROM store_returns sr
        JOIN item i ON sr.sr_item_sk = i.i_item_sk
        WHERE sr.sr_return_amt_inc_tax > 50
        GROUP BY i.i_item_sk, i.i_brand, i.i_category
    )
SELECT
    s.s_store_id,
    s.s_state,
    w.w_warehouse_name,
    i.i_item_id,
    i.i_brand,
    inv.inv_quantity_on_hand,
    sr.sr_return_amt_inc_tax,
    ir.total_return_amt,
    RANK() OVER (PARTITION BY s.s_state ORDER BY ir.total_return_amt DESC) AS state_return_rank,
    CASE
        WHEN inv.inv_quantity_on_hand < 10 THEN 'Low Stock'
        WHEN inv.inv_quantity_on_hand BETWEEN 10 AND 100 THEN 'Medium Stock'
        ELSE 'High Stock'
    END AS stock_category
FROM store_returns sr
JOIN item i ON sr.sr_item_sk = i.i_item_sk
JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
JOIN store s ON sr.sr_store_sk = s.s_store_sk
JOIN item_returns ir ON ir.i_item_sk = i.i_item_sk
WHERE s.s_state = 'CA'
  AND s.s_rec_start_date <= DATE '2000-03-13'
  AND w.w_gmt_offset BETWEEN -5.0 AND -3.0
ORDER BY state_return_rank, sr.sr_return_amt_inc_tax DESC
LIMIT 100
