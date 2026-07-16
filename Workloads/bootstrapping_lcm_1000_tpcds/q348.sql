SELECT
    d_ret.d_year AS return_year,
    d_ret.d_moy AS return_month,
    s.s_state AS store_state,
    w.web_state AS website_state,
    CASE WHEN ca_ref.ca_county = s.s_county THEN 'SameCounty' ELSE 'DiffCounty' END AS county_match,
    COUNT(*) AS total_returns,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_net_loss) AS total_net_loss,
    AVG(cr.cr_fee) AS avg_fee,
    COUNT(DISTINCT cr.cr_order_number) AS distinct_orders,
    SUM(CASE WHEN cr.cr_return_quantity > 5 THEN cr.cr_return_amount ELSE 0 END) AS high_qty_return_amount,
    MIN(d_ret.d_date) AS first_return_date,
    MAX(d_ret.d_date) AS last_return_date
FROM catalog_returns cr
JOIN date_dim d_ret
    ON cr.cr_returned_date_sk = d_ret.d_date_sk
JOIN customer_address ca_ref
    ON cr.cr_refunded_addr_sk = ca_ref.ca_address_sk
JOIN customer_address ca_ret
    ON cr.cr_returning_addr_sk = ca_ret.ca_address_sk
JOIN store s
    ON s.s_closed_date_sk = d_ret.d_date_sk
JOIN web_site w
    ON w.web_open_date_sk = d_ret.d_date_sk
JOIN date_dim d_web_close
    ON w.web_close_date_sk = d_web_close.d_date_sk
WHERE cr.cr_return_amount > 0
  AND d_ret.d_year >= 2020
GROUP BY
    d_ret.d_year,
    d_ret.d_moy,
    s.s_state,
    w.web_state,
    CASE WHEN ca_ref.ca_county = s.s_county THEN 'SameCounty' ELSE 'DiffCounty' END
HAVING COUNT(*) > 10
ORDER BY total_return_amount DESC
LIMIT 100
