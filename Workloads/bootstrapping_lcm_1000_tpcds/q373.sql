SELECT
    d.d_year,
    d.d_quarter_name,
    i.i_category,
    i.i_brand,
    w.w_warehouse_name,
    s.s_store_name,
    COUNT(*) AS returns_cnt,
    SUM(cr.cr_return_quantity) AS total_return_qty,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_net_loss) AS total_net_loss,
    AVG(cr.cr_return_amount) AS avg_return_amount,
    MIN(cr.cr_return_amount) AS min_return_amount,
    MAX(cr.cr_return_amount) AS max_return_amount,
    SUM(cr.cr_fee) AS total_fee,
    SUM(cr.cr_return_tax) AS total_return_tax,
    CASE WHEN SUM(cr.cr_net_loss) > 0 THEN 'LOSS' ELSE 'NO LOSS' END AS loss_indicator
FROM catalog_returns cr
JOIN date_dim d
    ON cr.cr_returned_date_sk = d.d_date_sk
JOIN item i
    ON cr.cr_item_sk = i.i_item_sk
JOIN warehouse w
    ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 2000 AND 2005
  AND i.i_category = 'Electronics'
  AND w.w_state = 'CA'
GROUP BY
    d.d_year,
    d.d_quarter_name,
    i.i_category,
    i.i_brand,
    w.w_warehouse_name,
    s.s_store_name
HAVING SUM(cr.cr_return_amount) > 1000
ORDER BY total_net_loss DESC
LIMIT 100
