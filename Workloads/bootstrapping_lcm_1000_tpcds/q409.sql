SELECT
    d.d_year,
    i.i_category,
    s.s_state,
    floor(i.i_current_price / 10) * 10 AS price_band_start,
    SUM(cr.cr_net_loss) AS total_catalog_net_loss,
    SUM(wr.wr_net_loss) AS total_web_net_loss,
    SUM(cr.cr_net_loss + wr.wr_net_loss) AS total_net_loss,
    SUM(cr.cr_return_quantity) AS total_catalog_return_qty,
    SUM(wr.wr_return_quantity) AS total_web_return_qty,
    SUM(cr.cr_return_quantity + wr.wr_return_quantity) AS total_return_qty,
    SUM(cr.cr_return_amount) AS total_catalog_return_amt,
    SUM(wr.wr_return_amt) AS total_web_return_amt,
    SUM(cr.cr_return_amount + wr.wr_return_amt) AS total_return_amt,
    AVG(i.i_current_price) AS avg_item_price,
    AVG(s.s_tax_percentage) AS avg_store_tax,
    CASE WHEN SUM(cr.cr_net_loss + wr.wr_net_loss) > 50000 THEN 'High Loss' ELSE 'Low Loss' END AS loss_category
FROM catalog_returns cr
JOIN date_dim d
    ON cr.cr_returned_date_sk = d.d_date_sk
JOIN item i
    ON cr.cr_item_sk = i.i_item_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
JOIN web_returns wr
    ON wr.wr_returned_date_sk = d.d_date_sk
   AND wr.wr_item_sk = i.i_item_sk
WHERE d.d_year >= 2000
GROUP BY
    d.d_year,
    i.i_category,
    s.s_state,
    floor(i.i_current_price / 10) * 10
HAVING SUM(cr.cr_return_quantity + wr.wr_return_quantity) > 0
ORDER BY total_net_loss DESC
LIMIT 100
