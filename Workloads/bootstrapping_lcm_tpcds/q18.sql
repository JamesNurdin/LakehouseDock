SELECT
    d.d_year,
    d.d_month_seq,
    i.i_category,
    CASE
        WHEN cr.cr_return_amt_inc_tax >= 1000 THEN '>=1000'
        WHEN cr.cr_return_amt_inc_tax >= 500 THEN '500-999'
        WHEN cr.cr_return_amt_inc_tax >= 100 THEN '100-499'
        ELSE '<100'
    END AS return_amount_bucket,
    COUNT(*) AS total_returns,
    SUM(cr.cr_return_amount) AS total_return_amount,
    AVG(inv.inv_quantity_on_hand) AS avg_inventory_qty_on_hand,
    COUNT(DISTINCT s.s_store_id) AS stores_closed_on_date,
    SUM(CASE WHEN s.s_tax_percentage > 0.07 THEN 1 ELSE 0 END) AS high_tax_store_cnt,
    SUM(CASE WHEN cr.cr_fee > 0 THEN cr.cr_fee ELSE 0 END) AS total_fee,
    MAX(cr.cr_return_quantity) AS max_return_qty
FROM catalog_returns cr
JOIN date_dim d
    ON cr.cr_returned_date_sk = d.d_date_sk
JOIN item i
    ON cr.cr_item_sk = i.i_item_sk
JOIN inventory inv
    ON inv.inv_date_sk = d.d_date_sk
   AND inv.inv_item_sk = i.i_item_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
WHERE d.d_year = 2002
  AND i.i_category IS NOT NULL
GROUP BY
    d.d_year,
    d.d_month_seq,
    i.i_category,
    CASE
        WHEN cr.cr_return_amt_inc_tax >= 1000 THEN '>=1000'
        WHEN cr.cr_return_amt_inc_tax >= 500 THEN '500-999'
        WHEN cr.cr_return_amt_inc_tax >= 100 THEN '100-499'
        ELSE '<100'
    END
HAVING COUNT(*) > 5
ORDER BY total_return_amount DESC
LIMIT 100
