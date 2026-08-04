WITH inv_agg AS (
    SELECT
        inv_item_sk,
        inv_date_sk,
        SUM(inv_quantity_on_hand) AS total_qty
    FROM inventory
    TABLESAMPLE BERNOULLI (10)
    GROUP BY inv_item_sk, inv_date_sk
)
SELECT
    d_ret.d_year,
    i_wr.i_category,
    i_wr.i_size,
    r.r_reason_desc,
    SUM(wr.wr_return_amt) AS total_return_amt,
    SUM(ia1.total_qty) AS total_inventory_qty,
    AVG(wr.wr_net_loss) AS avg_net_loss
FROM web_returns wr
TABLESAMPLE BERNOULLI (5)
JOIN date_dim d_ret
    ON wr.wr_returned_date_sk = d_ret.d_date_sk
JOIN time_dim t
    ON wr.wr_returned_time_sk = t.t_time_sk
JOIN item i_wr
    ON wr.wr_item_sk = i_wr.i_item_sk
JOIN reason r
    ON wr.wr_reason_sk = r.r_reason_sk
JOIN inv_agg ia1
    ON wr.wr_item_sk = ia1.inv_item_sk
   AND wr.wr_returned_date_sk = ia1.inv_date_sk
JOIN date_dim d_inv
    ON ia1.inv_date_sk = d_inv.d_date_sk
JOIN item i_inv
    ON ia1.inv_item_sk = i_inv.i_item_sk
JOIN inventory inv_raw
    ON inv_raw.inv_item_sk = i_wr.i_item_sk
   AND inv_raw.inv_date_sk = d_ret.d_date_sk
JOIN inventory inv_raw2
    ON inv_raw2.inv_item_sk = i_wr.i_item_sk
   AND inv_raw2.inv_date_sk = d_ret.d_date_sk
WHERE t.t_meal_time = 'dinner'
  AND i_wr.i_size IN ('medium', 'large')
  AND wr.wr_return_amt > (SELECT AVG(wr_return_amt) FROM web_returns)
GROUP BY d_ret.d_year,
         i_wr.i_category,
         i_wr.i_size,
         r.r_reason_desc
ORDER BY total_return_amt DESC
LIMIT 100
