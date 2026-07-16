SELECT
    d.d_year,
    d.d_month_seq,
    r.r_reason_desc,
    s.s_state,
    ca_returning.ca_city,
    CASE
        WHEN cr.cr_return_quantity > 10 THEN 'High'
        WHEN cr.cr_return_quantity BETWEEN 5 AND 10 THEN 'Medium'
        ELSE 'Low'
    END AS quantity_category,
    COUNT(*) AS total_returns,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_fee) AS total_fee,
    AVG(cr.cr_net_loss) AS avg_net_loss,
    SUM(cr.cr_return_tax) AS total_tax,
    COUNT(DISTINCT cr.cr_item_sk) AS distinct_items,
    MIN(cr.cr_returned_date_sk) AS min_return_date_sk,
    MAX(cr.cr_returned_date_sk) AS max_return_date_sk
FROM catalog_returns cr
JOIN date_dim d
    ON cr.cr_returned_date_sk = d.d_date_sk
JOIN customer_address ca_refunded
    ON cr.cr_refunded_addr_sk = ca_refunded.ca_address_sk
JOIN customer_address ca_returning
    ON cr.cr_returning_addr_sk = ca_returning.ca_address_sk
JOIN reason r
    ON cr.cr_reason_sk = r.r_reason_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 2015 AND 2020
  AND s.s_state = 'CA'
  AND ca_refunded.ca_country = 'United States'
GROUP BY
    d.d_year,
    d.d_month_seq,
    r.r_reason_desc,
    s.s_state,
    ca_returning.ca_city,
    CASE
        WHEN cr.cr_return_quantity > 10 THEN 'High'
        WHEN cr.cr_return_quantity BETWEEN 5 AND 10 THEN 'Medium'
        ELSE 'Low'
    END
HAVING COUNT(*) > 10
ORDER BY d.d_year DESC, total_returns DESC
LIMIT 100
