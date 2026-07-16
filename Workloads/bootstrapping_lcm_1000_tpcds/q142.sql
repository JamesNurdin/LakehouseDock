SELECT
    dd.d_year,
    i.i_category,
    i.i_brand,
    s.s_state,
    CASE
        WHEN s.s_state IN ('CA', 'OR', 'WA') THEN 'West Coast'
        WHEN s.s_state IN ('NY', 'NJ', 'CT') THEN 'Northeast'
        ELSE 'Other'
    END AS region,
    COUNT(*) AS num_returns,
    SUM(cr.cr_return_quantity) AS total_qty,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_net_loss) AS total_net_loss,
    AVG(cr.cr_return_amount) AS avg_return_amount,
    SUM(cr.cr_fee) AS total_fee,
    SUM(cr.cr_return_tax) AS total_tax,
    ROUND(SUM(cr.cr_return_amount) / NULLIF(SUM(cr.cr_return_quantity), 0), 2) AS avg_amount_per_item,
    COUNT(DISTINCT cr.cr_returning_customer_sk) AS distinct_customers
FROM catalog_returns cr
JOIN date_dim dd ON cr.cr_returned_date_sk = dd.d_date_sk
JOIN item i ON cr.cr_item_sk = i.i_item_sk
JOIN store s ON s.s_closed_date_sk = dd.d_date_sk
WHERE dd.d_year BETWEEN 2017 AND 2022
  AND cr.cr_return_amount > 0
GROUP BY
    dd.d_year,
    i.i_category,
    i.i_brand,
    s.s_state,
    CASE
        WHEN s.s_state IN ('CA', 'OR', 'WA') THEN 'West Coast'
        WHEN s.s_state IN ('NY', 'NJ', 'CT') THEN 'Northeast'
        ELSE 'Other'
    END
HAVING SUM(cr.cr_net_loss) > 0
ORDER BY total_net_loss DESC
LIMIT 200
