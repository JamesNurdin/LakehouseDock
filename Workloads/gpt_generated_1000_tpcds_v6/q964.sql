WITH distinct_items AS (
    SELECT DISTINCT i.i_item_sk, i.i_category, i.i_brand
    FROM item i
    WHERE i.i_category_id IN (5, 8)
      AND i.i_current_price > 20.00
),
filtered_returns AS (
    SELECT
        wr.wr_returned_date_sk,
        wr.wr_item_sk,
        wr.wr_return_quantity,
        wr.wr_return_amt_inc_tax,
        wr.wr_return_tax,
        wr.wr_fee,
        wr.wr_net_loss
    FROM web_returns wr
    WHERE wr.wr_return_amt_inc_tax > 0
      AND wr.wr_return_quantity >= 1
)
SELECT
    d.d_year,
    d.d_day_name,
    di.i_category,
    di.i_brand,
    SUM(fr.wr_return_quantity) AS total_qty,
    SUM(fr.wr_return_amt_inc_tax) AS total_return_amount,
    AVG(fr.wr_return_amt_inc_tax) AS avg_return_amount,
    COUNT(DISTINCT fr.wr_return_quantity) AS distinct_qty_counts,
    MIN(fr.wr_return_amt_inc_tax) AS min_return_amount,
    MAX(fr.wr_return_amt_inc_tax) AS max_return_amount
FROM filtered_returns fr
JOIN date_dim d ON fr.wr_returned_date_sk = d.d_date_sk
JOIN distinct_items di ON fr.wr_item_sk = di.i_item_sk
WHERE d.d_year = 2001
  AND d.d_day_name = 'Saturday'
GROUP BY GROUPING SETS (
    (d.d_year, d.d_day_name, di.i_category, di.i_brand),
    (d.d_year, d.d_day_name, di.i_category),
    (d.d_year, d.d_day_name),
    (d.d_year),
    ()
)
ORDER BY d.d_year DESC, d.d_day_name, di.i_category
LIMIT 100
