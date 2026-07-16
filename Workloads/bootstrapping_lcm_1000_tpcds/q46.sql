SELECT
    d.d_year,
    d.d_month_seq,
    i.i_category,
    i.i_brand,
    r.r_reason_desc,
    s.s_division_name,
    COUNT(*) AS total_returns,
    SUM(cr.cr_return_quantity) AS total_quantity,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_net_loss) AS total_net_loss,
    AVG(cr.cr_return_amount) AS avg_return_amount,
    SUM(CASE WHEN r.r_reason_desc = 'Damaged' THEN cr.cr_return_amount ELSE 0 END) AS damaged_return_amount,
    SUM(CASE WHEN i.i_current_price > 100 THEN cr.cr_return_amount ELSE 0 END) AS high_price_return_amount
FROM catalog_returns cr
JOIN date_dim d
    ON cr.cr_returned_date_sk = d.d_date_sk
JOIN item i
    ON cr.cr_item_sk = i.i_item_sk
JOIN reason r
    ON cr.cr_reason_sk = r.r_reason_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 2015 AND 2020
  AND i.i_category IS NOT NULL
GROUP BY
    d.d_year,
    d.d_month_seq,
    i.i_category,
    i.i_brand,
    r.r_reason_desc,
    s.s_division_name
HAVING COUNT(*) > 10
ORDER BY total_net_loss DESC
LIMIT 100
