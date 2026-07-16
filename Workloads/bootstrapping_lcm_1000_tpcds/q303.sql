SELECT
    d.d_year,
    d.d_month_seq,
    i_cat.i_category,
    s.s_state,
    COUNT(DISTINCT cr.cr_order_number) AS catalog_order_cnt,
    COUNT(DISTINCT wr.wr_order_number) AS web_order_cnt,
    SUM(cr.cr_return_amount) AS total_catalog_return,
    SUM(wr.wr_return_amt) AS total_web_return,
    SUM(cr.cr_return_amount + wr.wr_return_amt) AS total_return_amount,
    SUM(cr.cr_net_loss + wr.wr_net_loss) AS total_net_loss,
    AVG(i_cat.i_current_price) AS avg_item_price,
    SUM(CASE WHEN cr.cr_return_quantity > 5 THEN cr.cr_return_amount ELSE 0 END) AS high_qty_catalog_return,
    SUM(CASE WHEN wr.wr_return_quantity > 5 THEN wr.wr_return_amt ELSE 0 END) AS high_qty_web_return
FROM date_dim d
LEFT JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
LEFT JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
LEFT JOIN item i_cat ON i_cat.i_item_sk = cr.cr_item_sk
LEFT JOIN item i_wr ON i_wr.i_item_sk = wr.wr_item_sk
LEFT JOIN store s ON s.s_closed_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 2000 AND 2005
GROUP BY
    d.d_year,
    d.d_month_seq,
    i_cat.i_category,
    s.s_state
HAVING SUM(cr.cr_return_amount) > 1000 OR SUM(wr.wr_return_amt) > 1000
ORDER BY total_return_amount DESC
LIMIT 100
