SELECT
    d.d_year,
    d.d_moy AS month,
    s.s_state,
    d.d_quarter_name,
    COUNT(DISTINCT cr.cr_item_sk) AS distinct_catalog_items,
    COUNT(DISTINCT wr.wr_item_sk) AS distinct_web_items,
    SUM(cr.cr_return_amount) AS total_catalog_return_amount,
    SUM(wr.wr_return_amt) AS total_web_return_amount,
    SUM(cr.cr_return_tax + wr.wr_return_tax) AS total_return_tax,
    SUM(cr.cr_net_loss + wr.wr_net_loss) AS total_net_loss,
    SUM(inv.inv_quantity_on_hand) AS total_inventory_quantity,
    AVG(cr.cr_return_quantity) AS avg_catalog_return_quantity,
    AVG(wr.wr_return_quantity) AS avg_web_return_quantity,
    SUM(CASE WHEN d.d_month_seq BETWEEN 1 AND 3 THEN cr.cr_return_amount + wr.wr_return_amt ELSE 0 END) AS q1_total_return_amount,
    SUM(CASE WHEN d.d_month_seq BETWEEN 4 AND 6 THEN cr.cr_return_amount + wr.wr_return_amt ELSE 0 END) AS q2_total_return_amount,
    SUM(CASE WHEN d.d_month_seq BETWEEN 7 AND 9 THEN cr.cr_return_amount + wr.wr_return_amt ELSE 0 END) AS q3_total_return_amount,
    SUM(CASE WHEN d.d_month_seq BETWEEN 10 AND 12 THEN cr.cr_return_amount + wr.wr_return_amt ELSE 0 END) AS q4_total_return_amount
FROM catalog_returns cr
JOIN date_dim d
    ON cr.cr_returned_date_sk = d.d_date_sk
JOIN web_returns wr
    ON wr.wr_returned_date_sk = d.d_date_sk
JOIN inventory inv
    ON inv.inv_date_sk = d.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 2000 AND 2005
GROUP BY
    d.d_year,
    d.d_moy,
    s.s_state,
    d.d_quarter_name
HAVING SUM(cr.cr_return_amount) > 0
ORDER BY
    d.d_year,
    d.d_moy,
    s.s_state
