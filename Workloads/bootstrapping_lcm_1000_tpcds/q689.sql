SELECT
    d.d_year,
    d.d_quarter_seq,
    i.i_category,
    s.s_state,
    w.web_state,
    CASE
        WHEN cr.cr_return_amount < 10 THEN 'Low'
        WHEN cr.cr_return_amount < 100 THEN 'Medium'
        ELSE 'High'
    END AS return_amount_bucket,
    COUNT(*) AS returns_cnt,
    SUM(cr.cr_net_loss) AS total_net_loss,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_fee) AS total_fee,
    AVG(i.i_current_price) AS avg_item_price,
    SUM(cr.cr_return_quantity) AS total_quantity,
    SUM(cr.cr_return_ship_cost) AS total_ship_cost
FROM catalog_returns cr
JOIN date_dim d
    ON cr.cr_returned_date_sk = d.d_date_sk
JOIN item i
    ON cr.cr_item_sk = i.i_item_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
JOIN web_site w
    ON w.web_open_date_sk = d.d_date_sk
   AND w.web_close_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 2010 AND 2020
GROUP BY
    d.d_year,
    d.d_quarter_seq,
    i.i_category,
    s.s_state,
    w.web_state,
    CASE
        WHEN cr.cr_return_amount < 10 THEN 'Low'
        WHEN cr.cr_return_amount < 100 THEN 'Medium'
        ELSE 'High'
    END
HAVING COUNT(*) > 5
ORDER BY total_net_loss DESC
LIMIT 100
